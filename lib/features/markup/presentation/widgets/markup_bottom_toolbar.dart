import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../controllers/markup_editor_controller.dart';
import 'theme_selector_modal.dart';

class MarkupBottomToolbar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final isOutdoor = themeState.isOutdoorActive;
    final isDark = themeState.isDarkActive;

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

    final zoomPct = (state.zoomLevel * 100).toInt();
    final activeColorPresets = themeState.colorPresets;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isOutdoor ? 16 : 14, vertical: isOutdoor ? 8 : 6),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.98),
        border: Border(top: BorderSide(color: outlineColor, width: isOutdoor ? 1.5 : 1.0)),
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
              // Layers toggle button (Min 48dp touch target)
              IconButton(
                style: isOutdoor ? IconButton.styleFrom(minimumSize: const Size(48, 48)) : null,
                icon: Icon(
                  state.isLayersPanelOpen ? Icons.layers_rounded : Icons.layers_outlined,
                  color: state.isLayersPanelOpen ? primaryColor : textColor,
                  size: isOutdoor ? 24 : 20,
                ),
                tooltip: 'Toggle Layers Panel',
                onPressed: () => controller.toggleLayersPanel(),
              ),
              const SizedBox(width: 4),

              // Theme Selector quick-switch
              IconButton(
                style: isOutdoor ? IconButton.styleFrom(minimumSize: const Size(48, 48)) : null,
                icon: Icon(
                  isOutdoor ? Icons.wb_sunny_rounded : (isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                  color: primaryColor,
                  size: isOutdoor ? 22 : 18,
                ),
                tooltip: 'Theme: ${themeState.themeMode.label}',
                onPressed: () => ThemeSelectorModal.show(context),
              ),
              const SizedBox(width: 4),

              // Color Preset Dots (5 in Outdoor mode, 7 in Standard/Dark)
              Row(
                children: activeColorPresets.map((color) {
                  final isSelected = state.activeColor.value == color.value;
                  final dotSize = isOutdoor ? 30.0 : 24.0;
                  final touchSize = isOutdoor ? 48.0 : 32.0;

                  return GestureDetector(
                    onTap: () => controller.setColor(color),
                    child: Container(
                      width: touchSize,
                      height: touchSize,
                      alignment: Alignment.center,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? (isOutdoor ? AppColors.outdoorText : Colors.white) : outlineColor,
                            width: isSelected ? 3.0 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [const BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 8),

              // Stroke Width Slider
              SizedBox(
                width: isOutdoor ? 120 : 100,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: isOutdoor ? 4 : 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: isOutdoor ? 8 : 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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

              // Undo (Min 48dp touch target)
              IconButton(
                style: isOutdoor ? IconButton.styleFrom(minimumSize: const Size(48, 48)) : null,
                icon: Icon(Icons.undo_rounded, size: isOutdoor ? 22 : 20),
                tooltip: 'Undo (or Undo Snap)',
                onPressed: state.canUndo ? () => controller.undo() : null,
              ),

              // Redo (Min 48dp touch target)
              IconButton(
                style: isOutdoor ? IconButton.styleFrom(minimumSize: const Size(48, 48)) : null,
                icon: Icon(Icons.redo_rounded, size: isOutdoor ? 22 : 20),
                tooltip: 'Redo',
                onPressed: state.canRedo ? () => controller.redo() : null,
              ),

              const SizedBox(width: 4),

              // Zoom % Pill (Tap to reset)
              InkWell(
                onTap: onResetZoom,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isOutdoor ? 10 : 8, vertical: isOutdoor ? 6 : 4),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: outlineColor, width: isOutdoor ? 1.5 : 1.0),
                  ),
                  child: Text(
                    '$zoomPct%',
                    style: TextStyle(
                      fontSize: isOutdoor ? 13 : 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Fullscreen Toggle
              IconButton(
                style: isOutdoor ? IconButton.styleFrom(minimumSize: const Size(48, 48)) : null,
                icon: Icon(
                  state.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  size: isOutdoor ? 24 : 20,
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
