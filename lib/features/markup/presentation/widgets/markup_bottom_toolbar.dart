import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/markup_editor_controller.dart';

class MarkupBottomToolbar extends StatelessWidget {
  final MarkupEditorState state;
  final MarkupEditorController controller;

  const MarkupBottomToolbar({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Pen Tool, Stroke Widths, Finger Drawing Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pen Tool Toggle
                InkWell(
                  onTap: () => controller.selectTool(MarkupTool.pen),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: state.selectedTool == MarkupTool.pen
                          ? AppColors.safetyOrange.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: state.selectedTool == MarkupTool.pen
                            ? AppColors.safetyOrange
                            : Colors.transparent,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_rounded, color: AppColors.safetyOrange, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Pen',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3 Stroke Width Presets (Thin, Medium, Thick)
                Row(
                  children: [
                    _buildWidthOption(2.0, 'Thin', 4.0),
                    const SizedBox(width: 8),
                    _buildWidthOption(4.0, 'Medium', 8.0),
                    const SizedBox(width: 8),
                    _buildWidthOption(8.0, 'Thick', 12.0),
                  ],
                ),

                // Finger Drawing Toggle
                IconButton(
                  icon: Icon(
                    state.allowFingerDrawing ? Icons.touch_app_rounded : Icons.edit_note_rounded,
                    color: state.allowFingerDrawing ? Colors.cyanAccent : Colors.grey,
                  ),
                  tooltip: state.allowFingerDrawing ? 'Finger Drawing ON' : 'Stylus Only',
                  onPressed: () => controller.toggleFingerDrawing(),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: 4 Color Preset Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: kMarkupColorPresets.map((color) {
                final isSelected = state.activeColor.value == color.value;
                return GestureDetector(
                  onTap: () => controller.setColor(color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.black26,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidthOption(double width, String label, double dotSize) {
    final isSelected = state.activeStrokeWidth == width;
    return GestureDetector(
      onTap: () => controller.setStrokeWidth(width),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.safetyOrange.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.safetyOrange : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.safetyOrange : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
