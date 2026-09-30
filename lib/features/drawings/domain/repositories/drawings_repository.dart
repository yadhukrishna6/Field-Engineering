import '../models/drawing.dart';
import '../models/drawing_type.dart';

abstract class DrawingsRepository {
  Future<List<Drawing>> getDrawingsForProject(
    String projectId, {
    String? searchQuery,
    DrawingType? typeFilter,
    String? revisionFilter,
  });

  Future<List<Drawing>> getAllDrawings({
    String? searchQuery,
    DrawingType? typeFilter,
    bool? downloadedOnly,
  });

  Future<Drawing?> getDrawingById(String id);

  Future<Drawing> addDrawing(Drawing drawing);

  Future<Drawing> updateDrawing(Drawing drawing);

  Future<bool> deleteDrawing(String id);

  Future<Drawing> importPdfDrawing({
    required String projectId,
    required String sourceFilePath,
    required String drawingNumber,
    required String title,
    required DrawingType drawingType,
    required String revision,
  });

  Future<void> markDrawingDownloaded(String id, bool downloaded);

  Stream<List<Drawing>> watchDrawingsForProject(String projectId);
}
