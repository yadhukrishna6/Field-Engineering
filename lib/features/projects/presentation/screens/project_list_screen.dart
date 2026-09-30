import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/projects_controller.dart';
import '../widgets/project_card.dart';
import '../widgets/project_form_dialog.dart';
import '../../domain/models/project_status.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/loading_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../core/theme/color_palette.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectsListNotifierProvider);
    final filter = ref.watch(projectsFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter and Action Bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppSearchField(
                    hintText: 'Search projects by name, number, client or location...',
                    onChanged: (query) {
                      ref.read(projectsFilterProvider.notifier).state = filter.copyWith(searchQuery: query);
                      ref.read(projectsListNotifierProvider.notifier).loadProjects();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Status Filter Segment
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusFilterChip(
                          ref: ref,
                          label: 'All Projects',
                          isSelected: filter.statusFilter == null,
                          onSelected: () {
                            ref.read(projectsFilterProvider.notifier).state = filter.copyWith(clearStatus: true);
                            ref.read(projectsListNotifierProvider.notifier).loadProjects();
                          },
                        ),
                        ...ProjectStatus.values.map((status) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _buildStatusFilterChip(
                              ref: ref,
                              label: status.displayName,
                              isSelected: filter.statusFilter == status,
                              icon: status.icon,
                              badgeColor: status.badgeColor,
                              onSelected: () {
                                ref.read(projectsFilterProvider.notifier).state = filter.copyWith(statusFilter: status);
                                ref.read(projectsListNotifierProvider.notifier).loadProjects();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Project'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ProjectFormDialog(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content Area
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading && state.projects.isEmpty) {
                    return const LoadingStateView(message: 'Loading project packages...');
                  }

                  if (state.errorMessage != null && state.projects.isEmpty) {
                    return ErrorStateView(
                      message: state.errorMessage!,
                      onRetry: () => ref.read(projectsListNotifierProvider.notifier).loadProjects(),
                    );
                  }

                  if (state.projects.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.folder_open_rounded,
                      title: 'No Projects Found',
                      message: filter.searchQuery.isNotEmpty
                          ? 'No projects match "${filter.searchQuery}". Try adjusting your search or filters.'
                          : 'No field engineering projects registered on this device yet.',
                      actionLabel: 'Create New Project',
                      onAction: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ProjectFormDialog(),
                        );
                      },
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive tablet grid calculation (2 to 3 columns on tablet landscape)
                      final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;

                      return GridView.builder(
                        itemCount: state.projects.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.45,
                        ),
                        itemBuilder: (context, index) {
                          final project = state.projects[index];
                          return ProjectCard(
                            project: project,
                            onTap: () {
                              context.go('/projects/${project.id}');
                            },
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
  }

  Widget _buildStatusFilterChip({
    required WidgetRef ref,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
    Color? badgeColor,
  }) {
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null && badgeColor != null) ...[
            Icon(icon, size: 14, color: isSelected ? Colors.white : badgeColor),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.darkTextSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }
}
