import '../models/project.dart';
import '../models/project_status.dart';

abstract class ProjectsRepository {
  Future<List<Project>> getProjects({
    String? searchQuery,
    ProjectStatus? statusFilter,
  });

  Future<Project?> getProjectById(String id);

  Future<Project> createProject(Project project);

  Future<Project> updateProject(Project project);

  Future<bool> deleteProject(String id);

  Future<void> downloadProjectPackage(String projectId, {void Function(double progress)? onProgress});

  Stream<List<Project>> watchProjects();
}
