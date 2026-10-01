import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/drawing.dart';
import '../../domain/models/drawing_type.dart';
import '../controllers/drawings_controller.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/storage/storage_models.dart';

class DrawingCard extends ConsumerWidget {
  final Drawing drawing;
  final VoidCallback? onTap;

  const DrawingCard({
    super.key,
    required this.drawing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allDrawingsState = ref.watch(allDrawingsNotifierProvider);
    final isToggling = allDrawingsState.downloadingDrawingIds.contains(drawing.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.go('/drawings/${drawing.id}/view'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Drawing Discipline Badge & Status / Menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: drawing.drawingType.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: drawing.drawingType.color.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          drawing.drawingType.icon,
                          size: 14,
                          color: drawing.drawingType.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          drawing.drawingType.code,
                          style: TextStyle(
                            color: drawing.drawingType.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          drawing.revision,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppColors.safetyOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onSelected: (action) {
                          if (action == 'view') {
                            context.go('/drawings/${drawing.id}/view');
                          } else if (action == 'toggle_download') {
                            ref
                                .read(allDrawingsNotifierProvider.notifier)
                                .toggleDownloadStatus(drawing.id, drawing.downloaded);
                          } else if (action == 'delete') {
                            _confirmDelete(context, ref);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_rounded, size: 18, color: AppColors.primaryLight),
                                SizedBox(width: 8),
                                Text('Open Blueprint / Drawing'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_download',
                            child: Row(
                              children: [
                                Icon(
                                  drawing.downloaded
                                      ? Icons.delete_sweep_rounded
                                      : Icons.download_rounded,
                                  size: 18,
                                  color: AppColors.safetyOrange,
                                ),
                                const SizedBox(width: 8),
                                Text(drawing.downloaded ? 'Remove Offline Cache' : 'Cache Offline'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Delete Drawing', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Drawing Number
              Text(
                drawing.drawingNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),

              // Drawing Title
              Text(
                drawing.title,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),
              const Divider(height: 16),

              // Footer: Offline Status, Page count, Size & Quick Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        drawing.downloaded
                            ? Icons.offline_pin_rounded
                            : Icons.cloud_queue_rounded,
                        size: 16,
                        color: drawing.downloaded ? AppColors.online : AppColors.offline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        drawing.downloaded ? 'OFFLINE' : 'ONLINE ONLY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: drawing.downloaded ? AppColors.online : AppColors.offline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${drawing.pageCount} pg • ${StorageUsage.formatBytes(drawing.fileSize)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                    ],
                  ),
                  if (isToggling)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      tooltip: 'Open Drawing',
                      color: AppColors.primaryLight,
                      onPressed: () => context.go('/drawings/${drawing.id}/view'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Engineering Drawing?'),
          content: Text(
            'Are you sure you want to delete drawing ${drawing.drawingNumber} ("${drawing.title}") from offline storage?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(allDrawingsNotifierProvider.notifier).deleteDrawing(drawing.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
