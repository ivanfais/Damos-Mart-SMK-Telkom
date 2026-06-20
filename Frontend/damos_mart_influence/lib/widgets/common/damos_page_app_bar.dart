import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Green page header for inside scroll content (not fixed).
class DamosPageHeader extends StatelessWidget {
  const DamosPageHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.leadingIcon,
    this.includeTopSafeArea = true,
    this.backgroundColor = primary,
    this.foregroundColor = Colors.white,
    this.titleWidget,
    this.trailing,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final IconData? leadingIcon;
  final bool includeTopSafeArea;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? titleWidget;
  final Widget? trailing;

  static const Color primary = Color(0xFF1B8C2E);

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = includeTopSafeArea ? MediaQuery.paddingOf(context).top : 0.0;

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: EdgeInsets.fromLTRB(
        showBackButton ? 4 : 16,
        topPadding + 8,
        16,
        12,
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: Icon(leadingIcon ?? Icons.arrow_back, color: foregroundColor),
              onPressed: () => _handleBack(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          Expanded(
            child: titleWidget ??
                Text(
                  title,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Fixed [AppBar] variant — prefer [DamosPageHeader] inside scroll when possible.
class DamosPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DamosPageAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.leadingIcon,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final IconData? leadingIcon;

  static const Color primary = Color(0xFF1B8C2E);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: showBackButton ? 0 : 16,
      leading: showBackButton
          ? IconButton(
              icon: Icon(leadingIcon ?? Icons.arrow_back, color: Colors.white),
              onPressed: () => _handleBack(context),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
