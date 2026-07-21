import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SearchScope { catalog, favorites }

class SearchNavigation {
  static void open(
    BuildContext context, {
    SearchScope scope = SearchScope.catalog,
    String? initialQuery,
  }) {
    final params = <String, String>{'scope': scope.name};
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      params['q'] = initialQuery.trim();
    }
    context.push(Uri(path: '/search', queryParameters: params).toString());
  }
}
