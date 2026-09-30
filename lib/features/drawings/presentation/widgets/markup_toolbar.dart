import 'package:flutter/material.dart';
import '../../domain/models/markup.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              _buildToolButton(MarkupType.measurement),
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

  Widget _buildToolButton(MarkupType tool) {
    final isSelected = viewerState.isDrawingMode && viewerState.selectedTool == tool;

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
      tooltip: 'Select Markup Color',
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: viewerState.currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      onSelected: (color) => controller.setColor(color),
      itemBuilder: (context) {
        return kEngineeringColors.map((color) {
          return PopupMenuItem(
            value: color,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _getColorName(color),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildStrokeWidthButton(BuildContext context) {
    final widths = [1.0, 2.0, 3.0, 5.0, 8.0, 12.0];

    return PopupMenuButton<double>(
      tooltip: 'Stroke Width',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: viewerState.strokeWidth.clamp(1.0, 8.0),
              color: viewerState.currentColor,
            ),
            const SizedBox(width: 6),
            Text(
              '${viewerState.strokeWidth.toInt()}pt',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      onSelected: (w) => controller.setStrokeWidth(w),
      itemBuilder: (context) {
        return widths.map((w) {
          return PopupMenuItem(
            value: w,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: w,
                  color: viewerState.currentColor,
                ),
                const SizedBox(width: 12),
                Text('${w.toInt()} pt', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildOpacityButton(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Opacity',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Text(
          '${(viewerState.opacity * 100).toInt()}%',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
      onSelected: (o) => controller.setOpacity(o),
      itemBuilder: (context) {
        return [0.25, 0.50, 0.75, 1.0].map((o) {
          return PopupMenuItem(
            value: o,
            child: Text('${(o * 100).toInt()}% Opacity', style: const TextStyle(fontSize: 12)),
          );
        }).toList();
      },
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }

  String _getColorName(Color c) {
    if (c == const Color(0xFFD32F2F)) return 'Safety Red';
    if (c == const Color(0xFF2E7D32)) return 'Field Green';
    if (c == const Color(0xFF1565C0)) return 'P&ID Blue';
    if (c == const Color(0xFFFBC02D)) return 'Warning Yellow';
    if (c == const Color(0xFF7B1FA2)) return 'Instrument Purple';
    if (c == const Color(0xFF212121)) return 'Carbon Black';
    if (c == const Color(0xFFFF6F00)) return 'Hazard Orange';
    if (c == const Color(0xFF00838F)) return 'Process Cyan';
    return 'Custom Color';
  }
}
