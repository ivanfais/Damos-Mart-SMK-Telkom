import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/product/product_cubit.dart';
import 'blocs/cart/cart_cubit.dart';
import 'blocs/order/order_cubit.dart';
import 'blocs/queue/queue_cubit.dart';
import 'blocs/complaint/complaint_cubit.dart';
import 'blocs/notification/notification_cubit.dart';
import 'blocs/cooperative/cooperative_cubit.dart';
import 'core/notifications/notification_payload.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/disc/disc_build_guard.dart';
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

  @override
  void initState() {
    super.initState();
    AppRouter.router.routerDelegate.addListener(_syncSystemUi);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSystemUi());
    PushNotificationService.instance.registerTapHandler(_handleNotificationTap);
  }

  void _handleNotificationTap(String? payload) {
    final complaintId = NotificationPayload.parseComplaintId(payload);
    if (complaintId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openComplaintDetail(complaintId);
      });
      return;
    }

    final orderId = NotificationPayload.parseOrderId(payload);
    if (orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openOrderHistoryDetail(orderId);
      });
      return;
    }

    final queueId = NotificationPayload.parseQueueId(payload);
    if (queueId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openQueueDetail(queueId);
      });
    }
  }

  void _openComplaintDetail(String complaintId) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final location = GoRouterState.of(context).uri.toString();
    if (location.contains('/complaints/$complaintId')) return;

    context.push('/profile/chat/complaints/$complaintId/track');
  }

  void _openOrderHistoryDetail(String orderId) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final location = GoRouterState.of(context).uri.toString();
    if (location.contains('/orders/history/$orderId')) return;

    context.push('/orders/history/$orderId');
  }

  void _openQueueDetail(String queueId) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final location = GoRouterState.of(context).uri.toString();
    if (location.contains('/queue/$queueId')) return;

    context.push('/queue/$queueId');
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
      final queueNumber = data['queueNumber']?.toString() ?? '-';
      final orderId = data['orderId']?.toString();
      final queueId = data['queueId']?.toString();
      final orderNumber = data['orderNumber']?.toString();
      _showQueueNotification(
        title: 'Antrean Dipanggil',
        message:
            'Pesanan ${orderNumber ?? queueNumber} sedang disiapkan oleh petugas koperasi.',
        queueNumber: queueNumber,
        orderNumber: orderNumber,
        isReady: false,
        orderId: orderId,
        queueId: queueId,
      );
      _refreshQueuesAfterSocketEvent();
      _refreshNotificationsAfterSocketEvent();
    });

    SocketService.instance.onQueueUpdated((data) {
      _handleQueueCompleted(data);
      _refreshQueuesAfterSocketEvent();
      _refreshNotificationsAfterSocketEvent();
    });

    SocketService.instance.onQueueReady((data) {
      final queueNumber = data['queueNumber']?.toString() ?? '-';
      final orderId = data['orderId']?.toString();
      final queueId = data['queueId']?.toString();
      final orderNumber = data['orderNumber']?.toString();
      _showQueueNotification(
        title: 'Pesanan Siap Diambil!',
        message:
            'Pesanan ${orderNumber ?? queueNumber} siap diambil. Tunjukkan QR Pengambilan di kasir.',
        queueNumber: queueNumber,
        orderNumber: orderNumber,
        isReady: true,
        orderId: orderId,
        queueId: queueId,
      );
      _refreshQueuesAfterSocketEvent();
      _refreshNotificationsAfterSocketEvent(reloadOrders: true);
    });

    SocketService.instance.onComplaintUpdated((data) {
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);
      _showComplaintNotification(payload);
      _refreshNotificationsAfterSocketEvent();
    });

    SocketService.instance.onOrderStatusUpdated((data) {
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);
      _showOrderStatusNotification(payload);
      _refreshAfterOrderStatusEvent(payload);
      _refreshNotificationsAfterSocketEvent();
    });
  }

  void _refreshAfterOrderStatusEvent(Map<String, dynamic> data) {
    final orderId = data['orderId']?.toString();
    if (orderId == null || orderId.isEmpty) return;

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final orderCubit = context.read<OrderCubit>();
    orderCubit.refreshMyOrdersSilently();
    orderCubit.refreshOrderDetailSilently(orderId);
  }

  void _refreshNotificationsAfterSocketEvent({bool reloadOrders = false}) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    if (reloadOrders) {
      context.read<OrderCubit>().refreshMyOrdersSilently();
    }

    final location = GoRouterState.of(context).uri.toString();
    final cubit = context.read<NotificationCubit>();
    if (location.startsWith('/notifications')) {
      cubit.loadNotifications();
    } else {
      cubit.refreshSilently();
    }
  }

  void _refreshQueuesAfterSocketEvent() {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    final userId = authState.user.id;

    final location = GoRouterState.of(context).uri.toString();
    if (location == '/queue') {
      context.read<QueueCubit>().refreshQueueList(userId: userId);
    } else {
      context.read<QueueCubit>().updateActiveQueuesSilently(userId: userId);
    }
  }

  void _handleQueueCompleted(dynamic data) {
    final orderId = data?['orderId']?.toString();
    final queueId = data?['queueId']?.toString();
    final status = data?['status']?.toString();
    if (status != 'COMPLETED') return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null) return;

      context.read<OrderCubit>().refreshMyOrdersSilently();

      final authState = context.read<AuthBloc>().state;
      final userId = authState is Authenticated ? authState.user.id : null;
      context.read<QueueCubit>().refreshQueueList(userId: userId);

      if (orderId != null) {
        final orderNumber = data?['orderNumber']?.toString();
        _showOrderCompletedNotification(
          orderId: orderId,
          orderNumber: orderNumber,
        );
      }

      if (orderId != null) {
        final location = GoRouterState.of(context).uri.toString();
        if (!location.contains('/orders/history/$orderId')) {
          _openOrderHistoryDetail(orderId);
        }
        return;
      }

      if (queueId == null) return;
      final location = GoRouterState.of(context).uri.toString();
      if (location.contains('/queue/$queueId/complete')) return;
      context.push('/queue/$queueId/complete');
    });
  }

  void _showOrderCompletedNotification({
    required String orderId,
    String? orderNumber,
  }) {
    final title = 'Pesanan Selesai';
    final message =
        'Pesanan ${orderNumber ?? 'Anda'} telah selesai diambil. Terima kasih telah berbelanja!';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NotificationBanner.show(
        title: title,
        message: message,
        onTap: () {
          NotificationBanner.hide();
          _openOrderHistoryDetail(orderId);
        },
      );

      final push = PushNotificationService.instance;
      if (!push.isSupported) return;

      await push.ensurePermission();
      await push.showOrderCompleted(orderId: orderId, orderNumber: orderNumber);
    });
  }

  void _showComplaintNotification(Map<String, dynamic> data) {
    final complaintId = data['complaintId']?.toString();
    if (complaintId == null || complaintId.isEmpty) return;

    final title = data['title']?.toString() ?? 'Status Komplain Diperbarui';
    final body = data['body']?.toString() ??
        'Ada pembaruan pada komplain Anda. Ketuk untuk melihat detail.';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NotificationBanner.show(
        title: title,
        message: body,
        onTap: () {
          NotificationBanner.hide();
          _openComplaintDetail(complaintId);
        },
      );

      final push = PushNotificationService.instance;
      if (!push.isSupported) return;

      await push.ensurePermission();
      await push.showComplaintUpdate(
        complaintId: complaintId,
        title: title,
        body: body,
      );
    });
  }

  void _showOrderStatusNotification(Map<String, dynamic> data) {
    final orderId = data['orderId']?.toString();
    if (orderId == null || orderId.isEmpty) return;

    final title = data['title']?.toString() ?? 'Status Pesanan Diperbarui';
    final body = data['body']?.toString() ??
        'Status pesanan Anda telah diperbarui. Ketuk untuk melihat detail.';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NotificationBanner.show(
        title: title,
        message: body,
        onTap: () {
          NotificationBanner.hide();
          _openOrderHistoryDetail(orderId);
        },
      );

      final push = PushNotificationService.instance;
      if (!push.isSupported) return;

      await push.ensurePermission();
      await push.showOrderStatusUpdate(
        orderId: orderId,
        title: title,
        body: body,
      );
    });
  }

  void _showQueueNotification({
    required String title,
    required String message,
    required String queueNumber,
    required bool isReady,
    String? orderId,
    String? queueId,
    String? orderNumber,
  }) {
    VoidCallback? onTap;
    if (orderId != null) {
      onTap = () {
        NotificationBanner.hide();
        _openOrderHistoryDetail(orderId);
      };
    } else if (queueId != null) {
      onTap = () {
        NotificationBanner.hide();
        _openQueueDetail(queueId);
      };
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NotificationBanner.show(
        title: title,
        message: message,
        onTap: onTap,
      );

      final push = PushNotificationService.instance;
      if (!push.isSupported) return;

      await push.ensurePermission();
      if (isReady) {
        await push.showQueueReady(
          queueNumber: queueNumber,
          orderId: orderId,
          queueId: queueId,
          orderNumber: orderNumber,
        );
      } else {
        await push.showQueueCalled(
          queueNumber: queueNumber,
          orderId: orderId,
          queueId: queueId,
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
        BlocProvider<OrderCubit>(
          create: (context) => OrderCubit(),
        ),
        BlocProvider<QueueCubit>(
          create: (context) => QueueCubit(),
        ),
        BlocProvider<ComplaintCubit>(
          create: (context) => ComplaintCubit(),
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
            context.read<QueueCubit>().loadActiveQueues(userId: state.user.id);
            context.read<NotificationCubit>().loadNotifications();
            context.read<CartCubit>().loadCart();
          } else if (state is Unauthenticated) {
            SocketService.instance.disconnect();
            _socketListenersRegistered = false;
            NotificationBanner.hide();
            context.read<QueueCubit>().reset();
            context.read<NotificationCubit>().reset();
            context.read<ComplaintCubit>().reset();
          }
        },
        child: MaterialApp.router(
          title: 'Damos Mart',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            final content = DefaultTextStyle(
              style: GoogleFonts.inter(),
              child: DiscBuildGuard(
                child: child ?? const SizedBox.shrink(),
              ),
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
