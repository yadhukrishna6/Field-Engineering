import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/snap_config.dart';

class SnapSettingsChip extends StatelessWidget {
  final SnapConfig snapConfig;
  final ValueChanged<SnapConfig> onConfigChanged;

  const SnapSettingsChip({
    super.key,
    required this.snapConfig,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final axisLabel = snapConfig.axisSet == SnapAxisSet.isometric ? '30° axis' : '0°/90° axis';
    final chipText = snapConfig.isEnabled ? 'Smart snap on, $axisLabel' : 'Smart snap off';

    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: 'Smart Snap & Axis Settings',
        offset: const Offset(0, 36),
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: outlineColor),
        ),
        onSelected: (value) {
          if (value == 'toggle') {
            onConfigChanged(snapConfig.copyWith(isEnabled: !snapConfig.isEnabled));
          } else if (value == 'isometric') {
            onConfigChanged(snapConfig.copyWith(
              isEnabled: true,
              axisSet: SnapAxisSet.isometric,
            ));
          } else if (value == 'orthogonal') {
            onConfigChanged(snapConfig.copyWith(
              isEnabled: true,
              axisSet: SnapAxisSet.orthogonal,
            ));
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  snapConfig.isEnabled ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: snapConfig.isEnabled ? primaryColor : outlineColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Enable Smart Snap',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'isometric',
            child: Row(
              children: [
                Icon(
                  snapConfig.axisSet == SnapAxisSet.isometric ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: snapConfig.axisSet == SnapAxisSet.isometric ? primaryColor : outlineColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Isometric (30° / 90°)',
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'orthogonal',
            child: Row(
              children: [
                Icon(
                  snapConfig.axisSet == SnapAxisSet.orthogonal ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: snapConfig.axisSet == SnapAxisSet.orthogonal ? primaryColor : outlineColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Orthogonal (0° / 90°)',
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: snapConfig.isEnabled ? primaryColor : outlineColor,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                snapConfig.isEnabled ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                size: 14,
                color: snapConfig.isEnabled ? primaryColor : AppColors.lightSecondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                chipText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: snapConfig.isEnabled ? textColor : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded, size: 16, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
