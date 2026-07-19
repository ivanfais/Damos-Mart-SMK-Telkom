import 'dart:async';

/// Broadcasts complaint status updates received via websocket.
class ComplaintRealtimeService {
  ComplaintRealtimeService._();

  static final ComplaintRealtimeService instance = ComplaintRealtimeService._();

  final StreamController<Map<String, dynamic>> _updates =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get updates => _updates.stream;

  void publish(Map<String, dynamic> data) {
    if (_updates.isClosed) return;
    _updates.add(data);
  }

  void dispose() {
    _updates.close();
  }
}
