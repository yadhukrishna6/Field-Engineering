import '../models/inspection.dart';
import '../models/inspection_item.dart';

abstract class InspectionsRepository {
  Future<void> saveInspection(Inspection inspection);
  Future<void> updateInspection(Inspection inspection);
  Future<void> updateInspectionItem(InspectionItem item);
  Future<void> deleteInspection(String id);
  Future<List<InspectionItem>> getInspectionItems(String inspectionId);
  Future<Inspection?> getInspectionById(String id);
  Future<List<Inspection>> getInspectionsByProject(String projectId);
  Future<List<Inspection>> getAllInspections();
}
