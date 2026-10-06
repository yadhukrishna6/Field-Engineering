import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/drawing_file.dart';
import '../controllers/drawings_list_controller.dart';
import '../widgets/upload_drawing_sheet.dart';

class DrawingsListScreen extends ConsumerWidget {
  const DrawingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drawingsListControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Drawings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(drawingsListControllerProvider.notifier).loadDrawings(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.safetyOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload Drawing', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openUploadSheet(context, ref),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.safetyOrange))
          : state.drawings.isEmpty
              ? _buildEmptyState(context, ref, isDark)
              : _buildDrawingsGrid(context, ref, state.drawings, isDark),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: const Icon(
                Icons.architecture_rounded,
                size: 72,
                color: AppColors.safetyOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Upload your first drawing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import PDF blueprints, P&IDs, or isometric images to begin annotating and marking up.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Upload Drawing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () => _openUploadSheet(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingsGrid(BuildContext context, WidgetRef ref, List<DrawingFile> drawings, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // Responsive columns: 1 column on phone, 2 on tablet, 3-4 on wide desktop
        int crossAxisCount = 1;
        if (screenWidth >= 1200) {
          crossAxisCount = 4;
        } else if (screenWidth >= 800) {
          crossAxisCount = 3;
        } else if (screenWidth >= 550) {
          crossAxisCount = 2;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: crossAxisCount == 1 ? 2.6 : 1.15,
              ),
              itemCount: drawings.length,
              itemBuilder: (context, index) {
                final drawing = drawings[index];
                return _buildDrawingCard(context, ref, drawing, isDark);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawingCard(BuildContext context, WidgetRef ref, DrawingFile drawing, bool isDark) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(drawing.createdAt);

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () {
          context.push('/drawings/${drawing.id}', extra: drawing);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Thumbnail / Icon & Type Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: drawing.isPdf
                          ? Colors.redAccent.withOpacity(0.12)
                          : Colors.blueAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      drawing.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: drawing.isPdf ? Colors.redAccent : Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drawing.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                drawing.fileType.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.safetyOrange),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (drawing.isPdf)
                              Text(
                                '${drawing.pageCount} ${drawing.pageCount == 1 ? "page" : "pages"}',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade500),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _confirmDelete(context, ref, drawing);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Bottom row: Date & Open Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Markup',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.safetyOrange),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.safetyOrange),
                    ],
                  ),
                ],
              ),
            ],
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

  void _confirmDelete(BuildContext context, WidgetRef ref, DrawingFile drawing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Drawing'),
        content: Text('Are you sure you want to delete "${drawing.name}" and all its annotations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(drawingsListControllerProvider.notifier).deleteDrawing(drawing.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
