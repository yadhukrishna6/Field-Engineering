import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../projects/presentation/controllers/projects_controller.dart';
import '../../../projects/domain/models/project_status.dart';
import '../controllers/offline_controller.dart';
import '../../../../core/offline/offline_sync_manager.dart';
import '../../../../core/offline/network_status_state.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/loading_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_header_bar.dart';

class OfflineDownloadManagerScreen extends ConsumerWidget {
  const OfflineDownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsListNotifierProvider);
    final storageState = ref.watch(offlineStorageNotifierProvider);
    final syncState = ref.watch(offlineSyncProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalProjects = projectsState.projects.length;
    final fullyDownloadedProjects = projectsState.projects.where((p) => p.isFullyDownloaded).length;
    final totalDrawings = projectsState.projects.fold<int>(0, (sum, p) => sum + p.drawingCount);
    final downloadedDrawings = projectsState.projects.fold<int>(0, (sum, p) => sum + p.downloadedCount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const AppHeaderBar(
        title: 'Offline Download Manager',
        subtitle: 'Desert & Remote Field Pre-Caching',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Desert Preparation Hero Card
            _buildDeploymentHeroBanner(
              context,
              ref,
              syncState,
              totalProjects: totalProjects,
              readyProjects: fullyDownloadedProjects,
              totalDrawings: totalDrawings,
              downloadedDrawings: downloadedDrawings,
            ),
            const SizedBox(height: 24),

            // Storage Quota Bar & Quick Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sd_storage_rounded, color: AppColors.safetyOrange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Tablet Offline Storage Allocation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Text(
                        '${storageState.usage.formattedTotal} Cached Offline',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalDrawings > 0 ? (downloadedDrawings / totalDrawings) : 1.0,
                      minHeight: 10,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.safetyOrange),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PDF Blueprints: ${storageState.usage.formattedPdfs} • Database: ${storageState.usage.formattedDatabase}',
                        style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                      ),
                      Text(
                        '$downloadedDrawings of $totalDrawings drawings ready (${totalDrawings > 0 ? ((downloadedDrawings / totalDrawings) * 100).toInt() : 100}%)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Header & "Pre-load All" Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Drawing Packages',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'Select project packages to cache locally before heading into off-grid desert locations.',
                      style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.download_for_offline_rounded, size: 18),
                  label: const Text('Pre-load All Projects (Desert Deployment)'),
                  onPressed: () async {
                    for (final p in projectsState.projects) {
                      if (!p.isFullyDownloaded) {
                        await ref.read(projectsListNotifierProvider.notifier).downloadProjectOffline(p.id);
                      }
                    }
                    ref.read(offlineStorageNotifierProvider.notifier).refreshUsage();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Project Packages List
            if (projectsState.isLoading && projectsState.projects.isEmpty)
              const LoadingStateView(message: 'Loading package queue...')
            else if (projectsState.projects.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No project packages registered yet.'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projectsState.projects.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final project = projectsState.projects[index];
                  final isDownloading = projectsState.downloadProgressMap.containsKey(project.id);
                  final progress = projectsState.downloadProgressMap[project.id] ?? 0.0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (project.isFullyDownloaded ? AppColors.online : AppColors.offline).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            project.isFullyDownloaded ? Icons.offline_pin_rounded : Icons.cloud_download_rounded,
                            color: project.isFullyDownloaded ? AppColors.online : AppColors.offline,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    project.projectNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.safetyOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(label: project.status.displayName, color: project.status.badgeColor),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                project.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Client: ${project.client} • Location: ${project.location}',
                                style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Download Action or Progress
                        if (isDownloading)
                          SizedBox(
                            width: 160,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Downloading package: ${(progress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.safetyOrange),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(value: progress),
                              ],
                            ),
                          )
                        else if (!project.isFullyDownloaded)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text('Pre-load (${project.drawingCount - project.downloadedCount} remaining)'),
                            onPressed: () {
                              ref.read(projectsListNotifierProvider.notifier).downloadProjectOffline(project.id);
                            },
                          )
                        else
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.online.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.online),
                                    SizedBox(width: 6),
                                    Text(
                                      'Offline Ready',
                                      style: TextStyle(
                                        color: AppColors.online,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => context.go('/projects/${project.id}'),
                                child: const Text('View Package'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeploymentHeroBanner(
    BuildContext context,
    WidgetRef ref,
    OfflineSyncState syncState, {
    required int totalProjects,
    required int readyProjects,
    required int totalDrawings,
    required int downloadedDrawings,
  }) {
    final isReady = totalProjects > 0 && readyProjects == totalProjects;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReady
              ? [const Color(0xFF0F392B), const Color(0xFF072118)]
              : [const Color(0xFF381E08), const Color(0xFF1F0E02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady ? AppColors.online.withOpacity(0.5) : AppColors.safetyOrange.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isReady ? AppColors.online : AppColors.safetyOrange).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReady ? Icons.verified_user_rounded : Icons.cloud_download_outlined,
              color: isReady ? AppColors.online : AppColors.safetyOrange,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady
                      ? 'OFFLINE DESERT DEPLOYMENT STATUS: 100% READY'
                      : 'OFFLINE DESERT PREPARATION: $readyProjects / $totalProjects Packages Cached',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isReady
                      ? 'All project drawing packages and local SQLite catalogs are completely downloaded to this tablet. You can disconnect from WiFi/Cellular and operate in remote desert or offshore platforms without disruption.'
                      : 'You have $readyProjects fully cached projects and $downloadedDrawings downloaded drawings. Run "Pre-load All Projects" before leaving the base station.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Network state pill toggle
          Column(
            children: [
              Text(
                'TEST NETWORK STATE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: syncState.status.color,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: syncState.status.color),
                ),
                icon: Icon(
                  syncState.isForcedOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                  size: 16,
                  color: syncState.status.color,
                ),
                label: Text(syncState.isForcedOffline ? 'Forced Offline' : 'Online'),
                onPressed: () {
                  ref.read(offlineSyncProvider.notifier).toggleConnectionMode();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
