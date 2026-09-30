import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/repositories/projects_repository.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/offline/offline_sync_manager.dart';

class ProjectsFilterState {
  final String searchQuery;
  final ProjectStatus? statusFilter;

  const ProjectsFilterState({
    this.searchQuery = '',
    this.statusFilter,
  });

  ProjectsFilterState copyWith({
    String? searchQuery,
    ProjectStatus? statusFilter,
    bool clearStatus = false,
  }) {
    return ProjectsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

final projectsFilterProvider = StateProvider<ProjectsFilterState>((ref) {
  return const ProjectsFilterState();
});

class ProjectsListState {
  final bool isLoading;
  final List<Project> projects;
  final String? errorMessage;
  final Map<String, double> downloadProgressMap; // projectId -> progress

  const ProjectsListState({
    this.isLoading = false,
    this.projects = const [],
    this.errorMessage,
    this.downloadProgressMap = const {},
  });

  ProjectsListState copyWith({
    bool? isLoading,
    List<Project>? projects,
    String? errorMessage,
    Map<String, double>? downloadProgressMap,
  }) {
    return ProjectsListState(
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      errorMessage: errorMessage,
      downloadProgressMap: downloadProgressMap ?? this.downloadProgressMap,
    );
  }
}

class ProjectsListNotifier extends StateNotifier<ProjectsListState> {
  final ProjectsRepository _repository;
  final Ref _ref;

  ProjectsListNotifier(this._repository, this._ref) : super(const ProjectsListState()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final filter = _ref.read(projectsFilterProvider);
      final projects = await _repository.getProjects(
        searchQuery: filter.searchQuery,
        statusFilter: filter.statusFilter,
      );
      state = state.copyWith(
        isLoading: false,
        projects: projects,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load projects: $e',
      );
    }
  }

  Future<Project?> createProject(Project project) async {
    try {
      final created = await _repository.createProject(project);
      _ref.read(offlineSyncProvider.notifier).enqueueChange(
        entityType: 'project',
        action: 'create',
        entityId: created.id,
        payload: created.toMap(),
      );
      await loadProjects();
      return created;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create project: $e');
      return null;
    }
  }

  Future<Project?> updateProject(Project project) async {
    try {
      final updated = await _repository.updateProject(project);
      _ref.read(offlineSyncProvider.notifier).enqueueChange(
        entityType: 'project',
        action: 'update',
        entityId: updated.id,
        payload: updated.toMap(),
      );
      await loadProjects();
      return updated;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update project: $e');
      return null;
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      final success = await _repository.deleteProject(id);
      if (success) {
        _ref.read(offlineSyncProvider.notifier).enqueueChange(
          entityType: 'project',
          action: 'delete',
          entityId: id,
        );
        await loadProjects();
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete project: $e');
      return false;
    }
  }

  Future<void> downloadProjectOffline(String projectId) async {
    final currentMap = Map<String, double>.from(state.downloadProgressMap);
    currentMap[projectId] = 0.05;
    state = state.copyWith(downloadProgressMap: currentMap);

    try {
      await _repository.downloadProjectPackage(
        projectId,
        onProgress: (progress) {
          final updatedMap = Map<String, double>.from(state.downloadProgressMap);
          updatedMap[projectId] = progress;
          state = state.copyWith(downloadProgressMap: updatedMap);
        },
      );

      final finalMap = Map<String, double>.from(state.downloadProgressMap);
      finalMap.remove(projectId);
      state = state.copyWith(downloadProgressMap: finalMap);

      await loadProjects();
    } catch (e) {
      final finalMap = Map<String, double>.from(state.downloadProgressMap);
      finalMap.remove(projectId);
      state = state.copyWith(
        downloadProgressMap: finalMap,
        errorMessage: 'Download failed: $e',
      );
    }
  }
}

final projectsListNotifierProvider = StateNotifierProvider<ProjectsListNotifier, ProjectsListState>((ref) {
  final repo = ref.watch(projectsRepositoryProvider);
  return ProjectsListNotifier(repo, ref);
});

final singleProjectProvider = FutureProvider.family<Project?, String>((ref, id) async {
  final repo = ref.watch(projectsRepositoryProvider);
  return repo.getProjectById(id);
});
