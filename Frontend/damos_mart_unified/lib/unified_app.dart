import 'dart:async';

import 'package:disc_core/disc_core.dart';
import 'package:flutter/material.dart';
import 'package:variant_conscientiousness/variant_entry.dart' as conscientiousness;
import 'package:variant_dominance/variant_entry.dart' as dominance;
import 'package:variant_influence/variant_entry.dart' as influence;
import 'package:variant_steadiness/variant_entry.dart' as steadiness;

import 'core/disc_variant_storage.dart';
import 'core/unified_restart.dart';

/// Host wrapper that mounts the active DISC variant Flutter app.
class UnifiedVariantApp extends StatefulWidget {
  const UnifiedVariantApp({super.key, required this.variant});

  final DiscVariant variant;

  @override
  State<UnifiedVariantApp> createState() => _UnifiedVariantAppState();
}

class _UnifiedVariantAppState extends State<UnifiedVariantApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant UnifiedVariantApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variant != widget.variant) {
      _ready = false;
      _prepare();
    }
  }

  Future<void> _prepare() async {
    final fastSwitch = UnifiedHostBridge.fastVariantSwitch;
    if (fastSwitch) {
      UnifiedHostBridge.fastVariantSwitch = false;
    }

    UnifiedHostBridge.hostActiveVariant = widget.variant;
    UnifiedHostBridge.switchVariant = _switchVariant;

    if (fastSwitch) {
      if (mounted) setState(() => _ready = true);
      unawaited(_bootstrap(widget.variant));
      return;
    }

    await _bootstrap(widget.variant);
    if (mounted) setState(() => _ready = true);
  }

  Future<bool> _switchVariant(DiscVariant next) async {
    if (next == widget.variant) return false;
    await DiscVariantStorage.save(next);
    if (!mounted) return true;
    UnifiedHostBridge.resetSplashOnMount = true;
    UnifiedHostBridge.fastVariantSwitch = true;
    UnifiedHostBridge.variantSessionId++;
    UnifiedRestart.restart();
    return true;
  }

  Future<void> _bootstrap(DiscVariant variant) async {
    switch (variant) {
      case DiscVariant.conscientiousness:
        await conscientiousness.VariantEntry.bootstrap(variant);
      case DiscVariant.influence:
        await influence.VariantEntry.bootstrap(variant);
      case DiscVariant.dominance:
        await dominance.VariantEntry.bootstrap(variant);
      case DiscVariant.steadiness:
        await steadiness.VariantEntry.bootstrap(variant);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return switch (widget.variant) {
      DiscVariant.conscientiousness => conscientiousness.VariantEntry.app(),
      DiscVariant.influence => influence.VariantEntry.app(),
      DiscVariant.dominance => dominance.VariantEntry.app(),
      DiscVariant.steadiness => steadiness.VariantEntry.app(),
    };
  }
}
