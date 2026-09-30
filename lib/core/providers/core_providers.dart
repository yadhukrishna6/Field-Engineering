import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../storage/offline_storage_manager.dart';
import '../services/field_gps_service.dart';
import '../services/voice_recording_service.dart';
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
import '../../features/issues/data/datasources/issues_local_datasource.dart';
import '../../features/issues/data/repositories/issues_repository_impl.dart';
import '../../features/issues/domain/repositories/issues_repository.dart';
import '../../features/photos/data/datasources/photos_local_datasource.dart';
import '../../features/photos/data/repositories/photos_repository_impl.dart';
import '../../features/photos/domain/repositories/photos_repository.dart';
import '../../features/voice_notes/data/datasources/voice_notes_local_datasource.dart';
import '../../features/voice_notes/data/repositories/voice_notes_repository_impl.dart';
import '../../features/voice_notes/domain/repositories/voice_notes_repository.dart';
import '../../features/inspections/data/datasources/inspections_local_datasource.dart';
import '../../features/inspections/data/repositories/inspections_repository_impl.dart';
import '../../features/inspections/domain/repositories/inspections_repository.dart';
import '../../features/equipment/data/datasources/equipment_local_datasource.dart';
import '../../features/equipment/data/repositories/equipment_repository_impl.dart';
import '../../features/equipment/domain/repositories/equipment_repository.dart';

// Core Singletons
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final storageManagerProvider = Provider<OfflineStorageManager>((ref) {
  return OfflineStorageManager.instance;
});

final gpsServiceProvider = Provider<FieldGpsService>((ref) {
  return FieldGpsService.instance;
});

final voiceRecordingServiceProvider = Provider<VoiceRecordingService>((ref) {
  return VoiceRecordingService.instance;
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

final issuesLocalDataSourceProvider = Provider<IssuesLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return IssuesLocalDataSource(appDatabase: db);
});

final photosLocalDataSourceProvider = Provider<PhotosLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return PhotosLocalDataSource(appDatabase: db);
});

final voiceNotesLocalDataSourceProvider = Provider<VoiceNotesLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return VoiceNotesLocalDataSource(appDatabase: db);
});

final inspectionsLocalDataSourceProvider = Provider<InspectionsLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return InspectionsLocalDataSource(appDatabase: db);
});

final equipmentLocalDataSourceProvider = Provider<EquipmentLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return EquipmentLocalDataSource(appDatabase: db);
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

final issuesRepositoryProvider = Provider<IssuesRepository>((ref) {
  final localDataSource = ref.watch(issuesLocalDataSourceProvider);
  return IssuesRepositoryImpl(localDataSource: localDataSource);
});

final photosRepositoryProvider = Provider<PhotosRepository>((ref) {
  final localDataSource = ref.watch(photosLocalDataSourceProvider);
  return PhotosRepositoryImpl(localDataSource: localDataSource);
});

final voiceNotesRepositoryProvider = Provider<VoiceNotesRepository>((ref) {
  final localDataSource = ref.watch(voiceNotesLocalDataSourceProvider);
  return VoiceNotesRepositoryImpl(localDataSource: localDataSource);
});

final inspectionsRepositoryProvider = Provider<InspectionsRepository>((ref) {
  final localDataSource = ref.watch(inspectionsLocalDataSourceProvider);
  return InspectionsRepositoryImpl(localDataSource: localDataSource);
});

final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  final localDataSource = ref.watch(equipmentLocalDataSourceProvider);
  return EquipmentRepositoryImpl(localDataSource: localDataSource);
});
