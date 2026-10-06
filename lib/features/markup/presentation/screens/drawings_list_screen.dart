import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/drawings_list_controller.dart';
import '../widgets/upload_drawing_sheet.dart';

class DrawingsListScreen extends ConsumerWidget {
  const DrawingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drawingsListControllerProvider);
    final controller = ref.read(drawingsListControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.draw_rounded, color: AppColors.safetyOrange),
            SizedBox(width: 8),
            Text('Engineering Markups'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.loadDrawings(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.safetyOrange))
          : state.drawings.isEmpty
              ? _buildEmptyState(context, controller)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.drawings.length,
                  itemBuilder: (context, index) {
                    final drawing = state.drawings[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: drawing.isPdf
                                ? Colors.redAccent.withOpacity(0.15)
                                : Colors.cyanAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            drawing.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                            color: drawing.isPdf ? Colors.redAccent : Colors.cyanAccent,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          drawing.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: drawing.isPdf
                                        ? Colors.redAccent.withOpacity(0.2)
                                        : Colors.cyanAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    drawing.fileType,
                                    style: TextStyle(
                                      color: drawing.isPdf ? Colors.redAccent : Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${drawing.pageCount} ${drawing.pageCount == 1 ? "page" : "pages"}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => _confirmDelete(context, controller, drawing.id, drawing.name),
                        ),
                        onTap: () {
                          context.push('/markup/${drawing.id}', extra: drawing);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.safetyOrange,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Upload Drawing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          UploadDrawingSheet.show(
            context,
            onDrawingSelected: (path, name, fileType, pageCount) async {
              final newDrawing = await controller.addDrawing(
                name: name,
                fileType: fileType,
                localPath: path,
                pageCount: pageCount,
              );
              if (context.mounted) {
                context.push('/markup/${newDrawing.id}', extra: newDrawing);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DrawingsListController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.architecture_rounded, size: 64, color: AppColors.safetyOrange.withOpacity(0.6)),
            const SizedBox(height: 16),
            const Text(
              'No Drawings Uploaded',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a technical drawing or P&ID layout to start marking up in the field.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Drawing Now'),
              onPressed: () {
                UploadDrawingSheet.show(
                  context,
                  onDrawingSelected: (path, name, fileType, pageCount) async {
                    final newDrawing = await controller.addDrawing(
                      name: name,
                      fileType: fileType,
                      localPath: path,
                      pageCount: pageCount,
                    );
                    if (context.mounted) {
                      context.push('/markup/${newDrawing.id}', extra: newDrawing);
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DrawingsListController controller, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Drawing?'),
        content: Text('Are you sure you want to delete "$name" and all associated markups?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteDrawing(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
