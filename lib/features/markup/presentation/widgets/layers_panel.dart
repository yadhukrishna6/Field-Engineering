import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/markup_layer.dart';

class LayersPanel extends StatelessWidget {
  final Map<MarkupLayer, bool> layerVisibility;
  final ValueChanged<MarkupLayer> onToggleLayer;
  final VoidCallback onClose;
  final List<AnnotationItem>? conflictCopies;
  final ValueChanged<String>? onRestoreConflictCopy;

  // Phase D: Authors / User Layers
  final List<String> availableAuthors;
  final Set<String> visibleAuthorFilters;
  final ValueChanged<String>? onToggleAuthor;
  final VoidCallback? onShowAllAuthors;
  final VoidCallback? onShowOnlyMine;
  final String currentUser;
  final VoidCallback? onOpenRevisionCompare;
  final Map<String, int>? annotationCountsByAuthor;

  const LayersPanel({
    super.key,
    required this.layerVisibility,
    required this.onToggleLayer,
    required this.onClose,
    this.conflictCopies,
    this.onRestoreConflictCopy,
    this.availableAuthors = const ['Field Engineer'],
    this.visibleAuthorFilters = const {},
    this.onToggleAuthor,
    this.onShowAllAuthors,
    this.onShowOnlyMine,
    this.currentUser = 'Field Engineer',
    this.onOpenRevisionCompare,
    this.annotationCountsByAuthor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      width: 270,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.97),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outlineColor, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.layers_rounded, size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Layers & Review',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 8),

            // Revision Compare Action Button (Phase D)
            if (onOpenRevisionCompare != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: const Text(
                    'Compare Revisions (Overlay)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onOpenRevisionCompare,
                ),
              ),
              const Divider(height: 8),
            ],

            // Layer Checkboxes
            ...MarkupLayer.values.map((layer) {
              final isVisible = layerVisibility[layer] ?? true;
              return InkWell(
                onTap: () => onToggleLayer(layer),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isVisible,
                          onChanged: (_) => onToggleLayer(layer),
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          layer.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: isVisible ? textColor : textColor.withOpacity(0.4),
                            fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(
                        isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        size: 14,
                        color: isVisible ? primaryColor : textColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Divider(height: 10),

            // Phase D: Authors & User Layers Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AUTHOR LAYERS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: onShowAllAuthors,
                            child: Text(
                              'All',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                          Text(' | ', style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.3))),
                          InkWell(
                            onTap: onShowOnlyMine,
                            child: Text(
                              'Mine',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...availableAuthors.map((author) {
                    final isVisible = visibleAuthorFilters.isEmpty || visibleAuthorFilters.contains(author);
                    final isMe = author == currentUser;
                    final count = annotationCountsByAuthor?[author] ?? 0;

                    return InkWell(
                      onTap: () => onToggleAuthor?.call(author),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: isVisible,
                                onChanged: (_) => onToggleAuthor?.call(author),
                                activeColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: isMe ? primaryColor : Colors.blueGrey,
                              child: Text(
                                author.isNotEmpty ? author[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isMe ? '$author (Me)' : author,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                  color: isVisible ? textColor : textColor.withOpacity(0.4),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (count > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (isMe ? primaryColor : Colors.blueGrey).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isMe ? primaryColor : textColor),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const Divider(height: 10),

            // Phase B: Color Meaning Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COLOR MEANING LEGEND',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(const Color(0xFFD03A33), 'Revision / Delete / Replace', textColor),
                  _buildLegendItem(const Color(0xFF1E88E5), 'Client comment / Relocate / Verify', textColor),
                  _buildLegendItem(const Color(0xFF2E7D32), 'Approved / Dimension', textColor),
                  _buildLegendItem(const Color(0xFFE06A26), 'Add / Hold / Caution', textColor),
                  _buildLegendItem(const Color(0xFF111111), 'General annotation / Neutral', textColor),
                ],
              ),
            ),

            // Conflict Copies Section
            if (conflictCopies != null && conflictCopies!.isNotEmpty) ...[
              const Divider(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'CONFLICT COPIES (${conflictCopies!.length})',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...conflictCopies!.map((cc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${cc.type.code.toUpperCase()}: ${cc.text ?? "Stroke"}',
                                style: TextStyle(fontSize: 10, color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => onRestoreConflictCopy?.call(cc.id),
                              child: Text(
                                'Restore',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textColor.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
