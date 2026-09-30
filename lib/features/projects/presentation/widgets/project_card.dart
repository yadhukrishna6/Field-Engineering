import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../controllers/projects_controller.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/storage/storage_models.dart';
import 'project_form_dialog.dart';

class ProjectCard extends ConsumerWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressMap = ref.watch(projectsListNotifierProvider).downloadProgressMap;
    final isDownloading = progressMap.containsKey(project.id);
    final downloadProgress = progressMap[project.id] ?? 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Project Number & Status Badge & Overflow menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      project.projectNumber,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      StatusBadge(
                        label: project.status.displayName,
                        color: project.status.badgeColor,
                        icon: project.status.icon,
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (action) {
                          if (action == 'edit') {
                            showDialog(
                              context: context,
                              builder: (context) => ProjectFormDialog(existingProject: project),
                            );
                          } else if (action == 'delete') {
                            _confirmDelete(context, ref);
                          } else if (action == 'download') {
                            ref.read(projectsListNotifierProvider.notifier).downloadProjectOffline(project.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download_for_offline_rounded, size: 18, color: AppColors.primaryLight),
                                SizedBox(width: 8),
                                Text('Pre-load All Drawings Offline'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_note_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Project Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Delete Local Project', style: TextStyle(color: Colors.redAccent)),
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

              // Project Name
              Text(
                project.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Client & Location
              Row(
                children: [
                  const Icon(Icons.business_rounded, size: 14, color: AppColors.darkTextMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      project.client,
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.darkTextMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      project.location,
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Spacer(),
              const Divider(height: 20),

              // Bottom Offline Download Gauge & Drawing Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            project.isFullyDownloaded
                                ? Icons.offline_pin_rounded
                                : Icons.cloud_download_outlined,
                            size: 16,
                            color: project.isFullyDownloaded ? AppColors.online : AppColors.offline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${project.downloadedCount}/${project.drawingCount} Offline',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: project.isFullyDownloaded ? AppColors.online : AppColors.offline,
                            ),
                          ),
                        ],
                      ),
                      if (project.totalBytes > 0)
                        Text(
                          StorageUsage.formatBytes(project.totalBytes),
                          style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11),
                        ),
                    ],
                  ),
                  if (isDownloading)
                    SizedBox(
                      width: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(downloadProgress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(value: downloadProgress),
                        ],
                      ),
                    )
                  else if (!project.isFullyDownloaded && project.drawingCount > 0)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text('Download Bundle', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        ref.read(projectsListNotifierProvider.notifier).downloadProjectOffline(project.id);
                      },
                    )
                  else
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: onTap,
                      child: const Text('Open Project', style: TextStyle(fontSize: 12)),
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
          title: const Text('Delete Field Project?'),
          content: Text(
            'Are you sure you want to delete "${project.name}" and all associated local drawing files and cached data?',
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
                await ref.read(projectsListNotifierProvider.notifier).deleteProject(project.id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
