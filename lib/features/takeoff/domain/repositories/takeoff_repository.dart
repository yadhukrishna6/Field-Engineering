import '../models/takeoff_item.dart';

abstract class TakeoffRepository {
  Future<List<TakeoffItem>> getItemsForProject(
    String projectId, {
    String? drawingId,
    TakeoffItemType? itemType,
    String? searchQuery,
  });
  Future<List<TakeoffItem>> getTakeoffItems({
    String? projectId,
    String? drawingId,
    TakeoffItemType? itemType,
    String? searchQuery,
  });
  Future<TakeoffItem> saveItem(TakeoffItem item);
  Future<TakeoffItem> saveTakeoffItem(TakeoffItem item);
  Future<List<TakeoffItem>> saveItemsBatch(List<TakeoffItem> items);
  Future<bool> deleteItem(String id);
  Future<bool> deleteTakeoffItem(String id);
  Future<bool> deleteItemsForDrawing(String drawingId);
}
