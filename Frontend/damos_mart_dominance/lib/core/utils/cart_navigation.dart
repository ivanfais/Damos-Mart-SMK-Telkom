import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CartNavigation {
  static const String _fromKey = 'from';

  static String originFromLocation(String location) {
    final path = Uri.parse(location).path;

    if (path.startsWith('/orders') ||
        path.startsWith('/history') ||
        path.startsWith('/queue')) {
      return 'history';
    }
    if (path.startsWith('/profile')) return 'profile';
    if (path.startsWith('/catalog') ||
        path.startsWith('/preorder') ||
        path.startsWith('/checkout')) {
      return 'catalog';
    }
    if (path.startsWith('/favorites')) return 'profile';
    if (path.startsWith('/home')) return 'home';
    return 'home';
  }

  static String returnPath(String? from) {
    switch (from) {
      case 'catalog':
        return '/catalog';
      case 'history':
        return '/history';
      case 'profile':
        return '/profile';
      case 'home':
      default:
        return '/home';
    }
  }

  static int shellTabIndex(String? from) {
    switch (from) {
      case 'catalog':
        return 1;
      case 'history':
        return 2;
      case 'profile':
        return 3;
      case 'home':
      default:
        return 0;
    }
  }

  static void open(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final from = originFromLocation(location);
    context.go('/cart?$_fromKey=$from');
  }

  static void back(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters[_fromKey];
    context.go(returnPath(from));
  }

  static int selectedTabIndex(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters[_fromKey];
    return shellTabIndex(from);
  }
}
