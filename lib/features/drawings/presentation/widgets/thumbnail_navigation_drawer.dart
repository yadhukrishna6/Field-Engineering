import 'package:flutter/material.dart';
import '../../domain/models/drawing.dart';
import '../controllers/markup_controller.dart';
import '../../../../core/theme/color_palette.dart';

class ThumbnailNavigationDrawer extends StatelessWidget {
  final Drawing drawing;
  final DrawingViewerState viewerState;
  final MarkupController controller;
  final VoidCallback? onClose;

  const ThumbnailNavigationDrawer({
    super.key,
    required this.drawing,
    required this.viewerState,
    required this.controller,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo_library_rounded, color: AppColors.safetyOrange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Drawing Sheets',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Sheets List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: drawing.pageCount,
            itemBuilder: (context, index) {
              final pageNum = index + 1;
              final isCurrent = pageNum == viewerState.currentPage;
              final pageMarkupCount = viewerState.markups.where((m) => m.pageNumber == pageNum).length;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? AppColors.safetyOrange : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Material(
                  color: isCurrent
                      ? (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      controller.setPage(pageNum);
                      if (onClose != null) onClose!();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Miniature Blueprint Thumbnail Box
                          Container(
                            width: 64,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131D2A) : const Color(0xFFE8EEF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.architecture_rounded,
                                    size: 24,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 4,
                                  child: Text(
                                    '#$pageNum',
                                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sheet $pageNum of ${drawing.pageCount}',
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pageNum == 1 ? 'Main P&ID / Header Diagram' : 'Continuation & Aux Loop',
                                  style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
                                ),
                                if (pageMarkupCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.edit_note_rounded, size: 12, color: AppColors.safetyOrange),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$pageMarkupCount markup(s)',
                                        style: const TextStyle(fontSize: 10, color: AppColors.safetyOrange, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isCurrent)
                            const Icon(Icons.check_circle_rounded, color: AppColors.safetyOrange, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
