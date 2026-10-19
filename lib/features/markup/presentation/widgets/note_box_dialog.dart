import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class NoteBoxDialog extends StatefulWidget {
  final bool isOutdoor;
  final bool isDark;
  final String? initialText;
  final ValueChanged<String> onConfirm;

  const NoteBoxDialog({
    super.key,
    required this.isOutdoor,
    required this.isDark,
    this.initialText,
    required this.onConfirm,
  });

  static Future<String?> show(BuildContext context, {required bool isOutdoor, required bool isDark, String? initialText}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => NoteBoxDialog(
        isOutdoor: isOutdoor,
        isDark: isDark,
        initialText: initialText,
        onConfirm: (text) => Navigator.pop(ctx, text),
      ),
    );
  }

  @override
  State<NoteBoxDialog> createState() => _NoteBoxDialogState();
}

class _NoteBoxDialogState extends State<NoteBoxDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? 'NEW SPOOL TO BE INSTALLED\nFIELD VERIFIED DIMENSIONS');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isOutdoor
        ? AppColors.outdoorSurface
        : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final outlineColor = widget.isOutdoor
        ? AppColors.outdoorOutline
        : (widget.isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final textColor = widget.isOutdoor
        ? AppColors.outdoorText
        : (widget.isDark ? AppColors.darkText : AppColors.lightText);
    final primaryColor = widget.isOutdoor
        ? AppColors.outdoorPrimary
        : (widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outlineColor, width: widget.isOutdoor ? 2.0 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes_rounded, color: primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Technical Note Box',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              style: AppTypography.engineeringTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Enter multi-line technical field note...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: outlineColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2.0),
                ),
                filled: true,
                fillColor: widget.isOutdoor ? AppColors.outdoorChip : AppColors.lightChip,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: textColor.withOpacity(0.8))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Place Note Box'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      widget.onConfirm(text);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
