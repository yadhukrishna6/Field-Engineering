import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/repositories/projects_repository.dart';
import '../datasources/projects_local_datasource.dart';
import '../../../drawings/domain/repositories/drawings_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/app_exceptions.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsLocalDataSource localDataSource;
  final DrawingsRepository drawingsRepository;
  final _projectsStreamController = StreamController<List<Project>>.broadcast();

  ProjectsRepositoryImpl({
    required this.localDataSource,
    required this.drawingsRepository,
  });

  void _notifyListeners() async {
    try {
      final projects = await localDataSource.getProjects();
      if (!_projectsStreamController.isClosed) {
        _projectsStreamController.add(projects);
      }
    } catch (e) {
      debugPrint('Error notifying projects stream: $e');
    }
  }

  @override
  Future<List<Project>> getProjects({
    String? searchQuery,
    ProjectStatus? statusFilter,
  }) async {
    try {
      return await localDataSource.getProjects(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
      );
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error getting projects: $e');
    }
  }

  @override
  Future<Project?> getProjectById(String id) async {
    try {
      return await localDataSource.getProjectById(id);
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error getting project by id: $e');
    }
  }

  @override
  Future<Project> createProject(Project project) async {
    try {
      final result = await localDataSource.insertProject(project);
      _notifyListeners();
      return result;
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error creating project: $e');
    }
  }

  @override
  Future<Project> updateProject(Project project) async {
    try {
      final updated = project.copyWith(updatedAt: DateTime.now());
      final result = await localDataSource.updateProject(updated);
      _notifyListeners();
      return result;
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error updating project: $e');
    }
  }

  @override
  Future<bool> deleteProject(String id) async {
    try {
      final success = await localDataSource.deleteProject(id);
      if (success) {
        _notifyListeners();
      }
      return success;
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error deleting project: $e');
    }
  }

  @override
  Future<void> downloadProjectPackage(
    String projectId, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final drawings = await drawingsRepository.getDrawingsForProject(projectId);
      if (drawings.isEmpty) {
        onProgress?.call(1.0);
        return;
      }

      int completed = 0;
      for (final drawing in drawings) {
        if (!drawing.downloaded) {
          // Simulate rapid file caching/download package preparation
          await Future.delayed(const Duration(milliseconds: 300));
          await drawingsRepository.markDrawingDownloaded(drawing.id, true);
        }
        completed++;
        onProgress?.call(completed / drawings.length);
      }
      _notifyListeners();
    } catch (e) {
      throw OfflineSyncFailure('Failed downloading project package: $e');
    }
  }

  @override
  Stream<List<Project>> watchProjects() {
    // Prime stream with initial data
    _notifyListeners();
    return _projectsStreamController.stream;
  }

  void dispose() {
    _projectsStreamController.close();
  }
}
