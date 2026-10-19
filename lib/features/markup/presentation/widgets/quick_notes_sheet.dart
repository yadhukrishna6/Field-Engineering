import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum QuickNoteType {
  delete('DELETE', 'delete', Color(0xFFD03A33), Color(0xFFC62828), Icons.delete_outline_rounded, 'Mark item for deletion'),
  add('ADD', 'add', Color(0xFFE06A26), Color(0xFFC25E00), Icons.add_circle_outline_rounded, 'Mark new component to install'),
  replace('REPLACE', 'replace', Color(0xFFD03A33), Color(0xFFC62828), Icons.published_with_changes_rounded, 'Mark component for replacement'),
  relocate('RELOCATE', 'relocate', Color(0xFF1E88E5), Color(0xFF185FA5), Icons.drive_file_move_rounded, 'Relocate pipe spool / valve'),
  verify('VERIFY IN FIELD', 'verify', Color(0xFF1E88E5), Color(0xFF185FA5), Icons.fact_check_outlined, 'Verify dimensions / specs on site');

  final String label;
  final String changeType;
  final Color standardColor;
  final Color outdoorColor;
  final IconData icon;
  final String description;

  const QuickNoteType(
    this.label,
    this.changeType,
    this.standardColor,
    this.outdoorColor,
    this.icon,
    this.description,
  );

  Color getColor(bool isOutdoor) => isOutdoor ? outdoorColor : standardColor;
}

class QuickNotesSheet extends StatelessWidget {
  final bool isOutdoor;
  final bool isDark;
  final ValueChanged<QuickNoteType> onSelectQuickNote;

  const QuickNotesSheet({
    super.key,
    required this.isOutdoor,
    required this.isDark,
    required this.onSelectQuickNote,
  });

  static Future<QuickNoteType?> show(BuildContext context, {required bool isOutdoor, required bool isDark}) {
    return showModalBottomSheet<QuickNoteType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickNotesSheet(
        isOutdoor: isOutdoor,
        isDark: isDark,
        onSelectQuickNote: (note) => Navigator.pop(ctx, note),
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
                      Icon(Icons.bolt_rounded, color: primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Standard Quick-Notes',
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
                'Select a standard change note, then tap anywhere on the drawing to place it.',
                style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 14),
              ...QuickNoteType.values.map((q) {
                final color = q.getColor(isOutdoor);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => onSelectQuickNote(q),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
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
                            child: Icon(q.icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.label,
                                  style: AppTypography.engineeringTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  q.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              q.changeType.toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
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
