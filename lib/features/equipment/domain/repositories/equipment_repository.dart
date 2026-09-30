import '../models/equipment_item.dart';

abstract class EquipmentRepository {
  Future<void> saveEquipment(EquipmentItem item);
  Future<void> updateEquipment(EquipmentItem item);
  Future<void> deleteEquipment(String id);
  Future<EquipmentItem?> getEquipmentById(String id);
  Future<EquipmentItem?> getEquipmentByTagNumber(String tagNumber);
  Future<List<EquipmentItem>> getEquipmentByProject(String projectId);
  Future<List<EquipmentItem>> getEquipmentByDrawing(String drawingId);
  Future<List<EquipmentItem>> getAllEquipment();
}
