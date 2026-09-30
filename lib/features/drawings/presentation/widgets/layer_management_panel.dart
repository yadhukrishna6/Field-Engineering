import 'package:flutter/material.dart';
import '../../domain/models/markup.dart';
import '../controllers/markup_controller.dart';
import '../../../../core/theme/color_palette.dart';

class LayerManagementPanel extends StatelessWidget {
  final DrawingViewerState viewerState;
  final MarkupController controller;
  final VoidCallback? onClose;

  const LayerManagementPanel({
    super.key,
    required this.viewerState,
    required this.controller,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.layers_rounded, color: AppColors.safetyOrange, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Drawing Layers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Layer Items
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildLayerTile(
                  context,
                  layer: DrawingLayer.original,
                  title: 'Original Drawing (PDF)',
                  subtitle: 'Vector engineering base blueprint',
                  icon: Icons.picture_as_pdf_rounded,
                  count: null,
                  isLocked: true,
                ),
                _buildLayerTile(
                  context,
                  layer: DrawingLayer.markup,
                  title: 'Markups & Clouds',
                  subtitle: 'Sketches, redlines, text & revision clouds',
                  icon: Icons.draw_rounded,
                  count: viewerState.getLayerCount(DrawingLayer.markup),
                ),
                _buildLayerTile(
                  context,
                  layer: DrawingLayer.measurement,
                  title: 'Measurements & Dimensions',
                  subtitle: 'ASME piping dimension lines & scales',
                  icon: Icons.square_foot_rounded,
                  count: viewerState.getLayerCount(DrawingLayer.measurement),
                ),
                _buildLayerTile(
                  context,
                  layer: DrawingLayer.issue,
                  title: 'Punchlist Issues',
                  subtitle: 'Field punchlist location pins',
                  icon: Icons.warning_amber_rounded,
                  count: viewerState.getLayerCount(DrawingLayer.issue),
                  color: Colors.redAccent,
                ),
                _buildLayerTile(
                  context,
                  layer: DrawingLayer.photo,
                  title: 'Site Inspection Photos',
                  subtitle: 'Photo location markers & callouts',
                  icon: Icons.camera_alt_outlined,
                  count: viewerState.getLayerCount(DrawingLayer.photo),
                  color: Colors.amberAccent,
                ),
                _buildLayerTile(
                  context,
                  layer: DrawingLayer.inspection,
                  title: 'QA/QC Inspection Stamps',
                  subtitle: 'Field signoffs & approval stamps',
                  icon: Icons.approval_rounded,
                  count: viewerState.getLayerCount(DrawingLayer.inspection),
                  color: AppColors.online,
                ),
                _buildLayerTile(
                  context,
                  layer: DrawingLayer.previousRevision,
                  title: 'Previous Revision Overlay',
                  subtitle: 'Comparison against previous IFC revision',
                  icon: Icons.compare_rounded,
                  count: null,
                  color: Colors.purpleAccent,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Show All', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    for (final l in DrawingLayer.values) {
                      if (!viewerState.visibleLayers.contains(l)) {
                        controller.toggleLayer(l);
                      }
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.visibility_off_rounded, size: 16),
                  label: const Text('Hide Markups', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    for (final l in DrawingLayer.values) {
                      if (l != DrawingLayer.original && viewerState.visibleLayers.contains(l)) {
                        controller.toggleLayer(l);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerTile(
    BuildContext context, {
    required DrawingLayer layer,
    required String title,
    required String subtitle,
    required IconData icon,
    int? count,
    Color? color,
    bool isLocked = false,
  }) {
    final isVisible = viewerState.visibleLayers.contains(layer);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CheckboxListTile(
      value: isVisible,
      onChanged: isLocked
          ? null
          : (val) {
              controller.toggleLayer(layer);
            },
      activeColor: color ?? AppColors.safetyOrange,
      secondary: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryLight).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.primaryLight),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isVisible
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
          ),
          if (count != null && count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
