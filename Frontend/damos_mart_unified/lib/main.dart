import 'package:disc_core/disc_variant.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/disc_variant_storage.dart';
import 'core/unified_restart.dart';
import 'screens/disc_picker_screen.dart';
import 'unified_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await DiscVariantStorage.init();

  runApp(const UnifiedRestart(child: DamosMartUnifiedRoot()));
}

/// Root widget: shows DISC picker until a variant is chosen, then loads it.
class DamosMartUnifiedRoot extends StatefulWidget {
  const DamosMartUnifiedRoot({super.key});

  @override
  State<DamosMartUnifiedRoot> createState() => _DamosMartUnifiedRootState();
}

class _DamosMartUnifiedRootState extends State<DamosMartUnifiedRoot> {
  DiscVariant? _activeVariant;

  @override
  void initState() {
    super.initState();
    _activeVariant = DiscVariantStorage.read();
  }

  Future<void> _onVariantSelected(DiscVariant variant) async {
    await DiscVariantStorage.save(variant);
    if (!mounted) return;
    setState(() => _activeVariant = variant);
  }

  @override
  Widget build(BuildContext context) {
    if (_activeVariant == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DiscPickerScreen(onSelected: _onVariantSelected),
      );
    }

    return UnifiedVariantApp(key: ValueKey(_activeVariant), variant: _activeVariant!);
  }
}
