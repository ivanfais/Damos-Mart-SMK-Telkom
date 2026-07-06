import 'dart:async';

/// Broadcasts when the API layer clears the session (expired/invalid token).
class SessionExpiredNotifier {
  SessionExpiredNotifier._();

  static final SessionExpiredNotifier instance = SessionExpiredNotifier._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
