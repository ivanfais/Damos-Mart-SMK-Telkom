import 'package:flutter/material.dart';
import '../../core/utils/password_rules.dart';
import '../../theme/damos_dominance_colors.dart';

class PasswordRequirements extends StatelessWidget {
  final String password;

  const PasswordRequirements({
    super.key,
    required this.password,
  });

  Widget _item(String label, bool met) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: met ? DamosDominanceColors.primary : DamosDominanceColors.textHint,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? DamosDominanceColors.textPrimary : DamosDominanceColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _item('Min. 8 Karakter', PasswordRules.hasMinLength(password)),
              const SizedBox(height: 8),
              _item('Huruf Kapital', PasswordRules.hasUppercase(password)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _item('Angka (0-9)', PasswordRules.hasDigit(password)),
              const SizedBox(height: 8),
              _item('Simbol (@,\$,!)', PasswordRules.hasSymbol(password)),
            ],
          ),
        ),
      ],
    );
  }
}
