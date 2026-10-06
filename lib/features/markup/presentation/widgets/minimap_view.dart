import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/drawing_file.dart';

class MinimapView extends StatelessWidget {
  final TransformationController transformationController;
  final DrawingFile drawing;
  final VoidCallback onResetZoom;

  const MinimapView({
    super.key,
    required this.transformationController,
    required this.drawing,
    required this.onResetZoom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;

    const minimapWidth = 110.0;
    const minimapHeight = 78.0;

    return ValueListenableBuilder<Matrix4>(
      valueListenable: transformationController,
      builder: (context, matrix, _) {
        final scale = matrix.getMaxScaleOnAxis().clamp(0.5, 8.0);
        final translation = matrix.getTranslation();

        // Calculate viewport rect relative to minimap
        final vpWidth = (minimapWidth / scale).clamp(16.0, minimapWidth);
        final vpHeight = (minimapHeight / scale).clamp(12.0, minimapHeight);

        final normX = (-translation.x / (scale * 800)).clamp(0.0, 1.0 - (vpWidth / minimapWidth));
        final normY = (-translation.y / (scale * 600)).clamp(0.0, 1.0 - (vpHeight / minimapHeight));

        final rectLeft = normX * minimapWidth;
        final rectTop = normY * minimapHeight;

        return GestureDetector(
          onTap: onResetZoom,
          onPanUpdate: (details) {
            // Dragging minimap viewport to pan main canvas
            final deltaX = -details.delta.dx * scale * 8.0;
            final deltaY = -details.delta.dy * scale * 8.0;
            final newMatrix = matrix.clone()..translate(deltaX / scale, deltaY / scale);
            transformationController.value = newMatrix;
          },
          child: Container(
            width: minimapWidth,
            height: minimapHeight,
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: outlineColor, width: 1.0),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Stack(
              children: [
                // Drawing overview placeholder / blueprint outline
                Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 32,
                    color: outlineColor.withOpacity(0.6),
                  ),
                ),

                // Blue Viewport Rectangle
                Positioned(
                  left: rectLeft,
                  top: rectTop,
                  width: vpWidth,
                  height: vpHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF185FA5).withOpacity(0.25),
                      border: Border.all(color: const Color(0xFF185FA5), width: 1.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
