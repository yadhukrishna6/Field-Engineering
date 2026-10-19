import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glove_mode_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../controllers/markup_editor_controller.dart';
import 'quick_notes_sheet.dart';
import 'stamps_sheet.dart';

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

  String _getColorMeaningTooltip(Color color) {
    if (color == const Color(0xFFD03A33) || color == const Color(0xFFC62828)) {
      return 'Red - Revision / Delete / Replace';
    } else if (color == const Color(0xFF1E88E5) || color == const Color(0xFF185FA5)) {
      return 'Blue - Client Comment / Relocate / Verify';
    } else if (color == const Color(0xFF2E7D32) || color == const Color(0xFF1F6B2D)) {
      return 'Green - Approved / Dimension';
    } else if (color == const Color(0xFFE06A26) || color == const Color(0xFFC25E00)) {
      return 'Orange - Add / Hold / Caution';
    } else if (color == const Color(0xFF111111) || color == const Color(0xFF212121)) {
      return 'Black - General / Neutral';
    }
    return 'Color Preset';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final isOutdoor = themeState.isOutdoorActive;
    final isDark = themeState.isDarkActive;
    final gloveState = ref.watch(gloveModeProvider);
    final isGlove = gloveState.isGloveMode;
    final minTouchTarget = gloveState.minTouchTarget(isOutdoor);
    final iconSize = gloveState.iconSize(isOutdoor);

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
      padding: EdgeInsets.symmetric(horizontal: isGlove ? 8 : 12, vertical: isGlove ? 8 : 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: outlineColor, width: isOutdoor ? 1.5 : 1.0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Layers Toggle, Quick-Notes & Stamps Shortcut
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Layers Panel Toggle
                  InkWell(
                    onTap: () => controller.toggleLayersPanel(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: BoxConstraints(minHeight: minTouchTarget, minWidth: minTouchTarget),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: state.isLayersPanelOpen ? primaryColor.withOpacity(0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: state.isLayersPanelOpen ? primaryColor : outlineColor,
                          width: isOutdoor ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.layers_rounded, size: iconSize - 4, color: state.isLayersPanelOpen ? primaryColor : textColor),
                          const SizedBox(width: 4),
                          Text(
                            'Layers',
                            style: TextStyle(
                              fontSize: isOutdoor ? 12 : 11,
                              fontWeight: FontWeight.bold,
                              color: state.isLayersPanelOpen ? primaryColor : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Quick-Notes Button (Phase B)
                  InkWell(
                    onTap: () async {
                      final chosen = await QuickNotesSheet.show(context, isOutdoor: isOutdoor, isDark: isDark);
                      if (chosen != null) {
                        controller.setQuickNoteType(chosen, isOutdoor);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: BoxConstraints(minHeight: minTouchTarget, minWidth: minTouchTarget),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: state.selectedTool == MarkupTool.quickNote ? primaryColor.withOpacity(0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: state.selectedTool == MarkupTool.quickNote ? primaryColor : outlineColor,
                          width: isOutdoor ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: iconSize - 4, color: state.selectedTool == MarkupTool.quickNote ? primaryColor : textColor),
                          const SizedBox(width: 4),
                          Text(
                            state.selectedTool == MarkupTool.quickNote && state.activeQuickNoteType != null
                                ? state.activeQuickNoteType!.label
                                : 'Quick Note',
                            style: TextStyle(
                              fontSize: isOutdoor ? 12 : 11,
                              fontWeight: FontWeight.bold,
                              color: state.selectedTool == MarkupTool.quickNote ? primaryColor : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Stamps Button (Phase B)
                  InkWell(
                    onTap: () async {
                      final stamp = await StampsSheet.show(context, isOutdoor: isOutdoor, isDark: isDark);
                      if (stamp != null) {
                        controller.setStampType(stamp, isOutdoor);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: BoxConstraints(minHeight: minTouchTarget, minWidth: minTouchTarget),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: state.selectedTool == MarkupTool.stamp ? primaryColor.withOpacity(0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: state.selectedTool == MarkupTool.stamp ? primaryColor : outlineColor,
                          width: isOutdoor ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.approval_rounded, size: iconSize - 4, color: state.selectedTool == MarkupTool.stamp ? primaryColor : textColor),
                          const SizedBox(width: 4),
                          Text(
                            'Stamps',
                            style: TextStyle(
                              fontSize: isOutdoor ? 12 : 11,
                              fontWeight: FontWeight.bold,
                              color: state.selectedTool == MarkupTool.stamp ? primaryColor : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Center: Preset Color Dots with Tooltips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: activeColorPresets.map((color) {
                  final isSelected = state.activeColor.value == color.value;
                  final dotSize = isGlove ? 34.0 : (isOutdoor ? 30.0 : 26.0);

                  return Tooltip(
                    message: _getColorMeaningTooltip(color),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isGlove ? 4 : 3),
                      child: InkWell(
                        onTap: () => controller.setColor(color),
                        borderRadius: BorderRadius.circular(dotSize / 2),
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? primaryColor : (isOutdoor ? AppColors.outdoorOutline : Colors.black26),
                              width: isSelected ? 3.0 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)]
                                : null,
                          ),
                          child: isSelected
                              ? const Center(child: Icon(Icons.check_rounded, size: 16, color: Colors.white))
                              : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(width: 12),

              // Right: Glove Mode Toggle, Wipe Lock Toggle, Zoom & Undo/Redo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glove Mode Toggle
                  Tooltip(
                    message: isGlove ? 'Glove Mode Active (>= 56dp touch targets)' : 'Enable Glove Mode',
                    child: InkWell(
                      onTap: () {
                        ref.read(gloveModeProvider.notifier).toggleGloveMode();
                        controller.setGloveMode(!isGlove);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: BoxConstraints(minHeight: minTouchTarget, minWidth: minTouchTarget),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isGlove ? primaryColor.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isGlove ? primaryColor : outlineColor, width: isOutdoor ? 1.5 : 1.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.sports_handball_rounded, size: iconSize - 4, color: isGlove ? primaryColor : textColor),
                            const SizedBox(width: 4),
                            Text(
                              'Glove',
                              style: TextStyle(
                                fontSize: isOutdoor ? 11 : 10,
                                fontWeight: FontWeight.bold,
                                color: isGlove ? primaryColor : textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Wipe Lock Toggle
                  Tooltip(
                    message: state.isWipeLocked ? 'Canvas Frozen (Wipe Lock)' : 'Lock Canvas to Wipe Screen Dust',
                    child: IconButton(
                      icon: Icon(
                        state.isWipeLocked ? Icons.lock_rounded : Icons.lock_outline_rounded,
                        color: state.isWipeLocked ? primaryColor : textColor,
                        size: iconSize - 2,
                      ),
                      onPressed: () => controller.toggleWipeLock(),
                    ),
                  ),

                  // Undo / Redo
                  IconButton(
                    icon: Icon(Icons.undo_rounded, size: iconSize - 4),
                    color: state.canUndo ? textColor : textColor.withOpacity(0.3),
                    tooltip: 'Undo (reverts snap / stroke)',
                    onPressed: state.canUndo ? () => controller.undo() : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.redo_rounded, size: iconSize - 4),
                    color: state.canRedo ? textColor : textColor.withOpacity(0.3),
                    tooltip: 'Redo',
                    onPressed: state.canRedo ? () => controller.redo() : null,
                  ),

                  // Zoom Percentage Chip
                  InkWell(
                    onTap: onResetZoom,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      constraints: BoxConstraints(minHeight: minTouchTarget * 0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOutdoor ? AppColors.outdoorChip : AppColors.lightChip,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: outlineColor, width: isOutdoor ? 1.5 : 1.0),
                      ),
                      child: Text(
                        '$zoomPct%',
                        style: TextStyle(
                          fontSize: isOutdoor ? 12 : 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
