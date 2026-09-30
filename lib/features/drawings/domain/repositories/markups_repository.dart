import '../models/markup.dart';

abstract class MarkupsRepository {
  Future<List<Markup>> getMarkupsForDrawing(String drawingId, {int? pageNumber});
  Future<Markup> saveMarkup(Markup markup);
  Future<List<Markup>> saveMarkupsBatch(List<Markup> markups);
  Future<bool> deleteMarkup(String id);
  Future<bool> deleteMarkupsForDrawing(String drawingId, {int? pageNumber});
}
