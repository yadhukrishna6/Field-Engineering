import '../../domain/models/inspection.dart';
import '../../domain/models/inspection_item.dart';
import '../../domain/repositories/inspections_repository.dart';
import '../datasources/inspections_local_datasource.dart';

class InspectionsRepositoryImpl implements InspectionsRepository {
  final InspectionsLocalDataSource _localDataSource;

  InspectionsRepositoryImpl({required InspectionsLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<void> saveInspection(Inspection inspection) =>
      _localDataSource.insertInspection(inspection);

  @override
  Future<void> updateInspection(Inspection inspection) =>
      _localDataSource.updateInspection(inspection);

  @override
  Future<void> updateInspectionItem(InspectionItem item) =>
      _localDataSource.updateInspectionItem(item);

  @override
  Future<void> deleteInspection(String id) => _localDataSource.deleteInspection(id);

  @override
  Future<List<InspectionItem>> getInspectionItems(String inspectionId) =>
      _localDataSource.getInspectionItems(inspectionId);

  @override
  Future<Inspection?> getInspectionById(String id) =>
      _localDataSource.getInspectionById(id);

  @override
  Future<List<Inspection>> getInspectionsByProject(String projectId) =>
      _localDataSource.getInspectionsByProject(projectId);

  @override
  Future<List<Inspection>> getAllInspections() =>
      _localDataSource.getAllInspections();
}
