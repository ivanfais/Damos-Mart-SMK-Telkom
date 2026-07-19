import 'package:flutter/material.dart';

/// Restarts the unified host tree (e.g. after DISC variant change).
class UnifiedRestart extends StatefulWidget {
  const UnifiedRestart({super.key, required this.child});

  final Widget child;

  static _UnifiedRestartState? _state;

  static void restart() => _state?.restart();

  @override
  State<UnifiedRestart> createState() => _UnifiedRestartState();
}

class _UnifiedRestartState extends State<UnifiedRestart> {
  Key _subtreeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    UnifiedRestart._state = this;
  }

  @override
  void dispose() {
    if (UnifiedRestart._state == this) {
      UnifiedRestart._state = null;
    }
    super.dispose();
  }

  void restart() {
    setState(() => _subtreeKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _subtreeKey,
      child: widget.child,
    );
  }
}
