import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../storage/offline_storage_manager.dart';
import '../../features/projects/data/datasources/projects_local_datasource.dart';
import '../../features/projects/data/repositories/projects_repository_impl.dart';
import '../../features/projects/domain/repositories/projects_repository.dart';
import '../../features/drawings/data/datasources/drawings_local_datasource.dart';
import '../../features/drawings/data/repositories/drawings_repository_impl.dart';
import '../../features/drawings/domain/repositories/drawings_repository.dart';
import '../../features/drawings/data/datasources/markups_local_datasource.dart';
import '../../features/drawings/data/repositories/markups_repository_impl.dart';
import '../../features/drawings/domain/repositories/markups_repository.dart';
import '../../features/drawings/data/datasources/measurements_local_datasource.dart';
import '../../features/drawings/data/repositories/measurements_repository_impl.dart';
import '../../features/drawings/domain/repositories/measurements_repository.dart';
import '../../features/takeoff/data/datasources/takeoff_local_datasource.dart';
import '../../features/takeoff/data/repositories/takeoff_repository_impl.dart';
import '../../features/takeoff/domain/repositories/takeoff_repository.dart';
import '../../features/calculations/data/datasources/saved_calculations_local_datasource.dart';
import '../../features/calculations/data/repositories/saved_calculations_repository_impl.dart';
import '../../features/calculations/domain/repositories/saved_calculations_repository.dart';

// Core Singletons
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final storageManagerProvider = Provider<OfflineStorageManager>((ref) {
  return OfflineStorageManager.instance;
});

// Data Sources
final projectsLocalDataSourceProvider = Provider<ProjectsLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectsLocalDataSource(appDatabase: db);
});

final drawingsLocalDataSourceProvider = Provider<DrawingsLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return DrawingsLocalDataSource(appDatabase: db);
});

final markupsLocalDataSourceProvider = Provider<MarkupsLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return MarkupsLocalDataSource(appDatabase: db);
});

final measurementsLocalDataSourceProvider = Provider<MeasurementsLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return MeasurementsLocalDataSource(appDatabase: db);
});

final takeoffLocalDataSourceProvider = Provider<TakeoffLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return TakeoffLocalDataSource(appDatabase: db);
});

final savedCalculationsLocalDataSourceProvider = Provider<SavedCalculationsLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return SavedCalculationsLocalDataSource(appDatabase: db);
});

// Repositories
final drawingsRepositoryProvider = Provider<DrawingsRepository>((ref) {
  final localDataSource = ref.watch(drawingsLocalDataSourceProvider);
  final storageManager = ref.watch(storageManagerProvider);
  return DrawingsRepositoryImpl(
    localDataSource: localDataSource,
    storageManager: storageManager,
  );
});

final markupsRepositoryProvider = Provider<MarkupsRepository>((ref) {
  final localDataSource = ref.watch(markupsLocalDataSourceProvider);
  return MarkupsRepositoryImpl(localDataSource: localDataSource);
});

final measurementsRepositoryProvider = Provider<MeasurementsRepository>((ref) {
  final localDataSource = ref.watch(measurementsLocalDataSourceProvider);
  return MeasurementsRepositoryImpl(localDataSource: localDataSource);
});

final takeoffRepositoryProvider = Provider<TakeoffRepository>((ref) {
  final localDataSource = ref.watch(takeoffLocalDataSourceProvider);
  return TakeoffRepositoryImpl(localDataSource: localDataSource);
});

final savedCalculationsRepositoryProvider = Provider<SavedCalculationsRepository>((ref) {
  final localDataSource = ref.watch(savedCalculationsLocalDataSourceProvider);
  return SavedCalculationsRepositoryImpl(localDataSource: localDataSource);
});

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  final localDataSource = ref.watch(projectsLocalDataSourceProvider);
  final drawingsRepo = ref.watch(drawingsRepositoryProvider);
  return ProjectsRepositoryImpl(
    localDataSource: localDataSource,
    drawingsRepository: drawingsRepo,
  );
});
