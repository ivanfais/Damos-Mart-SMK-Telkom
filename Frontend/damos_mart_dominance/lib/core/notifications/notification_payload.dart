class NotificationPayload {
  NotificationPayload._();

  static const String _orderPrefix = 'order:';

  static String orderDetail(String orderId) => '$_orderPrefix$orderId';

  static String? parseOrderId(String? payload) {
    if (payload == null || !payload.startsWith(_orderPrefix)) return null;
    final orderId = payload.substring(_orderPrefix.length);
    return orderId.isEmpty ? null : orderId;
  }
}
