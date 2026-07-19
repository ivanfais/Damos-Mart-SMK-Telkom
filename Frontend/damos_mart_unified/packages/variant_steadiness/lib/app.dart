import 'dart:async';

import 'package:disc_core/variant_navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

import 'data/models/notification_model.dart';
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
import 'core/notifications/notification_push_bridge.dart';
import 'core/notifications/order_notification_dispatcher.dart';
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

class _DamosMartAppState extends State<DamosMartApp> with WidgetsBindingObserver {
  bool _socketListenersRegistered = false;
  Timer? _notificationPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scheduleUnifiedSplashReset(AppRouter.router.go);
    AppRouter.router.routerDelegate.addListener(_syncSystemUi);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSystemUi());
    PushNotificationService.instance.registerTapHandler(_handleNotificationTap);
    _setupNotificationDispatcher();
  }

  void _setupNotificationDispatcher() {
    final dispatcher = OrderNotificationDispatcher.instance;
    dispatcher.registerTapHandler(({orderId, queueId, complaintId}) {
      if (complaintId != null) {
        _openComplaintDetail(complaintId);
        return;
      }
      if (orderId != null) {
        _openOrderHistoryDetail(orderId);
        return;
      }
      if (queueId != null) {
        _openQueueDetail(queueId);
      }
    });

    dispatcher.registerBannerHandler(({required title, required body, onTap}) {
      NotificationBanner.show(title: title, message: body, onTap: onTap);
    });

    NotificationPushBridge.instance.onNewNotification = (notification) {
      if (_shouldPushFromApi(notification)) {
        OrderNotificationDispatcher.instance.showFromModel(notification);
      }
    };
  }

  bool _shouldPushFromApi(NotificationModel notification) {
    return notification.type == NotificationType.orderStatus ||
        notification.type == NotificationType.queueReady ||
        notification.type == NotificationType.complaint;
  }

  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null) return;
      context.read<NotificationCubit>().refreshSilently();
    });
  }

  void _stopNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null) return;

      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        SocketService.instance.init(authState.user.id);
      }

      context.read<NotificationCubit>().refreshSilently();
      PushNotificationService.instance.ensurePermission();
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _stopNotificationPolling();
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
      OrderNotificationDispatcher.instance.showQueueEvent(
        title: 'Antrean Dipanggil',
        body:
            'Pesanan ${orderNumber ?? queueNumber} sedang disiapkan oleh petugas koperasi.',
        queueNumber: queueNumber,
        isReady: false,
        orderId: orderId,
        queueId: queueId,
        orderNumber: orderNumber,
      );
      _refreshQueuesAfterSocketEvent();
      _refreshNotificationsAfterSocketEvent();
    });

    SocketService.instance.onQueueUpdated((data) {
      _handleQueueUpdated(data);
      _refreshQueuesAfterSocketEvent();
      _refreshNotificationsAfterSocketEvent();
    });

    SocketService.instance.onQueueReady((data) {
      final queueNumber = data['queueNumber']?.toString() ?? '-';
      final orderId = data['orderId']?.toString();
      final queueId = data['queueId']?.toString();
      final orderNumber = data['orderNumber']?.toString();
      OrderNotificationDispatcher.instance.showQueueEvent(
        title: 'Pesanan Siap Diambil!',
        body:
            'Pesanan ${orderNumber ?? queueNumber} siap diambil. Tunjukkan QR Pengambilan di kasir.',
        queueNumber: queueNumber,
        isReady: true,
        orderId: orderId,
        queueId: queueId,
        orderNumber: orderNumber,
      );
      _refreshQueuesAfterSocketEvent();
      _refreshNotificationsAfterSocketEvent(reloadOrders: true);
    });

    SocketService.instance.onComplaintUpdated((data) {
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);
      final complaintId = payload['complaintId']?.toString();
      if (complaintId == null || complaintId.isEmpty) return;
      OrderNotificationDispatcher.instance.showComplaint(
        complaintId: complaintId,
        title: payload['title']?.toString() ?? 'Status Komplain Diperbarui',
        body: payload['body']?.toString() ??
            'Ada pembaruan pada komplain Anda. Ketuk untuk melihat detail.',
      );
      _refreshNotificationsAfterSocketEvent();
    });

    SocketService.instance.onOrderStatusUpdated((data) {
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);
      final orderId = payload['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) return;
      OrderNotificationDispatcher.instance.showOrderStatus(
        orderId: orderId,
        title: payload['title']?.toString() ?? 'Status Pesanan Diperbarui',
        body: payload['body']?.toString() ??
            'Status pesanan Anda telah diperbarui. Ketuk untuk melihat detail.',
      );
      _refreshAfterOrderStatusEvent(payload);
      _refreshNotificationsAfterSocketEvent();
    });

    SocketService.instance.onNotificationNew((data) {
      if (data is! Map) return;
      OrderNotificationDispatcher.instance.showFromSocket(Map<String, dynamic>.from(data));
      _refreshNotificationsAfterSocketEvent();
    });
  }

  void _handleQueueUpdated(dynamic data) {
    if (data is! Map) return;
    final payload = Map<String, dynamic>.from(data);
    final status = payload['status']?.toString();
    final event = payload['event']?.toString();

    if (status == 'COMPLETED') {
      _handleQueueCompleted(data);
      return;
    }

    if (event == 'PAYMENT_SUCCESS') {
      final orderId = payload['orderId']?.toString();
      final queueId = payload['queueId']?.toString();
      final queueNumber = payload['queueNumber']?.toString() ?? '-';
      final orderNumber = payload['orderNumber']?.toString();
      if (orderId == null) return;
      OrderNotificationDispatcher.instance.showPaymentSuccess(
        orderId: orderId,
        title: 'Pembayaran Berhasil',
        body:
            'Pesanan ${orderNumber ?? orderId} telah dibayar. Nomor antrean Anda adalah $queueNumber.',
        queueId: queueId,
        queueNumber: queueNumber,
        orderNumber: orderNumber,
      );
      _refreshNotificationsAfterSocketEvent(reloadOrders: true);
    }
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
        OrderNotificationDispatcher.instance.showOrderCompleted(
          orderId: orderId,
          orderNumber: orderNumber,
          title: 'Pesanan Selesai',
          body:
              'Pesanan ${orderNumber ?? 'Anda'} telah selesai diambil. Terima kasih telah berbelanja!',
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
            unawaited(PushNotificationService.instance.ensurePermission());
            SocketService.instance.init(state.user.id);
            _registerNotificationListeners();
            NotificationPushBridge.instance.reset();
            _startNotificationPolling();
            context.read<QueueCubit>().loadActiveQueues(userId: state.user.id);
            context.read<NotificationCubit>().loadNotifications();
            context.read<CartCubit>().loadCart();
          } else if (state is Unauthenticated) {
            SocketService.instance.disconnect();
            _socketListenersRegistered = false;
            _stopNotificationPolling();
            NotificationPushBridge.instance.reset();
            NotificationBanner.hide();
            context.read<QueueCubit>().reset();
            context.read<NotificationCubit>().reset();
            context.read<ComplaintCubit>().reset();
          }
        },
        child: BlocListener<NotificationCubit, NotificationState>(
          listenWhen: (previous, current) => current is NotificationLoaded,
          listener: (context, state) {
            if (state is NotificationLoaded) {
              NotificationPushBridge.instance.onNotificationsLoaded(state.notifications);
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
      ),
    );
  }
}
