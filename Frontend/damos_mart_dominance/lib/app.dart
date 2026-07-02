import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/damos_dominance_colors.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/product/product_cubit.dart';
import 'blocs/cart/cart_cubit.dart';
import 'blocs/favorite/favorite_cubit.dart';
import 'blocs/order/order_cubit.dart';
import 'blocs/queue/queue_cubit.dart';
import 'blocs/chat/chat_cubit.dart';
import 'blocs/notification/notification_cubit.dart';
import 'blocs/cooperative/cooperative_cubit.dart';
import 'core/auth/session_expired_notifier.dart';
import 'core/auth/auth_refresh_notifier.dart';
import 'core/disc/disc_build_guard.dart';
import 'core/notifications/notification_payload.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/socket/socket_service.dart';
import 'core/utils/damos_system_ui.dart';
import 'widgets/common/notification_banner.dart';

class DamosMartApp extends StatefulWidget {
  const DamosMartApp({super.key});

  @override
  State<DamosMartApp> createState() => _DamosMartAppState();
}

class _DamosMartAppState extends State<DamosMartApp> {
  bool _socketListenersRegistered = false;
  StreamSubscription<void>? _sessionExpiredSub;

  @override
  void initState() {
    super.initState();
    AppRouter.router.routerDelegate.addListener(_syncSystemUi);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSystemUi());
    _sessionExpiredSub = SessionExpiredNotifier.instance.stream.listen((_) {
      _handleSessionExpired();
    });
    PushNotificationService.instance.registerTapHandler(_handleNotificationTap);
  }

  void _handleNotificationTap(String? payload) {
    final orderId = NotificationPayload.parseOrderId(payload);
    if (orderId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openOrderDetail(orderId);
    });
  }

  void _openOrderDetail(String orderId) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    context.read<OrderCubit>().loadOrderDetail(orderId);

    final location = GoRouterState.of(context).uri.toString();
    if (location.contains('/orders/$orderId')) return;

    context.push('/orders/$orderId');
  }

  void _handleSessionExpired() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null) return;

      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      context.read<AuthBloc>().add(LoggedOut());
    });
  }

  void _redirectToLoginAfterLogout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
      const allowedPaths = {
        '/login',
        '/forgot-password',
        '/reset-password',
        '/',
        '/disc-picker',
      };
      if (allowedPaths.contains(path)) return;

      AppRouter.router.go('/login');
    });
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    AppRouter.router.routerDelegate.removeListener(_syncSystemUi);
    super.dispose();
  }

  void _syncSystemUi() {
    final location = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
    DamosSystemUi.apply(DamosSystemUi.forRoute(location));
  }

  void _registerNotificationListeners() {
    if (_socketListenersRegistered) return;
    _socketListenersRegistered = true;

    SocketService.instance.onQueueCalled((data) {
      final queueNumber = data['queueNumber']?.toString() ?? '-';
      final orderId = data['orderId']?.toString();
      final orderNumber = data['orderNumber']?.toString();
      _showQueueNotification(
        title: 'Antrean Dipanggil',
        message: 'Pesanan ${orderNumber ?? queueNumber} sedang disiapkan oleh petugas koperasi.',
        queueNumber: queueNumber,
        orderNumber: orderNumber,
        isReady: false,
        orderId: orderId,
      );
      _refreshAfterQueueEvent();
    });

    SocketService.instance.onQueueUpdated((data) {
      _handleQueueCompleted(data);
      _refreshAfterQueueEvent();
    });

    SocketService.instance.onQueueReady((data) {
      final queueNumber = data['queueNumber']?.toString() ?? '-';
      final orderId = data['orderId']?.toString();
      final orderNumber = data['orderNumber']?.toString();
      _showQueueNotification(
        title: 'Pesanan Siap Diambil!',
        message:
            'Pesanan ${orderNumber ?? queueNumber} siap diambil. Tunjukkan QR Pengambilan di kasir.',
        queueNumber: queueNumber,
        orderNumber: orderNumber,
        isReady: true,
        orderId: orderId,
      );
      _refreshAfterQueueEvent(reloadOrders: true);
    });
  }

  void _refreshAfterQueueEvent({bool reloadOrders = false}) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    context.read<QueueCubit>().updateActiveQueuesSilently();
    if (reloadOrders) {
      context.read<OrderCubit>().loadMyOrders();
    }
  }

  void _handleQueueCompleted(dynamic data) {
    final orderId = data?['orderId']?.toString();
    final status = data?['status']?.toString();
    if (orderId == null || status != 'COMPLETED') return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null) return;

      context.read<OrderCubit>().loadMyOrders();

      final location = GoRouterState.of(context).uri.toString();
      if (location.contains('/orders/$orderId')) return;

      _openOrderDetail(orderId);
    });
  }

  void _showQueueNotification({
    required String title,
    required String message,
    required String queueNumber,
    required bool isReady,
    String? orderId,
    String? orderNumber,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (orderId != null) {
        NotificationBanner.show(
          title: title,
          message: message,
          onTap: () {
            NotificationBanner.hide();
            _openOrderDetail(orderId);
          },
        );
      } else {
        NotificationBanner.show(
          title: title,
          message: message,
        );
      }

      final push = PushNotificationService.instance;
      if (!push.isSupported) return;

      await push.ensurePermission();
      if (isReady) {
        await push.showQueueReady(
          queueNumber: queueNumber,
          orderId: orderId,
          orderNumber: orderNumber,
        );
      } else {
        await push.showQueueCalled(
          queueNumber: queueNumber,
          orderId: orderId,
          orderNumber: orderNumber,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AppStarted()),
        ),
        BlocProvider<ProductCubit>(
          create: (context) => ProductCubit(),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(),
        ),
        BlocProvider<FavoriteCubit>(
          create: (context) => FavoriteCubit(),
        ),
        BlocProvider<OrderCubit>(
          create: (context) => OrderCubit(),
        ),
        BlocProvider<QueueCubit>(
          create: (context) => QueueCubit(),
        ),
        BlocProvider<ChatCubit>(
          create: (context) => ChatCubit(),
        ),
        BlocProvider<NotificationCubit>(
          create: (context) => NotificationCubit(),
        ),
        BlocProvider<CooperativeCubit>(
          create: (context) => CooperativeCubit(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            PushNotificationService.instance.ensurePermission();
            SocketService.instance.init(state.user.id);
            _registerNotificationListeners();
            context.read<QueueCubit>().loadActiveQueues();
            context.read<FavoriteCubit>().loadFavoriteIds();
            AuthRefreshNotifier.instance.refresh();
          } else if (state is Unauthenticated) {
            SocketService.instance.disconnect();
            _socketListenersRegistered = false;
            NotificationBanner.hide();
            context.read<CartCubit>().resetSession();
            context.read<FavoriteCubit>().resetSession();
            AuthRefreshNotifier.instance.refresh();
            _redirectToLoginAfterLogout();
          }
        },
        child: MaterialApp.router(
          title: 'Damos Mart',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            final content = DiscBuildGuard(
              child: child ?? const SizedBox.shrink(),
            );
            if (kIsWeb) {
              final path =
                  AppRouter.router.routerDelegate.currentConfiguration.uri.path;
              final greenShell = path == '/';

              return ColoredBox(
                color: greenShell
                    ? DamosDominanceColors.primary
                    : const Color(0xFFF3F4F6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: content,
                  ),
                ),
              );
            }
            return content;
          },
        ),
      ),
    );
  }
}
