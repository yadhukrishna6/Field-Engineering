import '../../domain/models/equipment_item.dart';
import '../../domain/repositories/equipment_repository.dart';
import '../datasources/equipment_local_datasource.dart';

class EquipmentRepositoryImpl implements EquipmentRepository {
  final EquipmentLocalDataSource _localDataSource;

  EquipmentRepositoryImpl({required EquipmentLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<void> saveEquipment(EquipmentItem item) => _localDataSource.insertEquipment(item);

  @override
  Future<void> updateEquipment(EquipmentItem item) => _localDataSource.updateEquipment(item);

  @override
  Future<void> deleteEquipment(String id) => _localDataSource.deleteEquipment(id);

  @override
  Future<EquipmentItem?> getEquipmentById(String id) => _localDataSource.getEquipmentById(id);

  @override
  Future<EquipmentItem?> getEquipmentByTagNumber(String tagNumber) =>
      _localDataSource.getEquipmentByTagNumber(tagNumber);

  @override
  Future<List<EquipmentItem>> getEquipmentByProject(String projectId) =>
      _localDataSource.getEquipmentByProject(projectId);

  @override
  Future<List<EquipmentItem>> getEquipmentByDrawing(String drawingId) =>
      _localDataSource.getEquipmentByDrawing(drawingId);

  @override
  Future<List<EquipmentItem>> getAllEquipment() => _localDataSource.getAllEquipment();
}
