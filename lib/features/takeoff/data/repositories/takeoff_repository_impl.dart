import '../../domain/models/takeoff_item.dart';
import '../../domain/repositories/takeoff_repository.dart';
import '../datasources/takeoff_local_datasource.dart';

class TakeoffRepositoryImpl implements TakeoffRepository {
  final TakeoffLocalDataSource localDataSource;

  TakeoffRepositoryImpl({required this.localDataSource});

  @override
  Future<List<TakeoffItem>> getItemsForProject(
    String projectId, {
    String? drawingId,
    TakeoffItemType? itemType,
    String? searchQuery,
  }) {
    return localDataSource.getItemsForProject(
      projectId,
      drawingId: drawingId,
      itemType: itemType,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<TakeoffItem>> getTakeoffItems({
    String? projectId,
    String? drawingId,
    TakeoffItemType? itemType,
    String? searchQuery,
  }) {
    return localDataSource.getItemsForProject(
      projectId,
      drawingId: drawingId,
      itemType: itemType,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<TakeoffItem> saveItem(TakeoffItem item) {
    return localDataSource.saveItem(item);
  }

  @override
  Future<TakeoffItem> saveTakeoffItem(TakeoffItem item) {
    return localDataSource.saveItem(item);
  }

  @override
  Future<List<TakeoffItem>> saveItemsBatch(List<TakeoffItem> items) {
    return localDataSource.saveItemsBatch(items);
  }

  @override
  Future<bool> deleteItem(String id) {
    return localDataSource.deleteItem(id);
  }

  @override
  Future<bool> deleteTakeoffItem(String id) {
    return localDataSource.deleteItem(id);
  }

  @override
  Future<bool> deleteItemsForDrawing(String drawingId) {
    return localDataSource.deleteItemsForDrawing(drawingId);
  }
}
