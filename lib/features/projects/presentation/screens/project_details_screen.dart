import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../controllers/projects_controller.dart';
import '../widgets/project_form_dialog.dart';
import '../../../drawings/presentation/controllers/drawings_controller.dart';
import '../../../drawings/presentation/widgets/drawing_card.dart';
import '../../../drawings/presentation/widgets/drawing_import_modal.dart';
import '../../../drawings/domain/models/drawing_type.dart';
import '../../../../shared/widgets/loading_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/storage/storage_models.dart';
import '../../../../core/utils/formatters.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  String _drawingSearch = '';
  DrawingType? _selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(singleProjectProvider(widget.projectId));
    final drawingsState = ref.watch(projectDrawingsNotifierProvider(widget.projectId));
    final projectsListState = ref.watch(projectsListNotifierProvider);
    final isDownloading = projectsListState.downloadProgressMap.containsKey(widget.projectId);
    final downloadProgress = projectsListState.downloadProgressMap[widget.projectId] ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return projectAsync.when(
      loading: () => const Scaffold(
        body: LoadingStateView(message: 'Loading field project details...'),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: ErrorStateView(
          message: 'Failed to load project: $err',
          onRetry: () => ref.refresh(singleProjectProvider(widget.projectId)),
        ),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: const ErrorStateView(message: 'Project not found in local offline database.'),
          );
        }

        // Filter drawings locally for fast search in project
        final filteredDrawings = drawingsState.drawings.where((d) {
          final matchesSearch = _drawingSearch.isEmpty ||
              d.drawingNumber.toLowerCase().contains(_drawingSearch.toLowerCase()) ||
              d.title.toLowerCase().contains(_drawingSearch.toLowerCase());
          final matchesType = _selectedTypeFilter == null || d.drawingType == _selectedTypeFilter;
          return matchesSearch && matchesType;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/projects');
                }
              },
            ),
            title: Row(
              children: [
                Text(
                  project.projectNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.safetyOrange),
                ),
                const SizedBox(width: 8),
                Text(
                  project.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            actions: [
              StatusBadge(
                label: project.status.displayName,
                color: project.status.badgeColor,
                icon: project.status.icon,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded),
                tooltip: 'Edit Project Metadata',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProjectFormDialog(existingProject: project),
                  ).then((_) => ref.refresh(singleProjectProvider(widget.projectId)));
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Overview Banner & Action Controls
                _buildProjectOverviewCard(context, ref, project, isDownloading, downloadProgress),
                const SizedBox(height: 20),

                // Search, Filter & Import Drawings Bar
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppSearchField(
                        hintText: 'Search drawings in ${project.projectNumber}...',
                        onChanged: (val) => setState(() => _drawingSearch = val),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Type Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DrawingType?>(
                          value: _selectedTypeFilter,
                          hint: const Text('All Disciplines', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Disciplines', style: TextStyle(fontSize: 13)),
                            ),
                            ...DrawingType.values.map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Row(
                                    children: [
                                      Icon(t.icon, color: t.color, size: 16),
                                      const SizedBox(width: 8),
                                      Text(t.displayName, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                )),
                          ],
                          onChanged: (val) => setState(() => _selectedTypeFilter = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.safetyOrange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_to_photos_rounded, size: 18),
                      label: const Text('Add Drawing PDF'),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => DrawingImportModal(preselectedProjectId: project.id),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Drawings Grid
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (drawingsState.isLoading && drawingsState.drawings.isEmpty) {
                        return const LoadingStateView(message: 'Loading project drawings...');
                      }

                      if (filteredDrawings.isEmpty) {
                        return EmptyStateView(
                          icon: Icons.layers_clear_rounded,
                          title: 'No Drawings in Project',
                          message: drawingsState.drawings.isEmpty
                              ? 'This project package has no drawings imported yet. Import or generate blueprints for field inspection.'
                              : 'No drawings match your search query "$_drawingSearch".',
                          actionLabel: 'Import Drawing PDF',
                          onAction: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => DrawingImportModal(preselectedProjectId: project.id),
                            );
                          },
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;

                          return GridView.builder(
                            itemCount: filteredDrawings.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: 1.6,
                            ),
                            itemBuilder: (context, index) {
                              final drawing = filteredDrawings[index];
                              return DrawingCard(
                                drawing: drawing,
                                onTap: () => context.go('/drawings/${drawing.id}/view'),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectOverviewCard(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isDownloading,
    double downloadProgress,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.description.isNotEmpty
                          ? project.description
                          : 'No project scope description entered.',
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      children: [
                        _buildMetaItem(Icons.business_rounded, 'Client: ${project.client}'),
                        _buildMetaItem(Icons.location_on_outlined, 'Site: ${project.location}'),
                        _buildMetaItem(Icons.schedule_rounded, 'Updated: ${AppFormatters.formatDateTime(project.updatedAt)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Offline Download Action Area
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OFFLINE PACKAGE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted),
                          ),
                          Icon(
                            project.isFullyDownloaded ? Icons.offline_pin_rounded : Icons.cloud_download_outlined,
                            size: 16,
                            color: project.isFullyDownloaded ? AppColors.online : AppColors.offline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${project.downloadedCount}/${project.drawingCount} Drawings Cached',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Storage: ${StorageUsage.formatBytes(project.totalBytes)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                      ),
                      const SizedBox(height: 10),
                      if (isDownloading)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Downloading: ${(downloadProgress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.safetyOrange),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: downloadProgress),
                          ],
                        )
                      else if (!project.isFullyDownloaded && project.drawingCount > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.download_for_offline_rounded, size: 16),
                            label: const Text('Download All Offline', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              ref.read(projectsListNotifierProvider.notifier).downloadProjectOffline(project.id);
                            },
                          ),
                        )
                      else
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: AppColors.online),
                            SizedBox(width: 6),
                            Text(
                              '100% Desert Ready',
                              style: TextStyle(
                                color: AppColors.online,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.darkTextMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
      ],
    );
  }
}
