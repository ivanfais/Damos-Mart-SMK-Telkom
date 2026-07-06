import 'env.dart';

class ApiConfig {
  static String get baseUrl => Env.baseUrl;
  static String get wsUrl => Env.webSocketUrl;

  // Image Upload base URL
  static String imageUrl(String path) {
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '${Env.webSocketUrl}$cleanPath';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String loginSso = '/auth/login/sso';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String userMe = '/users/me';
  static const String changePassword = '/users/me/password';

  // Categories
  static const String categories = '/categories';
  static String categoryDetail(String id) => '/categories/$id';

  // Products
  static const String products = '/products';
  static const String featuredProducts = '/products/featured';
  static String productDetail(String id) => '/products/$id';
  static String productReviews(String id) => '/products/$id/reviews';

  // Cart
  static const String cart = '/cart';
  static String cartItem(String id) => '/cart/$id';

  // Orders
  static const String orders = '/orders';
  static String orderDetail(String id) => '/orders/$id';
  static String payOrder(String id) => '/orders/$id/pay';
  static String cancelOrder(String id) => '/orders/$id/cancel';

  // Queues
  static const String activeQueues = '/queues/active';
  static const String currentQueueState = '/queues/current';
  static String queueDetail(String id) => '/queues/$id';

  // Reviews
  static const String reviews = '/reviews';

  // Chat
  static const String chatRoom = '/chat/room';
  static String chatMessages(String roomId) => '/chat/room/$roomId/messages';

  // Cooperative Info
  static const String operatingHours = '/cooperative/hours';
  static const String crowdData = '/cooperative/crowd';
  static const String cooperativeStatus = '/cooperative/status';
  static const String cooperativeInfo = '/cooperative/info';

  // Notifications
  static const String notifications = '/notifications';
  static String readNotification(String id) => '/notifications/$id/read';
  static const String readAllNotifications = '/notifications/read-all';

  // Complaints
  static const String complaints = '/complaints';
  static const String myComplaints = '/complaints/me';
  static String scheduleReturn(String complaintId) => '/complaints/$complaintId/return-schedule';
  static const String myReturnSchedules = '/complaints/return-schedules/me';

  // Favorites
  static const String favorites = '/favorites';
  static const String favoriteIds = '/favorites/ids';
  static String favoriteToggle(String productId) => '/favorites/$productId/toggle';
  static String favoriteRemove(String productId) => '/favorites/$productId';
}
