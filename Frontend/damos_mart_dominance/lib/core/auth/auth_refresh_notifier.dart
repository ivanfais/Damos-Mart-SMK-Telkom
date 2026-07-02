import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] to re-run auth redirects when session changes.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier._();

  static final AuthRefreshNotifier instance = AuthRefreshNotifier._();

  void refresh() => notifyListeners();
}
