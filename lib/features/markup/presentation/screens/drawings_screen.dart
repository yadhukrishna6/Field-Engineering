import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/drawings_list_controller.dart';
import '../widgets/dashed_upload_card.dart';
import '../widgets/sync_status_chip.dart';
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: SyncStatusChip()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(drawingsListControllerProvider.notifier).loadDrawings(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Dashed Border Upload Card
            DashedUploadCard(
              onTap: () => UploadDrawingSheet.show(
                context,
                onDrawingSelected: (path, name, fileType, pageCount, job, dwg, rev, project, title, tokens, bytes) async {
                  final newDrawing = await ref.read(drawingsListControllerProvider.notifier).addDrawing(
                    name: name,
                    fileType: fileType,
                    pageCount: pageCount,
                    localPath: path,
                    fileBytes: bytes,
                    jobNumber: job,
                    drawingNumber: dwg,
                    revision: rev,
                    projectName: project,
                    title: title,
                    extractedTokens: tokens,
                  );
                  if (context.mounted) {
                    context.push('/drawings/${newDrawing.id}', extra: newDrawing);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Header Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.drawings.length} drawings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Drawings List
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.drawings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No drawings uploaded yet.\nTap upload to add a technical drawing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              )
            else
              ...state.drawings.map((drawing) {
                final dateStr = DateFormat('MMM d, yyyy').format(drawing.createdAt);
                final pageStr = '${drawing.pageCount} ${drawing.pageCount == 1 ? 'page' : 'pages'}';

                return Card(
                  elevation: 0,
                  color: surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: outlineColor),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/drawings/${drawing.id}', extra: drawing),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Thumbnail / File Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.lightPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              drawing.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                              color: AppColors.lightPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Metadata
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drawing.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$pageStr • $dateStr',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Type Tag (PDF / Image)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: chipColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              drawing.fileType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
