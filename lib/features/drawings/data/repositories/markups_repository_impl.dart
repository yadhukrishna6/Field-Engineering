import '../../domain/models/markup.dart';
import '../../domain/repositories/markups_repository.dart';
import '../datasources/markups_local_datasource.dart';

class MarkupsRepositoryImpl implements MarkupsRepository {
  final MarkupsLocalDataSource localDataSource;

  MarkupsRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Markup>> getMarkupsForDrawing(String drawingId, {int? pageNumber}) {
    return localDataSource.getMarkupsForDrawing(drawingId, pageNumber: pageNumber);
  }

  @override
  Future<Markup> saveMarkup(Markup markup) {
    return localDataSource.insertOrUpdateMarkup(markup);
  }

  @override
  Future<List<Markup>> saveMarkupsBatch(List<Markup> markups) {
    return localDataSource.saveMarkupsBatch(markups);
  }

  @override
  Future<bool> deleteMarkup(String id) {
    return localDataSource.deleteMarkup(id);
  }

  @override
  Future<bool> deleteMarkupsForDrawing(String drawingId, {int? pageNumber}) {
    return localDataSource.deleteMarkupsForDrawing(drawingId, pageNumber: pageNumber);
  }
}
