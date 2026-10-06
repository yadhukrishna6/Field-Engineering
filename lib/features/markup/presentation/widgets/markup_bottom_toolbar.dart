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

    if (isVerticalRail) {
      return Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(right: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(3, 0)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'TOOLS',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              _buildToolButton(MarkupTool.pen, Icons.edit_rounded, 'Pen'),
              const SizedBox(height: 8),
              _buildToolButton(MarkupTool.text, Icons.text_fields_rounded, 'Text'),
              const SizedBox(height: 8),
              _buildToolButton(MarkupTool.eraser, Icons.auto_fix_high_rounded, 'Eraser'),
              const Divider(height: 24),
              if (state.selectedTool == MarkupTool.pen) ...[
                const Text(
                  'WIDTH',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildWidthOption(2.0, 'Thin', 4.0),
                const SizedBox(height: 6),
                _buildWidthOption(4.0, 'Medium', 7.0),
                const SizedBox(height: 6),
                _buildWidthOption(8.0, 'Thick', 11.0),
                const Divider(height: 24),
                const Text(
                  'COLOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildVerticalColorPresets(),
              ] else if (state.selectedTool == MarkupTool.text) ...[
                const Text(
                  'SIZE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildSizeOption('S', 'Small'),
                const SizedBox(height: 6),
                _buildSizeOption('M', 'Medium'),
                const SizedBox(height: 6),
                _buildSizeOption('L', 'Large'),
                const Divider(height: 24),
                const Text(
                  'COLOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildVerticalColorPresets(),
                if (state.selectedLabelId != null) ...[
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.delete_rounded, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
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
                    'Tap or drag over stroke/label to erase',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Divider(height: 24),
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
        ),
      );
    }

    // Phone / Portrait Bottom Toolbar
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
            // Row 1: Tool Selection Tabs (Pen, Text, Eraser)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildToolButton(MarkupTool.pen, Icons.edit_rounded, 'Pen'),
                    const SizedBox(width: 8),
                    _buildToolButton(MarkupTool.text, Icons.text_fields_rounded, 'Text'),
                    const SizedBox(width: 8),
                    _buildToolButton(MarkupTool.eraser, Icons.auto_fix_high_rounded, 'Eraser'),
                  ],
                ),
                if (state.selectedTool == MarkupTool.text && state.selectedLabelId != null)
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
                    tooltip: 'Delete Selected Label',
                    onPressed: () => controller.deleteSelectedLabel(),
                  )
                else
                  IconButton(
                    icon: Icon(
                      state.allowFingerDrawing ? Icons.touch_app_rounded : Icons.edit_note_rounded,
                      color: state.allowFingerDrawing ? Colors.cyanAccent : Colors.grey,
                    ),
                    tooltip: state.allowFingerDrawing ? 'Finger Inking Active' : 'Stylus Only Mode',
                    onPressed: () => controller.toggleFingerDrawing(),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Contextual Controls
            if (state.selectedTool == MarkupTool.pen) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildWidthOption(2.0, 'Thin', 4.0),
                      const SizedBox(width: 8),
                      _buildWidthOption(4.0, 'Medium', 7.0),
                      const SizedBox(width: 8),
                      _buildWidthOption(8.0, 'Thick', 11.0),
                    ],
                  ),
                  _buildColorPresets(),
                ],
              ),
            ] else if (state.selectedTool == MarkupTool.text) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildSizeOption('S', 'Small'),
                      const SizedBox(width: 8),
                      _buildSizeOption('M', 'Medium'),
                      const SizedBox(width: 8),
                      _buildSizeOption('L', 'Large'),
                    ],
                  ),
                  _buildColorPresets(),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                state.selectedLabelId != null
                    ? 'Label selected: Drag to move • Tap trash to delete'
                    : 'Tap drawing to place label • Uniform Engineering Font',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ] else if (state.selectedTool == MarkupTool.eraser) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cleaning_services_rounded, size: 16, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      'Tap or swipe across any stroke or label to erase completely',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.redAccent),
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

  Widget _buildToolButton(MarkupTool tool, IconData icon, String label) {
    final isSelected = state.selectedTool == tool;
    final activeColor = tool == MarkupTool.eraser ? Colors.redAccent : AppColors.safetyOrange;

    return InkWell(
      onTap: () => controller.selectTool(tool),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? activeColor : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 18),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPresets() {
    return Row(
      children: kMarkupColorPresets.map((color) {
        final isSelected = state.activeColor.value == color.value;
        return GestureDetector(
          onTap: () => controller.setColor(color),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.black26,
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerticalColorPresets() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: kMarkupColorPresets.map((color) {
        final isSelected = state.activeColor.value == color.value;
        return GestureDetector(
          onTap: () => controller.setColor(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.black26,
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWidthOption(double width, String label, double dotSize) {
    final isSelected = state.activeStrokeWidth == width;
    return GestureDetector(
      onTap: () => controller.setStrokeWidth(width),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.safetyOrange.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.safetyOrange : Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.safetyOrange : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
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

  Widget _buildSizeOption(String sizeCode, String label) {
    final isSelected = state.activeLabelSize == sizeCode;
    return GestureDetector(
      onTap: () => controller.setLabelSize(sizeCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.safetyOrange.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.safetyOrange : Colors.white12),
        ),
        child: Center(
          child: Text(
            '$sizeCode ($label)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.safetyOrange : null,
            ),
          ),
        ),
      ),
    );
  }
}
