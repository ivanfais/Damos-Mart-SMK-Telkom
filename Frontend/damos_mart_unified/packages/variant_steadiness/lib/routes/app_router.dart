import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:disc_core/unified_host_bridge.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/prefs_storage.dart';
import '../blocs/product/product_cubit.dart';
import 'damos_page_transitions.dart';

// Screens
import '../screens/disc/disc_picker_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/preorder/preorder_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../data/models/cart_item_model.dart';
import '../screens/checkout/payment_screen.dart';
import '../screens/checkout/qris_payment_screen.dart';
import '../screens/checkout/cash_payment_screen.dart';
import '../screens/checkout/order_status_screen.dart';
import '../screens/checkout/digital_receipt_screen.dart';
import '../data/models/order_model.dart';
import '../screens/queue/queue_list_screen.dart';
import '../screens/queue/queue_detail_screen.dart';
import '../screens/queue/preorder_tracking_screen.dart';
import '../screens/queue/qr_ticket_screen.dart';
import '../screens/queue/order_complete_screen.dart';
import '../screens/info/coop_info_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/disc_theme_settings_screen.dart';
import '../screens/profile/complaint_screen.dart';
import '../screens/profile/complaint_tracking_screen.dart';
import '../screens/profile/usage_guide_screen.dart';
import '../data/models/complaint_model.dart';
import '../screens/history/order_history_detail_screen.dart';
import '../screens/review/review_screen.dart';

