import '../models/drawing_file.dart';
import '../models/page_markup.dart';

abstract class MarkupRepository {
  Future<List<DrawingFile>> getDrawings();
  Future<DrawingFile?> getDrawing(String id);
  Future<DrawingFile> saveDrawing(DrawingFile drawing);
  Future<void> deleteDrawing(String id);
  Future<PageMarkup> getPageMarkup(String drawingId, int pageNumber);
  Future<PageMarkup> savePageMarkup(PageMarkup markup);
}
