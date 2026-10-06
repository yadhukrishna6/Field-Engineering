import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';

class ShapesSelectionPopup extends StatelessWidget {
  final AnnotationType currentShape;
  final ValueChanged<AnnotationType> onSelectShape;

  const ShapesSelectionPopup({
    super.key,
    required this.currentShape,
    required this.onSelectShape,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final shapes = [
      {'type': AnnotationType.line, 'label': 'Line', 'icon': Icons.horizontal_rule_rounded},
      {'type': AnnotationType.arrow, 'label': 'Arrow', 'icon': Icons.arrow_forward_rounded},
      {'type': AnnotationType.rectangle, 'label': 'Rectangle', 'icon': Icons.crop_square_rounded},
      {'type': AnnotationType.cloud, 'label': 'Revision Cloud', 'icon': Icons.cloud_outlined},
      {'type': AnnotationType.circle, 'label': 'Circle / Ellipse', 'icon': Icons.circle_outlined},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: shapes.map((shape) {
          final type = shape['type'] as AnnotationType;
          final isSelected = currentShape == type;

          return InkWell(
            onTap: () {
              Navigator.pop(context);
              onSelectShape(type);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(shape['icon'] as IconData, size: 18, color: isSelected ? primaryColor : textColor),
                  const SizedBox(width: 10),
                  Text(
                    shape['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? primaryColor : textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
