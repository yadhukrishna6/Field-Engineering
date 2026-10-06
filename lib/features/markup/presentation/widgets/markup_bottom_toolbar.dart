import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/markup_editor_controller.dart';

class MarkupBottomToolbar extends StatelessWidget {
  final MarkupEditorState state;
  final MarkupEditorController controller;
  final VoidCallback onResetZoom;

  const MarkupBottomToolbar({
    super.key,
    required this.state,
    required this.controller,
    required this.onResetZoom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final zoomPct = (state.zoomLevel * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.96),
        border: Border(top: BorderSide(color: outlineColor, width: 1.0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Layers toggle button
              IconButton(
                icon: Icon(
                  state.isLayersPanelOpen ? Icons.layers_rounded : Icons.layers_outlined,
                  color: state.isLayersPanelOpen ? primaryColor : textColor,
                  size: 20,
                ),
                tooltip: 'Toggle Layers Panel',
                onPressed: () => controller.toggleLayersPanel(),
              ),
              const SizedBox(width: 4),

              // 7 Reference-Style Color Dots
              Row(
                children: kReferenceColorPresets.map((color) {
                  final isSelected = state.activeColor.value == color.value;
                  return GestureDetector(
                    onTap: () => controller.setColor(color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : outlineColor,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [const BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 10),

              // Stroke Width Slider
              SizedBox(
                width: 110,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: outlineColor,
                    thumbColor: primaryColor,
                  ),
                  child: Slider(
                    value: state.activeStrokeWidth,
                    min: 1.0,
                    max: 12.0,
                    onChanged: (val) => controller.setStrokeWidth(val),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Undo
              IconButton(
                icon: const Icon(Icons.undo_rounded, size: 20),
                tooltip: 'Undo (or Undo Snap)',
                onPressed: state.canUndo ? () => controller.undo() : null,
              ),

              // Redo
              IconButton(
                icon: const Icon(Icons.redo_rounded, size: 20),
                tooltip: 'Redo',
                onPressed: state.canRedo ? () => controller.redo() : null,
              ),

              const SizedBox(width: 4),

              // Zoom % Pill (Tap to reset)
              InkWell(
                onTap: onResetZoom,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: outlineColor),
                  ),
                  child: Text(
                    '$zoomPct%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Fullscreen Toggle
              IconButton(
                icon: Icon(
                  state.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  size: 20,
                  color: textColor,
                ),
                tooltip: state.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                onPressed: () => controller.toggleFullscreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
