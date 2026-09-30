import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/offline/offline_sync_manager.dart';
import '../../../../core/offline/network_status_state.dart';
import '../controllers/dashboard_controller.dart';
import '../../../projects/presentation/controllers/projects_controller.dart';
import '../../../drawings/presentation/controllers/drawings_controller.dart';
import '../../../../shared/widgets/loading_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../drawings/presentation/widgets/drawing_import_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final syncState = ref.watch(offlineSyncProvider);

    return dashboardAsync.when(
      loading: () => const LoadingStateView(message: 'Loading field dashboard...'),
      error: (err, stack) => ErrorStateView(
        message: 'Failed to load dashboard: $err',
        onRetry: () => ref.invalidate(dashboardDataProvider),
      ),
      data: (data) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardDataProvider);
              await ref.read(projectsListNotifierProvider.notifier).loadProjects();
              await ref.read(allDrawingsNotifierProvider.notifier).loadDrawings();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline Desert Readiness Banner
                  _buildOfflineReadinessBanner(context, ref, syncState, data),
                  const SizedBox(height: 20),

                  // Top 4 KPI Metric Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'ACTIVE PROJECTS',
                          value: '${data.activeProjectsCount}',
                          subtitle: '${data.totalProjects} total registered',
                          icon: Icons.folder_special_rounded,
                          accentColor: AppColors.primaryLight,
                          onTap: () => context.go('/projects'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'OFFLINE DRAWINGS',
                          value: '${data.offlineDrawingsCount}',
                          subtitle: '${data.totalDrawings} total drawings',
                          icon: Icons.layers_rounded,
                          accentColor: AppColors.drawingPid,
                          onTap: () => context.go('/drawings'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'STORAGE USED',
                          value: data.storageUsage.formattedTotal,
                          subtitle: '${data.storageUsage.formattedPdfs} drawings cache',
                          icon: Icons.storage_rounded,
                          accentColor: AppColors.safetyOrange,
                          onTap: () => context.go('/offline-data'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'SYNC QUEUE',
                          value: '${syncState.pendingCount}',
                          subtitle: syncState.status.label,
                          icon: syncState.status.icon,
                          accentColor: syncState.status.color,
                          onTap: () => context.go('/offline-downloads'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Field Actions Strip
                  _buildQuickActionBar(context, ref),
                  const SizedBox(height: 24),

                  // Dual Pane Section: Active Projects (Left) & Recent Drawings (Right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Projects Summary (Flex 3)
                      Expanded(
                        flex: 3,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.assignment_turned_in_rounded, size: 20, color: AppColors.safetyOrange),
                                        SizedBox(width: 8),
                                        Text(
                                          'Active Project Packages',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                      label: const Text('View All'),
                                      onPressed: () => context.go('/projects'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (data.activeProjects.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(child: Text('No active projects found.')),
                                  )
                                else
                                  ...data.activeProjects.map((p) => _buildProjectTile(context, ref, p)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Recent Drawings Stream (Flex 2)
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.history_rounded, size: 20, color: AppColors.primaryLight),
                                        SizedBox(width: 8),
                                        Text(
                                          'Recent Drawings',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                      label: const Text('Browse'),
                                      onPressed: () => context.go('/drawings'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (data.recentDrawings.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(child: Text('No drawings loaded.')),
                                  )
                                else
                                  ...data.recentDrawings.map((d) => _buildRecentDrawingTile(context, d)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfflineReadinessBanner(
    BuildContext context,
    WidgetRef ref,
    OfflineSyncState syncState,
    DashboardData data,
  ) {
    final isDesertReady = data.offlineDrawingsCount > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDesertReady
              ? [const Color(0xFF0F392B), const Color(0xFF0A261C)]
              : [const Color(0xFF422006), const Color(0xFF291503)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDesertReady ? AppColors.online.withOpacity(0.4) : AppColors.offline.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDesertReady ? AppColors.online : AppColors.offline).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDesertReady ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: isDesertReady ? AppColors.online : AppColors.offline,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDesertReady
                      ? 'FIELD READY: ${data.offlineDrawingsCount} Drawings Downloaded Offline'
                      : 'OFFLINE WARNING: No drawings downloaded for field use',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDesertReady
                      ? 'Tablet is ready for offline operation in remote desert/offshore locations. SQLite database and PDF cache are synced.'
                      : 'Ensure all project drawing packages are pre-loaded to offline storage before departing base camp.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDesertReady ? AppColors.primary : AppColors.safetyOrange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download_for_offline_rounded, size: 18),
            label: const Text('Manage Downloads'),
            onPressed: () => context.go('/offline-downloads'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.darkTextMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBar(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.report_problem_rounded, color: Colors.redAccent),
            label: const Text('Field Issues / Punch'),
            onPressed: () => context.go('/issues'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.checklist_rounded, color: AppColors.safetyOrange),
            label: const Text('Field Inspections'),
            onPressed: () => context.go('/inspections'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.precision_manufacturing_rounded, color: Colors.blueAccent),
            label: const Text('Equipment Master'),
            onPressed: () => context.go('/equipment'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calculate_rounded, color: Colors.tealAccent),
            label: const Text('Calculators'),
            onPressed: () => context.go('/calculations'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.note_add_rounded, color: AppColors.primaryLight),
            label: const Text('Import PDF Drawing'),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const DrawingImportModal(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectTile(BuildContext context, WidgetRef ref, dynamic project) {
    final progressMap = ref.watch(projectsListNotifierProvider).downloadProgressMap;
    final isDownloading = progressMap.containsKey(project.id);
    final progress = progressMap[project.id] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          project.projectNumber,
                          style: const TextStyle(
                            color: AppColors.safetyOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: project.status.displayName,
                          color: project.status.badgeColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Client: ${project.client} • Location: ${project.location}',
                      style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${project.downloadedCount}/${project.drawingCount} Offline',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  if (isDownloading)
                    SizedBox(
                      width: 90,
                      child: LinearProgressIndicator(value: progress),
                    )
                  else if (!project.isFullyDownloaded)
                    InkWell(
                      onTap: () {
                        ref.read(projectsListNotifierProvider.notifier).downloadProjectOffline(project.id);
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.download_rounded, size: 14, color: AppColors.primaryLight),
                          SizedBox(width: 4),
                          Text(
                            'Pre-load',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: AppColors.online),
                        SizedBox(width: 4),
                        Text(
                          'Ready',
                          style: TextStyle(
                            color: AppColors.online,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDrawingTile(BuildContext context, dynamic drawing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.darkBorder.withOpacity(0.4)),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: drawing.drawingType.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(drawing.drawingType.icon, color: drawing.drawingType.color, size: 20),
        ),
        title: Text(
          drawing.drawingNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          '${drawing.title} • ${drawing.revision}',
          style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility_rounded, size: 18),
          tooltip: 'Open PDF',
          onPressed: () {
            context.go('/drawings/${drawing.id}/view');
          },
        ),
      ),
    );
  }
}
