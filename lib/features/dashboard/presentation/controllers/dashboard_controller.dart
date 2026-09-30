import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/models/project.dart';
import '../../../projects/domain/models/project_status.dart';
import '../../../drawings/domain/models/drawing.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/storage_models.dart';

class DashboardData {
  final int totalProjects;
  final int activeProjectsCount;
  final int totalDrawings;
  final int offlineDrawingsCount;
  final StorageUsage storageUsage;
  final List<Project> activeProjects;
  final List<Drawing> recentDrawings;

  const DashboardData({
    required this.totalProjects,
    required this.activeProjectsCount,
    required this.totalDrawings,
    required this.offlineDrawingsCount,
    required this.storageUsage,
    required this.activeProjects,
    required this.recentDrawings,
  });
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final projectsRepo = ref.watch(projectsRepositoryProvider);
  final drawingsRepo = ref.watch(drawingsRepositoryProvider);
  final storageManager = ref.watch(storageManagerProvider);
  final database = ref.watch(databaseProvider);

  final allProjects = await projectsRepo.getProjects();
  final activeProjects = allProjects.where((p) => p.status == ProjectStatus.active).toList();
  final allDrawings = await drawingsRepo.getAllDrawings();
  final offlineDrawings = allDrawings.where((d) => d.downloaded).toList();

  final dbBytes = await database.getDatabaseSizeInBytes();
  final storageUsage = await storageManager.calculateStorageUsage(dbBytes);

  return DashboardData(
    totalProjects: allProjects.length,
    activeProjectsCount: activeProjects.length,
    totalDrawings: allDrawings.length,
    offlineDrawingsCount: offlineDrawings.length,
    storageUsage: storageUsage,
    activeProjects: activeProjects.take(4).toList(),
    recentDrawings: allDrawings.take(6).toList(),
  );
});
