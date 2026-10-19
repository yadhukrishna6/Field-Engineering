import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum StampType {
  approved('APPROVED FOR CONSTRUCTION', Color(0xFF2E7D32), Color(0xFF1F6B2D), Icons.verified_rounded),
  controlledCopy('CONTROLLED COPY', Color(0xFF1E88E5), Color(0xFF185FA5), Icons.lock_clock_rounded),
  rejected('REJECTED', Color(0xFFD03A33), Color(0xFFC62828), Icons.cancel_rounded),
  asBuilt('AS-BUILT DRAWING', Color(0xFF00897B), Color(0xFF08605B), Icons.task_alt_rounded),
  hold('HOLD - DO NOT CONSTRUCT', Color(0xFFE06A26), Color(0xFFC25E00), Icons.pause_circle_filled_rounded);

  final String title;
  final Color standardColor;
  final Color outdoorColor;
  final IconData icon;

  const StampType(this.title, this.standardColor, this.outdoorColor, this.icon);

  Color getColor(bool isOutdoor) => isOutdoor ? outdoorColor : standardColor;
}

class StampsSheet extends StatelessWidget {
  final bool isOutdoor;
  final bool isDark;
  final ValueChanged<StampType> onSelectStamp;

  const StampsSheet({
    super.key,
    required this.isOutdoor,
    required this.isDark,
    required this.onSelectStamp,
  });

  static Future<StampType?> show(BuildContext context, {required bool isOutdoor, required bool isDark}) {
    return showModalBottomSheet<StampType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StampsSheet(
        isOutdoor: isOutdoor,
        isDark: isDark,
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                        'Official Engineering Stamps',
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
              const SizedBox(height: 4),
              Text(
                'Stamps auto-fill timestamp and user name on a locked inspection layer.',
                style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 14),
              ...StampType.values.map((s) {
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
                                  'BY: Field Engineer  |  DATE: $nowStr',
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
              }),
            ],
          ),
        ),
      ),
    );
  }
}
