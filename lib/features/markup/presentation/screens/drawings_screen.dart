import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/drawing_file.dart';
import '../controllers/drawings_list_controller.dart';
import '../widgets/dashed_upload_card.dart';
import '../widgets/upload_drawing_sheet.dart';

class DrawingsScreen extends ConsumerWidget {
  const DrawingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drawingsListControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final chipColor = isDark ? AppColors.darkChip : AppColors.lightChip;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawings'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashed-Border Upload Card
                  DashedUploadCard(
                    onTap: () => _openUploadSheet(context, ref),
                  ),
                  const SizedBox(height: 24),

                  // Drawings Count Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${state.drawings.length} ${state.drawings.length == 1 ? "drawing" : "drawings"}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // List of Drawing Cards
                  if (state.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.drawings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No drawings uploaded yet',
                          style: TextStyle(fontSize: 13, color: secondaryTextColor),
                        ),
                      ),
                    )
                  else
                    ...state.drawings.map((drawing) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDrawingRowCard(
                          context,
                          ref,
                          drawing,
                          surfaceColor,
                          outlineColor,
                          textColor,
                          secondaryTextColor,
                          chipColor,
                          isDark,
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingRowCard(
    BuildContext context,
    WidgetRef ref,
    DrawingFile drawing,
    Color surfaceColor,
    Color outlineColor,
    Color textColor,
    Color secondaryTextColor,
    Color chipColor,
    bool isDark,
  ) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(drawing.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/drawings/${drawing.id}', extra: drawing),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail / Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: drawing.isPdf
                        ? Colors.redAccent.withOpacity(0.12)
                        : Colors.blueAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    drawing.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: drawing.isPdf ? Colors.redAccent : Colors.blueAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drawing.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${drawing.pageCount} ${drawing.pageCount == 1 ? "page" : "pages"} • $formattedDate',
                            style: TextStyle(fontSize: 12, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Type Badge (PDF / Image)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    drawing.fileType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openUploadSheet(BuildContext context, WidgetRef ref) {
    UploadDrawingSheet.show(
      context,
      onDrawingSelected: (path, name, fileType, pageCount) async {
        final newDrawing = await ref.read(drawingsListControllerProvider.notifier).addDrawing(
              name: name,
              fileType: fileType,
              localPath: path,
              pageCount: pageCount,
            );
        if (context.mounted) {
          context.push('/drawings/${newDrawing.id}', extra: newDrawing);
        }
      },
    );
  }
}
