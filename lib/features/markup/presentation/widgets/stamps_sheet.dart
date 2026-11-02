import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum StampType {
  // --- 3 Standard Built-in Engineering Seals ---
  qaQcSeal(
    'QA / QC APPROVED (Seal 1)',
    Color(0xFF1B5E20),
    Color(0xFF1B5E20),
    Icons.verified_rounded,
    isStandardSeal: true,
    sealCode: 'qaQcSeal',
    subtitle: 'Dual-Ring Circular Quality Seal (Field Inspected)',
  ),
  safetySeal(
    'SAFETY & STRUCTURAL (Seal 2)',
    Color(0xFF0D47A1),
    Color(0xFF0D47A1),
    Icons.shield_rounded,
    isStandardSeal: true,
    sealCode: 'safetySeal',
    subtitle: 'ASME / OSHA Integrity Badge',
  ),
  peSeal(
    'LICENSED PE SEAL (Seal 3)',
    Color(0xFFB71C1C),
    Color(0xFFB71C1C),
    Icons.engineering_rounded,
    isStandardSeal: true,
    sealCode: 'peSeal',
    subtitle: 'Official Circular PE Board License Seal',
  ),

  // --- Official Reusable Engineer Signature ---
  engineerSignature(
    'OFFICIAL SIGNATURE',
    Color(0xFF1A237E),
    Color(0xFF1A237E),
    Icons.draw_rounded,
    isStandardSeal: true,
    sealCode: 'signature',
    subtitle: 'Consistent Authorized Signature • Yadhukrishna, PE',
  ),

  // --- Dynamic Job Number Badge ---
  jobNumberBadge(
    'JOB NUMBER BADGE',
    Color(0xFF37474F),
    Color(0xFF37474F),
    Icons.tag_rounded,
    isStandardSeal: true,
    sealCode: 'jobNumber',
    subtitle: 'Dynamic Job Number Badge (Last 3 Digits Editable)',
  ),

  // --- Document Status Stamps ---
  approved('APPROVED FOR CONSTRUCTION', Color(0xFF2E7D32), Color(0xFF1F6B2D), Icons.verified_rounded),
  controlledCopy('CONTROLLED COPY', Color(0xFF1E88E5), Color(0xFF185FA5), Icons.lock_clock_rounded),
  rejected('REJECTED', Color(0xFFD03A33), Color(0xFFC62828), Icons.cancel_rounded),
  asBuilt('AS-BUILT DRAWING', Color(0xFF00897B), Color(0xFF08605B), Icons.task_alt_rounded),
  hold('HOLD - DO NOT CONSTRUCT', Color(0xFFE06A26), Color(0xFFC25E00), Icons.pause_circle_filled_rounded);

  final String title;
  final Color standardColor;
  final Color outdoorColor;
  final IconData icon;
  final bool isStandardSeal;
  final String? sealCode;
  final String? subtitle;

  const StampType(
    this.title,
    this.standardColor,
    this.outdoorColor,
    this.icon, {
    this.isStandardSeal = false,
    this.sealCode,
    this.subtitle,
  });

  Color getColor(bool isOutdoor) => isOutdoor ? outdoorColor : standardColor;
}

class StampsSheet extends StatelessWidget {
  final bool isOutdoor;
  final bool isDark;
  final ValueChanged<StampType> onSelectStamp;
  final VoidCallback? onApplyStandardSet;

  const StampsSheet({
    super.key,
    required this.isOutdoor,
    required this.isDark,
    required this.onSelectStamp,
    this.onApplyStandardSet,
  });

  static Future<StampType?> show(
    BuildContext context, {
    required bool isOutdoor,
    required bool isDark,
    VoidCallback? onApplyStandardSet,
  }) {
    return showModalBottomSheet<StampType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StampsSheet(
        isOutdoor: isOutdoor,
        isDark: isDark,
        onApplyStandardSet: onApplyStandardSet,
        onSelectStamp: (stamp) => Navigator.pop(ctx, stamp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isOutdoor
        ? AppColors.outdoorSurface
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final outlineColor = isOutdoor
        ? AppColors.outdoorOutline
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final textColor = isOutdoor
        ? AppColors.outdoorText
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final standardSeals = StampType.values.where((s) => s.isStandardSeal).toList();
    final statusStamps = StampType.values.where((s) => !s.isStandardSeal).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: outlineColor, width: isOutdoor ? 2.0 : 1.0),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.approval_rounded, color: primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Engineering Seals & Stamps',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Standard 3 seals, signature & job number are built-in and freely draggable.',
                style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 14),

              // Quick Action: Predefined Title Block Placement
              if (onApplyStandardSet != null) ...[
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onApplyStandardSet!();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: primaryColor.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Place Standard Seals & Signature in Title Block',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Section 1: Standard Seals & Signature
              Text(
                'STANDARD BUILT-IN ELEMENTS (DRAGGABLE)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ...standardSeals.map((s) => _buildStampCard(context, s, isOutdoor, textColor, nowStr)),

              const SizedBox(height: 14),

              // Section 2: Status Stamps
              Text(
                'DOCUMENT STATUS STAMPS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textColor.withOpacity(0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ...statusStamps.map((s) => _buildStampCard(context, s, isOutdoor, textColor, nowStr)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStampCard(
    BuildContext context,
    StampType s,
    bool isOutdoor,
    Color textColor,
    String nowStr,
  ) {
    final color = s.getColor(isOutdoor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSelectStamp(s),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: isOutdoor ? 2.0 : 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(s.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: AppTypography.engineeringTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.subtitle ?? 'BY: Field Engineer  |  DATE: $nowStr',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'JetBrainsMono',
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.touch_app_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
