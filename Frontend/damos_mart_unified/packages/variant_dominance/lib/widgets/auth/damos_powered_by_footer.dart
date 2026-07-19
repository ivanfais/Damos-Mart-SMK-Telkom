import 'package:flutter/material.dart';
import '../../theme/damos_dominance_colors.dart';

class DamosPoweredByFooter extends StatelessWidget {
  final Color textColor;

  const DamosPoweredByFooter({
    super.key,
    this.textColor = DamosDominanceColors.textHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 1,
          color: textColor.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'POWERED BY SMK TELKOM JAKARTA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
