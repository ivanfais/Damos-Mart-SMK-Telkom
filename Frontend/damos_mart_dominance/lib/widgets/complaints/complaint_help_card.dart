import 'package:flutter/material.dart';
import '../../core/utils/complaint_status_helper.dart';
import '../../data/models/complaint_model.dart';
import '../../theme/damos_dominance_colors.dart';

class ComplaintHelpCard extends StatelessWidget {
  const ComplaintHelpCard({
    super.key,
    required this.onComplaintPressed,
  });

  final VoidCallback onComplaintPressed;

  static const _cardRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: DamosDominanceColors.fieldBorder),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.contact_support_outlined,
                  size: 40,
                  color: DamosDominanceColors.textPrimary,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mengalami Kendala?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: DamosDominanceColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Contoh: pembayaran, pengambilan, dsb',
                        style: TextStyle(
                          fontSize: 12,
                          color: DamosDominanceColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onComplaintPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: DamosDominanceColors.primary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: DamosDominanceColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_cardRadius),
                ),
              ),
              child: const Text(
                'Ajukan Komplain',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintStatusSummaryCard extends StatelessWidget {
  const ComplaintStatusSummaryCard({
    super.key,
    required this.complaint,
    required this.onTap,
  });

  final ComplaintModel complaint;
  final VoidCallback onTap;

  static const _cardRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    final badge = ComplaintStatusHelper.badgeTheme(complaint);
    final ticket = complaint.displayTicketNumber;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: DamosDominanceColors.fieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Status Komplain',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: DamosDominanceColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badge.backgroundColor,
                      borderRadius: BorderRadius.circular(_cardRadius),
                    ),
                    child: Text(
                      badge.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badge.foregroundColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'No. Tiket',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: DamosDominanceColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    ticket,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: DamosDominanceColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: DamosDominanceColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComplaintHistoryBanner extends StatelessWidget {
  const ComplaintHistoryBanner({
    super.key,
    required this.onComplaintPressed,
  });

  final VoidCallback onComplaintPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: DamosDominanceColors.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Ada masalah dengan pesanan ini?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DamosDominanceColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onComplaintPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ajukan Komplain',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: DamosDominanceColors.primary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: DamosDominanceColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
