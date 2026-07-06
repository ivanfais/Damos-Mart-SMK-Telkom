import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/prefs_storage.dart';
import '../core/auth/auth_refresh_notifier.dart';
import '../blocs/product/product_cubit.dart';
import 'damos_page_transitions.dart';

// Screens
import '../screens/disc/disc_picker_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/forgot_password_verify_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/preorder/preorder_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../data/models/cart_item_model.dart';
import '../screens/checkout/payment_screen.dart';
import '../screens/checkout/qris_payment_screen.dart';
import '../screens/checkout/cash_payment_screen.dart';
import '../data/models/order_model.dart';
import '../screens/queue/queue_route_redirect_screen.dart';
import '../screens/info/coop_info_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/favorites_screen.dart';
import '../screens/profile/disc_theme_settings_screen.dart';
import '../screens/complaints/complaint_form_screen.dart';
import '../screens/complaints/complaint_submitted_screen.dart';
import '../screens/complaints/complaint_product_selection_screen.dart';
import '../screens/complaints/complaint_detail_screen.dart';
import '../data/models/complaint_category_option.dart';
import '../screens/history/purchase_history_screen.dart';
import '../screens/order/order_detail_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/review/review_screen.dart';
import '../screens/notifications/notifications_screen.dart';

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
    refreshListenable: AuthRefreshNotifier.instance,
    redirect: (BuildContext context, GoRouterState state) async {
      final path = state.uri.path;
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

        final isAuthPath = path == '/login' ||
            path == '/register' ||
            path == '/forgot-password' ||
            path == '/forgot-password/verify' ||
            path == '/reset-password';

        if (isSplash || isDiscPicker) {
          return null;
        }

        if (!isLoggedIn && !isAuthPath) {
          return '/login';
        }

        if (isLoggedIn && isAuthPath) {
          return '/home';
        }

        return null;
      } catch (e) {
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
              registered: extra?['registered'] as bool? ?? false,
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
        pageBuilder: (context, state) => _page(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/forgot-password/verify',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          return _page(state, ForgotPasswordVerifyScreen(email: email));
        },
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return _page(state, ResetPasswordScreen(token: token));
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
            pageBuilder: (context, state) => _page(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/catalog',
            pageBuilder: (context, state) => _page(state, const CatalogScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => _page(state, const PurchaseHistoryScreen()),
          ),
          GoRoute(
            path: '/queue',
            redirect: (context, state) => '/history',
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => _page(state, const CartScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _page(state, const ProfileScreen()),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootNavigatorKey,
                pageBuilder: (context, state) => _page(state, const EditProfileScreen()),
              ),
              GoRoute(
                path: 'change-password',
                parentNavigatorKey: rootNavigatorKey,
                pageBuilder: (context, state) => _page(state, const ChangePasswordScreen()),
              ),
              GoRoute(
                path: 'disc-theme',
                parentNavigatorKey: rootNavigatorKey,
                pageBuilder: (context, state) => _page(state, const DiscThemeSettingsScreen()),
              ),
              GoRoute(
                path: 'history',
                redirect: (context, state) {
                  final tab = state.uri.queryParameters['tab'];
                  if (tab != null && tab.isNotEmpty) {
                    return '/history?tab=$tab';
                  }
                  return '/history';
                },
              ),
              GoRoute(
                path: 'chat',
                parentNavigatorKey: rootNavigatorKey,
                pageBuilder: (context, state) => _page(state, const ChatScreen()),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/favorites',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _page(state, const FavoritesScreen()),
      ),

      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _page(state, const NotificationsScreen()),
      ),

      GoRoute(
        path: '/orders/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, OrderDetailScreen(orderId: id));
        },
        routes: [
          GoRoute(
            path: 'complaints/select',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) {
              final orderId = state.pathParameters['id'] ?? '';
              return _page(
                state,
                ComplaintProductSelectionScreen(orderId: orderId),
              );
            },
          ),
          GoRoute(
            path: 'complaints/form',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) {
              final orderId = state.pathParameters['id'] ?? '';
              final extra = state.extra as Map<String, dynamic>? ?? {};
              OrderItemModel? selectedProduct;
              if (extra['selectedProduct'] is Map) {
                selectedProduct = OrderItemModel.fromJson(
                  Map<String, dynamic>.from(extra['selectedProduct'] as Map),
                );
              }
              final serviceIssue = ComplaintServiceIssueOption.byId(
                extra['serviceIssueId'] as String?,
              );
              return _page(
                state,
                ComplaintFormScreen(
                  orderId: orderId,
                  orderNumber: extra['orderNumber'] as String? ?? '',
                  selectedProduct: selectedProduct,
                  serviceIssue: serviceIssue,
                ),
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: '/complaints/success',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final ticket = extra['ticketNumber'] as String? ??
              state.uri.queryParameters['ticket'] ??
              'CMP-0000-000';
          final complaintId = extra['complaintId'] as String? ?? '';
          final orderId = extra['orderId'] as String? ?? '';
          return _page(
            state,
            ComplaintSubmittedScreen(
              ticketNumber: ticket,
              complaintId: complaintId,
              orderId: orderId,
            ),
          );
        },
      ),

      GoRoute(
        path: '/complaints/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, ComplaintDetailScreen(complaintId: id));
        },
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
        path: '/checkout/cash/:orderId',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          final order = state.extra as OrderModel?;
          return _page(state, CashPaymentScreen(orderId: orderId, order: order));
        },
      ),
      GoRoute(
        path: '/checkout/ticket/:orderId',
        redirect: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return '/orders/$orderId';
        },
      ),
      GoRoute(
        path: '/queue/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, QueueRouteRedirectScreen(queueId: id));
        },
      ),
      GoRoute(
        path: '/queue/:id/tracking',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, QueueRouteRedirectScreen(queueId: id));
        },
      ),
      GoRoute(
        path: '/queue/:id/qr',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, QueueRouteRedirectScreen(queueId: id));
        },
      ),
      GoRoute(
        path: '/queue/:id/complete',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _page(state, QueueRouteRedirectScreen(queueId: id));
        },
      ),
      GoRoute(
        path: '/info',
        pageBuilder: (context, state) => _page(state, const CoopInfoScreen()),
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
