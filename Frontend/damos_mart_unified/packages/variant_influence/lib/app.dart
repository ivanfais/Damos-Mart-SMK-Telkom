import 'package:disc_core/variant_navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/product/product_cubit.dart';
import 'blocs/cart/cart_cubit.dart';
import 'blocs/order/order_cubit.dart';
import 'blocs/queue/queue_cubit.dart';
import 'blocs/chat/chat_cubit.dart';
import 'blocs/notification/notification_cubit.dart';
import 'blocs/cooperative/cooperative_cubit.dart';
import 'core/disc/disc_build_guard.dart';
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
  String? _currentUserId;

  bool _isEventForCurrentUser(dynamic data) {
    if (_currentUserId == null) return false;
    if (data is! Map) return true;
    final payload = Map<String, dynamic>.from(data);
    final eventUserId = payload['userId']?.toString();
    if (eventUserId == null || eventUserId.isEmpty) return true;
    return eventUserId == _currentUserId;
  }

  @override
  void initState() {
    super.initState();
    scheduleUnifiedSplashReset(AppRouter.router.go);
    AppRouter.router.routerDelegate.addListener(_syncSystemUi);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSystemUi());
  }

  @override
  void dispose() {
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
      if (!_isEventForCurrentUser(data)) return;
      final queueNumber = data['queueNumber']?.toString() ?? '-';
      _showQueueNotification(
        title: 'Antrean Dipanggil',
        message:
            'Pesanan $queueNumber Anda sedang disiapkan oleh petugas koperasi.',
        queueNumber: queueNumber,
        isReady: false,
      );
      _refreshRealtimeData(queueId: data?['queueId']?.toString());
    });

    SocketService.instance.onQueueUpdated((data) {
      if (!_isEventForCurrentUser(data)) return;
      _handleQueueCompleted(data);
      _refreshRealtimeData(queueId: data?['queueId']?.toString());
    });

    SocketService.instance.onQueueReady((data) {
      if (!_isEventForCurrentUser(data)) return;
      final queueNumber = data['queueNumber']?.toString() ?? '-';
      _showQueueNotification(
        title: 'Pesanan Siap Diambil!',
        message:
            'Pesanan $queueNumber Anda sudah siap diambil di kasir. Silakan ambil sekarang.',
        queueNumber: queueNumber,
        isReady: true,
      );
      _refreshRealtimeData(queueId: data?['queueId']?.toString());
    });

    SocketService.instance.onOrderStatusUpdated((data) {
      if (!_isEventForCurrentUser(data)) return;
      _refreshRealtimeData(queueId: data?['queueId']?.toString());
    });
  }

  void _refreshRealtimeData({String? queueId}) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    context.read<QueueCubit>().updateActiveQueuesSilently();
    if (queueId != null && queueId.isNotEmpty) {
      context.read<QueueCubit>().updateQueueDetailSilently(queueId);
    }
    context.read<OrderCubit>().refreshMyOrdersSilently();
  }

  void _handleQueueCompleted(dynamic data) {
    final queueId = data?['queueId']?.toString();
    final status = data?['status']?.toString();
    if (queueId == null || status != 'COMPLETED') return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null) return;

      context.read<OrderCubit>().loadMyOrders();
      final location = GoRouterState.of(context).uri.toString();
      if (location.contains('/queue/$queueId/complete')) return;

      context.push('/queue/$queueId/complete');
    });
  }

  void _showQueueNotification({
    required String title,
    required String message,
    required String queueNumber,
    required bool isReady,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final push = PushNotificationService.instance;
      if (push.isSupported) {
        await push.ensurePermission();
        if (isReady) {
          await push.showQueueReady(queueNumber: queueNumber);
        } else {
          await push.showQueueCalled(queueNumber: queueNumber);
        }
        return;
      }

      // Web fallback: in-app banner
      NotificationBanner.show(
        title: title,
        message: message,
      );
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
            _currentUserId = state.user.id;
            PushNotificationService.instance.ensurePermission();
            SocketService.instance.init(state.user.id);
            _registerNotificationListeners();
          } else if (state is Unauthenticated) {
            _currentUserId = null;
            SocketService.instance.disconnect();
            _socketListenersRegistered = false;
            NotificationBanner.hide();
          }
        },
        child: MaterialApp.router(
          title: 'Damos Mart Influence',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            final content = DiscBuildGuard(
              child: child ?? const SizedBox.shrink(),
            );
            if (kIsWeb) {
              // Keep a straight, centered mobile-width viewport on web (no tilted frame).
              return ColoredBox(
                color: const Color(0xFFF3F4F6),
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