// Shell Navigation
import '../widgets/common/damos_bottom_nav.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static Page<void> _page(GoRouterState state, Widget child) {
    return DamosPageTransitions.page(state: state, child: child);
  }

  static Page<void> _shellPage(GoRouterState state, Widget child) {
    return DamosPageTransitions.shellPage(state: state, child: child);
  }

  static int _routerSession = -1;
  static GoRouter? _router;

  static GoRouter get router {
    final session = UnifiedHostBridge.variantSessionId;
    if (_router != null && _routerSession == session) {
      return _router!;
    }
    _routerSession = session;
    return _router = _buildRouter();
  }

  static GoRouter _buildRouter() => GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) async {
      final path = state.uri.path;
      print('DEBUG ROUTER: redirect called for path=$path');
      try {
        final selectedDisc = PrefsStorage.instance.getSelectedDiscVariant();
        final isDiscPicker = path == '/disc-picker';
        final isSplash = path == '/';

        if (selectedDisc == null && !isDiscPicker) {
          return '/disc-picker';
        }

        if (selectedDisc != null && isDiscPicker) {
          return '/';
        }

        final token = await SecureStorage.instance.getAccessToken();
        final isLoggedIn = token != null && token.isNotEmpty;
        print('DEBUG ROUTER: isLoggedIn=$isLoggedIn');

        final isAuthPath = path == '/login' ||
            path == '/register' ||
            path == '/forgot-password';

        if (isSplash || isDiscPicker) {
          print('DEBUG ROUTER: splash/disc-picker path, returning null');
          return null;
        }

        if (!isLoggedIn && !isAuthPath) {
          print('DEBUG ROUTER: not logged in, redirecting to /login');
          return '/login';
        }

        if (isLoggedIn && isAuthPath) {
          print('DEBUG ROUTER: logged in, redirecting to /home');
          return '/home';
        }

        print('DEBUG ROUTER: allowing normal routing, returning null');
        return null;
      } catch (e) {
        print('DEBUG ROUTER: redirect error: $e');
        return '/login';
      }
    },
    routes: [
      GoRoute(
        path: '/disc-picker',
        pageBuilder: (context, state) => _page(state, const DiscPickerScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _page(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _page(
            state,
            LoginScreen(
              prefillEmail: extra?['email'] as String?,
              justRegistered: extra?['registered'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _page(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _page(
            state,
            ForgotPasswordScreen(
              prefillContact: extra?['contact'] as String?,
            ),
          );
        },
      ),

      // Shell Route for bottom navigation tabs
      ShellRoute(
        builder: (context, state, child) {
          return DamosBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _shellPage(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/catalog',
            pageBuilder: (context, state) => _shellPage(state, const CatalogScreen()),
          ),
          GoRoute(
            path: '/queue',
            pageBuilder: (context, state) => _shellPage(state, const QueueListScreen()),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => _shellPage(state, const CartScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _shellPage(state, const ProfileScreen()),
            routes: [
              GoRoute(
                path: 'usage-guide',
                pageBuilder: (context, state) => _shellPage(state, const UsageGuideScreen()),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => _shellPage(state, const NotificationsScreen()),
          ),
        ],
      ),

      // Other child screens
      GoRoute(
        path: '/catalog/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(
            state,
            BlocProvider(
              create: (_) => ProductCubit(),
              child: ProductDetailScreen(productId: id),
            ),
          );
        },
      ),
      GoRoute(
        path: '/preorder/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(
            state,
            BlocProvider(
              create: (_) => ProductCubit()..loadProductDetail(id),
              child: PreorderScreen(productId: id),
            ),
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final items = extra is List<CartItemModel> ? extra : <CartItemModel>[];
          return _page(state, PaymentScreen(items: items));
        },
        routes: [
          GoRoute(
            path: 'qris/:orderId',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) {
              final orderId = state.pathParameters['orderId'] ?? '';
              final order = state.extra as OrderModel?;
              return _page(state, QrisPaymentScreen(orderId: orderId, order: order));
            },
          ),
          GoRoute(
            path: 'cash/:orderId',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) {
              final orderId = state.pathParameters['orderId'] ?? '';
              final order = state.extra as OrderModel?;
              return _page(state, CashPaymentScreen(orderId: orderId, order: order));
            },
          ),
          GoRoute(
            path: 'status/:orderId',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) {
              final orderId = state.pathParameters['orderId'] ?? '';
              return _page(state, OrderStatusScreen(orderId: orderId));
            },
          ),
          GoRoute(
            path: 'ticket/:orderId',
            parentNavigatorKey: rootNavigatorKey,
            redirect: (context, state) {
              final orderId = state.pathParameters['orderId'] ?? '';
              return '/checkout/status/$orderId';
            },
          ),
        ],
      ),
      GoRoute(
        path: '/checkout/receipt/:orderId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return _page(state, DigitalReceiptScreen(orderId: orderId));
        },
      ),
      GoRoute(
        path: '/queue/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, QueueDetailScreen(queueId: id));
        },
      ),
      GoRoute(
        path: '/queue/:id/tracking',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, PreorderTrackingScreen(queueId: id));
        },
      ),
      GoRoute(
        path: '/queue/:id/qr',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, QRTicketScreen(queueId: id));
        },
      ),
      GoRoute(
        path: '/queue/:id/complete',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, OrderCompleteScreen(queueId: id));
        },
      ),
      GoRoute(
        path: '/info',
        pageBuilder: (context, state) => _page(state, const CoopInfoScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => _page(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: '/profile/change-password',
        pageBuilder: (context, state) => _page(state, const ChangePasswordScreen()),
      ),
      GoRoute(
        path: '/profile/disc-theme',
        pageBuilder: (context, state) => _page(state, const DiscThemeSettingsScreen()),
      ),
      GoRoute(
        path: '/profile/history',
        redirect: (context, state) => '/profile?view=history',
      ),
      GoRoute(
        path: '/orders/history/:orderId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return _page(state, OrderHistoryDetailScreen(orderId: orderId));
        },
      ),
      GoRoute(
        path: '/orders/history',
        redirect: (context, state) => '/profile?view=history',
      ),
      GoRoute(
        path: '/profile/chat',
        pageBuilder: (context, state) => _page(state, const ComplaintScreen()),
        routes: [
          GoRoute(
            path: 'complaints/:id/track',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final extra = state.extra;
              ComplaintModel? complaint;
              Uint8List? photoBytes;

              if (extra is Map) {
                complaint = extra['complaint'] as ComplaintModel?;
                photoBytes = extra['photoBytes'] as Uint8List?;
              }

              return _page(
                state,
                ComplaintTrackingScreen(
                  complaintId: id,
                  initialComplaint: complaint,
                  photoBytes: photoBytes,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/review/:orderId/:productId',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          final productId = state.pathParameters['productId'] ?? '';
          return _page(
            state,
            ReviewScreen(orderId: orderId, productId: productId),
          );
        },
      ),
    ],
  );
}
