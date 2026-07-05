class NotificationPayload {
  NotificationPayload._();

  static const String _orderPrefix = 'order:';
  static const String _queuePrefix = 'queue:';
  static const String _complaintPrefix = 'complaint:';

  static String orderDetail(String orderId) => '$_orderPrefix$orderId';

  static String queueDetail(String queueId) => '$_queuePrefix$queueId';

  static String complaintDetail(String complaintId) =>
      '$_complaintPrefix$complaintId';

  static String? parseOrderId(String? payload) {
    if (payload == null || !payload.startsWith(_orderPrefix)) return null;
    final orderId = payload.substring(_orderPrefix.length);
    return orderId.isEmpty ? null : orderId;
  }

  static String? parseQueueId(String? payload) {
    if (payload == null || !payload.startsWith(_queuePrefix)) return null;
    final queueId = payload.substring(_queuePrefix.length);
    return queueId.isEmpty ? null : queueId;
  }

  static String? parseComplaintId(String? payload) {
    if (payload == null || !payload.startsWith(_complaintPrefix)) return null;
    final complaintId = payload.substring(_complaintPrefix.length);
    return complaintId.isEmpty ? null : complaintId;
  }
}
