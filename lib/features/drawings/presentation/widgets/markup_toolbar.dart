import 'package:flutter/material.dart';
import '../../domain/models/markup.dart';
import '../../domain/models/measurement.dart';
import '../../domain/models/drawing_calibration.dart';
import '../controllers/markup_controller.dart';
import '../../../../core/theme/color_palette.dart';

class MarkupToolbar extends StatelessWidget {
  final DrawingViewerState viewerState;
  final MarkupController controller;
  final VoidCallback onToggleLayers;
  final VoidCallback onFitToScreen;
  final VoidCallback? onAddText;
  final VoidCallback? onAddIssue;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onAddStamp;
  final VoidCallback? onCalibrate;
  final VoidCallback? onOpenCountTool;

  const MarkupToolbar({
    super.key,
    required this.viewerState,
    required this.controller,
    required this.onToggleLayers,
    required this.onFitToScreen,
    this.onAddText,
    this.onAddIssue,
    this.onAddPhoto,
    this.onAddStamp,
    this.onCalibrate,
    this.onOpenCountTool,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCalibrated = viewerState.calibration != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Switcher: Pan/Inspect vs Draw
            _buildModeToggle(context),
            const SizedBox(width: 8),
            _buildVerticalDivider(isDark),
            const SizedBox(width: 8),

            // Calibration Button & Status Pill
            _buildCalibrationButton(context, isCalibrated),
            const SizedBox(width: 6),

            // Tool Selectors (only if in drawing mode)
            if (viewerState.isDrawingMode) ...[
              _buildToolButton(MarkupType.pen),
              _buildToolButton(MarkupType.highlighter),
              _buildToolButton(MarkupType.line),
              _buildToolButton(MarkupType.arrow),
              _buildToolButton(MarkupType.rectangle),
              _buildToolButton(MarkupType.circle),
              _buildToolButton(MarkupType.revisionCloud),
              _buildActionToolButton(
                icon: Icons.text_fields_rounded,
                tooltip: 'Add Text Callout',
                onTap: onAddText,
              ),

              // Engineering Measurement Tools Suite Menu
              _buildMeasurementToolsMenu(context),

              // Component Count Tool Button
              _buildCountToolButton(context),

              _buildActionToolButton(
                icon: Icons.report_problem_rounded,
                tooltip: 'Add Punchlist Pin',
                color: Colors.redAccent,
                onTap: onAddIssue,
              ),
              _buildActionToolButton(
                icon: Icons.photo_camera_rounded,
                tooltip: 'Add Photo Pin',
                color: Colors.amberAccent,
                onTap: onAddPhoto,
              ),
              _buildActionToolButton(
                icon: Icons.verified_outlined,
                tooltip: 'Add Certification Stamp',
                color: AppColors.online,
                onTap: onAddStamp,
              ),
              _buildToolButton(MarkupType.eraser),

              const SizedBox(width: 8),
              _buildVerticalDivider(isDark),
              const SizedBox(width: 8),

              // Color Palette Picker Popover
              _buildColorPickerButton(context),
              const SizedBox(width: 6),

              // Stroke Width Selector Popover
              _buildStrokeWidthButton(context),
              const SizedBox(width: 6),

              // Opacity Selector
              _buildOpacityButton(context),
              const SizedBox(width: 8),
              _buildVerticalDivider(isDark),
              const SizedBox(width: 8),
            ],

            // Edit / Selection Tools (if item selected)
            if (viewerState.selectedMarkupId != null) ...[
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy Selected Markup',
                onPressed: controller.copySelectedMarkup,
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.redAccent),
                tooltip: 'Delete Selected Markup',
                onPressed: controller.deleteSelectedMarkup,
              ),
              const SizedBox(width: 8),
              _buildVerticalDivider(isDark),
              const SizedBox(width: 8),
            ],

