import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/secure_storage.dart';
import '../blocs/product/product_cubit.dart';
import 'damos_page_transitions.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/preorder/preorder_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../data/models/cart_item_model.dart';
import '../screens/checkout/payment_screen.dart';
import '../screens/checkout/qris_payment_screen.dart';
import '../screens/checkout/pickup_ticket_screen.dart';
import '../data/models/order_model.dart';
import '../screens/queue/queue_list_screen.dart';
import '../screens/queue/queue_detail_screen.dart';
import '../screens/queue/preorder_tracking_screen.dart';
import '../screens/queue/qr_ticket_screen.dart';
import '../screens/queue/order_complete_screen.dart';
import '../screens/info/coop_info_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/history/purchase_history_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/review/review_screen.dart';

// Shell Navigation
import '../widgets/common/damos_bottom_nav.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static Page<void> _page(GoRouterState state, Widget child) {
    return DamosPageTransitions.page(state: state, child: child);
  }

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) async {
      final path = state.uri.toString();
      print('DEBUG ROUTER: redirect called for path=$path');
      try {
        final token = await SecureStorage.instance.getAccessToken();
        final isLoggedIn = token != null && token.isNotEmpty;
        print('DEBUG ROUTER: isLoggedIn=$isLoggedIn');

        final isAuthPath = path == '/login' || path == '/register';
        final isSplash = path == '/';

        if (isSplash) {
          print('DEBUG ROUTER: splash path, returning null');
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

      // Shell Route for bottom navigation tabs
      ShellRoute(
        builder: (context, state, child) {
          return DamosBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _page(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/catalog',
            pageBuilder: (context, state) => _page(state, const CatalogScreen()),
          ),
          GoRoute(
            path: '/queue',
            pageBuilder: (context, state) => _page(state, const QueueListScreen()),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => _page(state, const CartScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _page(state, const ProfileScreen()),
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
          return _page(state, PreorderScreen(productId: id));
        },
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) {
          final items = state.extra as List<CartItemModel>? ?? [];
          return _page(state, PaymentScreen(items: items));
        },
      ),
      GoRoute(
        path: '/checkout/qris/:orderId',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          final order = state.extra as OrderModel?;
          return _page(state, QrisPaymentScreen(orderId: orderId, order: order));
        },
      ),
      GoRoute(
        path: '/checkout/ticket/:orderId',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return _page(state, PickupTicketScreen(orderId: orderId));
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
        path: '/profile/history',
        pageBuilder: (context, state) => _page(state, const PurchaseHistoryScreen()),
      ),
      GoRoute(
        path: '/profile/chat',
        pageBuilder: (context, state) => _page(state, const ChatScreen()),
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
