import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/markup_layer.dart';

class LayersPanel extends StatelessWidget {
  final Map<MarkupLayer, bool> layerVisibility;
  final ValueChanged<MarkupLayer> onToggleLayer;
  final VoidCallback onClose;

  const LayersPanel({
    super.key,
    required this.layerVisibility,
    required this.onToggleLayer,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 16, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Layers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: MarkupLayer.values.map((layer) {
                final isVisible = layerVisibility[layer] ?? true;
                return InkWell(
                  onTap: () => onToggleLayer(layer),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isVisible,
                          activeColor: primaryColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (_) => onToggleLayer(layer),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            layer.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isVisible ? textColor : textColor.withOpacity(0.5),
                              fontWeight: isVisible ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