            // Clipboard Paste
            if (viewerState.clipboard.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.paste_rounded, size: 18, color: AppColors.primaryLight),
                tooltip: 'Paste Markup',
                onPressed: controller.pasteMarkup,
              ),
            ],

            // Undo / Redo
            IconButton(
              icon: const Icon(Icons.undo_rounded, size: 18),
              tooltip: 'Undo',
              onPressed: viewerState.undoStack.isNotEmpty ? controller.undo : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo_rounded, size: 18),
              tooltip: 'Redo',
              onPressed: viewerState.redoStack.isNotEmpty ? controller.redo : null,
            ),

            const SizedBox(width: 8),
            _buildVerticalDivider(isDark),
            const SizedBox(width: 8),

            // Fit to Screen & Fullscreen
            IconButton(
              icon: const Icon(Icons.fit_screen_rounded, size: 18),
              tooltip: 'Fit Drawing to Screen',
              onPressed: onFitToScreen,
            ),
            IconButton(
              icon: Icon(
                viewerState.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                size: 20,
              ),
              tooltip: viewerState.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen Blueprint Mode',
              onPressed: controller.toggleFullscreen,
            ),

            // Stylus Palm Rejection Toggle
            IconButton(
              icon: Icon(
                Icons.draw_outlined,
                size: 18,
                color: viewerState.isStylusOnly ? AppColors.safetyOrange : null,
              ),
              tooltip: viewerState.isStylusOnly ? 'Stylus Only Mode (Active)' : 'Touch & Stylus Mode',
              onPressed: controller.toggleStylusMode,
            ),

            // Layers Panel Button
            IconButton(
              icon: const Icon(Icons.layers_rounded, size: 20, color: AppColors.safetyOrange),
              tooltip: 'Layer Management Panel',
              onPressed: onToggleLayers,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.pan_tool_outlined, size: 16),
          label: Text('Pan / Zoom', style: TextStyle(fontSize: 11)),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.draw_rounded, size: 16),
          label: Text('Markup', style: TextStyle(fontSize: 11)),
        ),
      ],
      selected: {viewerState.isDrawingMode},
      onSelectionChanged: (set) {
        controller.toggleDrawingMode();
      },
    );
  }

  Widget _buildCalibrationButton(BuildContext context, bool isCalibrated) {
    final isCalibrating = viewerState.isCalibrating;

    return Tooltip(
      message: isCalibrated
          ? 'Calibrated: 1 px = ${viewerState.calibration?.formattedScale(viewerState.calibration?.unit.symbol ?? 'mm')}\nTap to Re-calibrate'
          : 'Drawing scale not calibrated. Tap to calibrate scale.',
      child: InkWell(
        onTap: onCalibrate,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCalibrating
                ? AppColors.safetyOrange.withOpacity(0.2)
                : (isCalibrated ? AppColors.online.withOpacity(0.15) : Colors.grey.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCalibrating
                  ? AppColors.safetyOrange
                  : (isCalibrated ? AppColors.online : Colors.grey.withOpacity(0.4)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.straighten_rounded,
                size: 16,
                color: isCalibrating
                    ? AppColors.safetyOrange
                    : (isCalibrated ? AppColors.online : Colors.grey),
              ),
              const SizedBox(width: 4),
              Text(
                isCalibrating
                    ? 'Calibrating...'
                    : (isCalibrated
                        ? '${viewerState.calibration?.knownDistance.toStringAsFixed(0)} ${viewerState.calibration?.unit.symbol}'
                        : 'Calibrate'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isCalibrating
                      ? AppColors.safetyOrange
                      : (isCalibrated ? AppColors.online : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementToolsMenu(BuildContext context) {
    final isMeasurementMode = viewerState.isDrawingMode &&
        (viewerState.selectedTool == MarkupType.measurement || viewerState.activeMeasurementType != null);
    final activeType = viewerState.activeMeasurementType ?? MeasurementType.distance;

    return PopupMenuButton<MeasurementType>(
      tooltip: 'Engineering Measurement Tools',
      initialValue: activeType,
      offset: const Offset(0, 40),
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isMeasurementMode ? AppColors.safetyOrange.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activeType.icon,
              size: 18,
              color: isMeasurementMode ? AppColors.safetyOrange : null,
            ),
            const Icon(Icons.arrow_drop_down, size: 14),
          ],
        ),
      ),
      onSelected: (type) {
        controller.selectMeasurementType(type);
      },
      itemBuilder: (context) => MeasurementType.values.map((type) {
        return PopupMenuItem<MeasurementType>(
          value: type,
          child: Row(
            children: [
              Icon(type.icon, size: 18, color: AppColors.safetyOrange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type.displayName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      type.description,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (activeType == type && isMeasurementMode)
                const Icon(Icons.check, size: 16, color: AppColors.safetyOrange),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCountToolButton(BuildContext context) {
    final isCountActive = viewerState.isDrawingMode &&
        viewerState.activeMeasurementType == MeasurementType.count;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: const Icon(Icons.pin_drop_rounded, size: 18),
        color: isCountActive ? const Color(0xFF00E676) : null,
        tooltip: isCountActive
            ? 'Count Tool (${viewerState.activeCountLabel})'
            : 'Component Count Tool',
        style: isCountActive
            ? IconButton.styleFrom(backgroundColor: const Color(0xFF00E676).withOpacity(0.15))
            : null,
        onPressed: onOpenCountTool,
      ),
    );
  }

  Widget _buildToolButton(MarkupType tool) {
    final isSelected = viewerState.isDrawingMode &&
        viewerState.selectedTool == tool &&
        viewerState.activeMeasurementType == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(tool.icon, size: 18),
        color: isSelected ? AppColors.safetyOrange : null,
        tooltip: tool.displayName,
        style: isSelected
            ? IconButton.styleFrom(backgroundColor: AppColors.safetyOrange.withOpacity(0.15))
            : null,
        onPressed: () {
          controller.selectTool(tool);
        },
      ),
    );
  }

  Widget _buildActionToolButton({
    required IconData icon,
    required String tooltip,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildColorPickerButton(BuildContext context) {
    return PopupMenuButton<Color>(
      tooltip: 'Annotation Color',
      offset: const Offset(0, 40),
      icon: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: viewerState.activeColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: viewerState.activeColor.withOpacity(0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      onSelected: (color) => controller.setColor(color),
      itemBuilder: (context) {
        return DrawingColorPalette.engineeringPalette.map((c) {
          return PopupMenuItem<Color>(
            value: c.color,
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: c.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(c.name, style: const TextStyle(fontSize: 13)),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildStrokeWidthButton(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Stroke Thickness',
      offset: const Offset(0, 40),
      icon: const Icon(Icons.line_weight_rounded, size: 18),
      onSelected: (w) => controller.setStrokeWidth(w),
      itemBuilder: (context) {
        final widths = [1.5, 3.0, 5.0, 8.0, 12.0];
        return widths.map((w) {
          return PopupMenuItem<double>(
            value: w,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: w,
                  decoration: BoxDecoration(
                    color: viewerState.activeColor,
                    borderRadius: BorderRadius.circular(w / 2),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${w.toInt()} px', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildOpacityButton(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Markup Opacity',
      offset: const Offset(0, 40),
      icon: const Icon(Icons.opacity_rounded, size: 18),
      onSelected: (op) => controller.setOpacity(op),
      itemBuilder: (context) {
        final opacities = [1.0, 0.75, 0.5, 0.25];
        return opacities.map((op) {
          return PopupMenuItem<double>(
            value: op,
            child: Text('${(op * 100).toInt()}%', style: const TextStyle(fontSize: 13)),
          );
        }).toList();
      },
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
