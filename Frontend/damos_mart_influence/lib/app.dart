import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'core/socket/socket_service.dart';
import 'widgets/common/notification_banner.dart';

class DamosMartApp extends StatefulWidget {
  const DamosMartApp({super.key});

  @override
  State<DamosMartApp> createState() => _DamosMartAppState();
}

class _DamosMartAppState extends State<DamosMartApp> {
  bool _socketListenersRegistered = false;

  void _registerNotificationListeners() {
    if (_socketListenersRegistered) return;
    _socketListenersRegistered = true;

    SocketService.instance.onQueueCalled((data) {
      _showQueueBanner(
        title: 'Antrean Dipanggil',
        message:
            'Pesanan ${data['queueNumber']} Anda sedang disiapkan oleh petugas koperasi.',
      );
    });

    SocketService.instance.onQueueReady((data) {
      _showQueueBanner(
        title: 'Pesanan Siap Diambil!',
        message:
            'Pesanan ${data['queueNumber']} Anda sudah siap diambil di kasir. Silakan ambil sekarang.',
      );
    });
  }

  void _showQueueBanner({required String title, required String message}) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    NotificationBanner.show(
      context: context,
      title: title,
      message: message,
    );
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
            SocketService.instance.init(state.user.id);
            _registerNotificationListeners();
          } else if (state is Unauthenticated) {
            SocketService.instance.disconnect();
            _socketListenersRegistered = false;
            NotificationBanner.hide();
          }
        },
        child: MaterialApp.router(
          title: 'Damos Mart',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            if (kIsWeb) {
              // Keep a straight, centered mobile-width viewport on web (no tilted frame).
              return ColoredBox(
                color: const Color(0xFFF3F4F6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
