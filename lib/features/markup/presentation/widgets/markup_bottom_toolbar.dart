import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/markup_editor_controller.dart';

class MarkupBottomToolbar extends StatelessWidget {
  final MarkupEditorState state;
  final MarkupEditorController controller;
  final bool isVerticalRail;

  const MarkupBottomToolbar({
    super.key,
    required this.state,
    required this.controller,
    this.isVerticalRail = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    if (isVerticalRail) {
      return Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(right: BorderSide(color: outlineColor, width: 1.0)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TOOLS',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryTextColor),
              ),
              const SizedBox(height: 8),
              _buildToolButton(MarkupTool.pen, Icons.edit_rounded, 'Pen', primaryColor, textColor, secondaryTextColor),
              const SizedBox(height: 6),
              _buildToolButton(MarkupTool.text, Icons.text_fields_rounded, 'Text', primaryColor, textColor, secondaryTextColor),
              const SizedBox(height: 6),
              _buildToolButton(MarkupTool.eraser, Icons.auto_fix_high_rounded, 'Eraser', Colors.redAccent, textColor, secondaryTextColor),
              Divider(height: 20, color: outlineColor),
              if (state.selectedTool == MarkupTool.pen) ...[
                Text(
                  'WIDTH',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryTextColor),
                ),
                const SizedBox(height: 8),
                _buildWidthOption(2.0, 'Thin', 4.0, primaryColor, outlineColor, textColor, secondaryTextColor),
                const SizedBox(height: 6),
                _buildWidthOption(4.0, 'Medium', 7.0, primaryColor, outlineColor, textColor, secondaryTextColor),
                const SizedBox(height: 6),
                _buildWidthOption(8.0, 'Thick', 11.0, primaryColor, outlineColor, textColor, secondaryTextColor),
                Divider(height: 20, color: outlineColor),
                Text(
                  'COLOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryTextColor),
                ),
                const SizedBox(height: 8),
                _buildVerticalColorPresets(outlineColor),
              ] else if (state.selectedTool == MarkupTool.text) ...[
                Text(
                  'SIZE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryTextColor),
                ),
                const SizedBox(height: 8),
                _buildSizeOption('S', 'Small', primaryColor, outlineColor, textColor),
                const SizedBox(height: 6),
                _buildSizeOption('M', 'Medium', primaryColor, outlineColor, textColor),
                const SizedBox(height: 6),
                _buildSizeOption('L', 'Large', primaryColor, outlineColor, textColor),
                Divider(height: 20, color: outlineColor),
                Text(
                  'COLOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryTextColor),
                ),
                const SizedBox(height: 8),
                _buildVerticalColorPresets(outlineColor),
                if (state.selectedLabelId != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete_rounded, size: 14),
                    label: const Text('Delete', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.deleteSelectedLabel(),
                  ),
                ],
              ] else if (state.selectedTool == MarkupTool.eraser) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tap or swipe over item to erase',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              Divider(height: 20, color: outlineColor),
              IconButton(
                icon: Icon(
                  state.allowFingerDrawing ? Icons.touch_app_rounded : Icons.edit_note_rounded,
                  color: state.allowFingerDrawing ? primaryColor : secondaryTextColor,
                ),
                tooltip: state.allowFingerDrawing ? 'Finger Drawing ON' : 'Stylus Only',
                onPressed: () => controller.toggleFingerDrawing(),
              ),
            ],
          ),
        ),
      );
    }

    // Phone Bottom Toolbar
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: outlineColor, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Tools & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildToolButton(MarkupTool.pen, Icons.edit_rounded, 'Pen', primaryColor, textColor, secondaryTextColor),
                    const SizedBox(width: 8),
                    _buildToolButton(MarkupTool.text, Icons.text_fields_rounded, 'Text', primaryColor, textColor, secondaryTextColor),
                    const SizedBox(width: 8),
                    _buildToolButton(MarkupTool.eraser, Icons.auto_fix_high_rounded, 'Eraser', Colors.redAccent, textColor, secondaryTextColor),
                  ],
                ),
                if (state.selectedTool == MarkupTool.text && state.selectedLabelId != null)
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                    tooltip: 'Delete Selected Label',
                    onPressed: () => controller.deleteSelectedLabel(),
                  )
                else
                  IconButton(
                    icon: Icon(
                      state.allowFingerDrawing ? Icons.touch_app_rounded : Icons.edit_note_rounded,
                      color: state.allowFingerDrawing ? primaryColor : secondaryTextColor,
                    ),
                    tooltip: state.allowFingerDrawing ? 'Finger Inking Active' : 'Stylus Only Mode',
                    onPressed: () => controller.toggleFingerDrawing(),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Tool Context Options
            if (state.selectedTool == MarkupTool.pen) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildWidthOption(2.0, 'Thin', 4.0, primaryColor, outlineColor, textColor, secondaryTextColor),
                      const SizedBox(width: 6),
                      _buildWidthOption(4.0, 'Medium', 7.0, primaryColor, outlineColor, textColor, secondaryTextColor),
                      const SizedBox(width: 6),
                      _buildWidthOption(8.0, 'Thick', 11.0, primaryColor, outlineColor, textColor, secondaryTextColor),
                    ],
                  ),
                  _buildColorPresets(outlineColor),
                ],
              ),
            ] else if (state.selectedTool == MarkupTool.text) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildSizeOption('S', 'Small', primaryColor, outlineColor, textColor),
                      const SizedBox(width: 6),
                      _buildSizeOption('M', 'Med', primaryColor, outlineColor, textColor),
                      const SizedBox(width: 6),
                      _buildSizeOption('L', 'Lrg', primaryColor, outlineColor, textColor),
                    ],
                  ),
                  _buildColorPresets(outlineColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                state.selectedLabelId != null
                    ? 'Label selected: Drag to move • Tap trash to delete'
                    : 'Tap drawing to place label • Fixed Engineering Font',
                style: TextStyle(fontSize: 10, color: secondaryTextColor),
              ),
            ] else if (state.selectedTool == MarkupTool.eraser) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cleaning_services_rounded, size: 15, color: Colors.redAccent),
                    SizedBox(width: 6),
                    Text(
                      'Tap or swipe across any stroke or label to erase',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
    MarkupTool tool,
    IconData icon,
    String label,
    Color activeColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final isSelected = state.selectedTool == tool;

    return InkWell(
      onTap: () => controller.selectTool(tool),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : secondaryTextColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : secondaryTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPresets(Color outlineColor) {
    return Row(
      children: kMarkupColorPresets.map((color) {
        final isSelected = state.activeColor.value == color.value;
        return GestureDetector(
          onTap: () => controller.setColor(color),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : outlineColor,
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: isSelected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerticalColorPresets(Color outlineColor) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: kMarkupColorPresets.map((color) {
        final isSelected = state.activeColor.value == color.value;
        return GestureDetector(
          onTap: () => controller.setColor(color),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : outlineColor,
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: isSelected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWidthOption(
    double width,
    String label,
    double dotSize,
    Color primaryColor,
    Color outlineColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final isSelected = state.activeStrokeWidth == width;
    return GestureDetector(
      onTap: () => controller.setStrokeWidth(width),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? primaryColor : outlineColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : secondaryTextColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption(
    String sizeCode,
    String label,
    Color primaryColor,
    Color outlineColor,
    Color textColor,
  ) {
    final isSelected = state.activeLabelSize == sizeCode;
    return GestureDetector(
      onTap: () => controller.setLabelSize(sizeCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? primaryColor : outlineColor),
        ),
        child: Center(
          child: Text(
            '$sizeCode ($label)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryColor : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
