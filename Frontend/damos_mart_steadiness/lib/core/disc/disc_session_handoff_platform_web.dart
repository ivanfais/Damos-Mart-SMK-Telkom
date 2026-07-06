// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

String? readHandoffParam() => Uri.base.queryParameters['disc_handoff'];

void clearHandoffParam() {
  final uri = Uri.base;
  if (!uri.queryParameters.containsKey('disc_handoff')) return;

  final query = Map<String, String>.from(uri.queryParameters)
    ..remove('disc_handoff');
  final cleaned = uri.replace(
    queryParameters: query.isEmpty ? null : query,
  );
  html.window.history.replaceState(null, '', cleaned.toString());
}

void navigateToUrl(String url) {
  html.window.location.assign(url);
}
