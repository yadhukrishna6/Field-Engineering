import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/markup/domain/models/annotation_item.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/domain/models/drawing_file.dart';
import 'package:field_engineering/features/markup/domain/models/page_markup.dart';
import 'package:field_engineering/features/markup/domain/utils/stroke_smoother.dart';
import 'package:field_engineering/features/markup/presentation/controllers/markup_editor_controller.dart';
import 'package:field_engineering/features/markup/domain/repositories/markup_repository.dart';

class MockMarkupRepository implements MarkupRepository {
  final Map<String, PageMarkup> markups = {};
  final List<DrawingFile> drawings = [];

  @override
  Future<List<DrawingFile>> getDrawings() async => drawings;

  @override
  Future<DrawingFile?> getDrawing(String id) async => drawings.where((d) => d.id == id).firstOrNull;

  @override
  Future<DrawingFile> saveDrawing(DrawingFile drawing) async {
    drawings.add(drawing);
    return drawing;
  }

  @override
  Future<void> deleteDrawing(String id) async {
    drawings.removeWhere((d) => d.id == id);
  }

  @override
  Future<PageMarkup> getPageMarkup(String drawingId, int pageNumber) async {
    return markups['$drawingId:$pageNumber'] ?? PageMarkup(drawingId: drawingId, pageNumber: pageNumber, strokes: const []);
  }

  @override
  Future<PageMarkup> savePageMarkup(PageMarkup markup) async {
    markups['${markup.drawingId}:${markup.pageNumber}'] = markup;
    return markup;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 - Coordinate Normalization (0.0 .. 1.0)', () {
    test('Correctly converts screen offset to normalized Point2D and back', () {
      const screenSize = Size(1000, 800);
      const screenPoint = Offset(250, 400);

      final normalized = Point2D.fromOffset(screenPoint, screenSize);
      expect(normalized.x, equals(0.25));
      expect(normalized.y, equals(0.50));

      final backToScreen = normalized.toOffset(screenSize);
      expect(backToScreen.dx, equals(250.0));
      expect(backToScreen.dy, equals(400.0));
    });

    test('Clamps coordinates outside boundary safely to 0.0 .. 1.0', () {
      const screenSize = Size(500, 500);
      final outOfBounds = Point2D.fromOffset(const Offset(-50, 600), screenSize);
      expect(outOfBounds.x, equals(0.0));
      expect(outOfBounds.y, equals(1.0));
    });
  });

  group('Phase 1 - Stroke Smoothing & RDP Decimation', () {
    test('Generates valid cubic Bezier path from normalized points', () {
      const size = Size(800, 600);
      final points = [
        const Point2D(0.1, 0.1),
        const Point2D(0.2, 0.2),
        const Point2D(0.3, 0.15),
        const Point2D(0.4, 0.3),
      ];

      final path = StrokeSmoother.createSmoothPath(points, size);
      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.left, closeTo(80.0, 5.0));
    });

    test('Ramer-Douglas-Peucker simplifies collinear points without losing fidelity', () {
      final collinearPoints = [
        const Point2D(0.0, 0.0),
        const Point2D(0.1, 0.1),
        const Point2D(0.2, 0.2),
        const Point2D(0.3, 0.3),
        const Point2D(0.4, 0.4),
        const Point2D(0.5, 0.5),
      ];

      final simplified = StrokeSmoother.simplifyRDP(collinearPoints, epsilon: 0.001);
      expect(simplified.length, equals(2));
      expect(simplified.first.x, equals(0.0));
      expect(simplified.last.x, equals(0.5));
    });
  });

  group('Phase 1 - State Controller & Undo/Redo Command Stack', () {
    late MockMarkupRepository repo;
    late DrawingFile testDrawing;
    late MarkupEditorController controller;

    setUp(() {
      repo = MockMarkupRepository();
      testDrawing = DrawingFile(
        id: 'dwg-101',
        name: 'Piping Isometric Rev 01',
        fileType: 'PDF',
        pageCount: 3,
        localPath: 'assets/sample_drawings/pid_drawing_sample.pdf',
        createdAt: DateTime.now(),
      );
      controller = MarkupEditorController(repo, testDrawing);
    });

    test('Inking a stroke updates active page strokes and enables Undo', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state.strokes.isEmpty, isTrue);
      expect(controller.state.canUndo, isFalse);

      controller.startStroke(const Point2D(0.1, 0.1));
      controller.appendStrokePoint(const Point2D(0.2, 0.2));
      controller.finishStroke();

      expect(controller.state.strokes.length, equals(1));
      expect(controller.state.canUndo, isTrue);
      expect(controller.state.canRedo, isFalse);
    });

    test('Undo removes unsnapped stroke and Redo restores it', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.startStroke(const Point2D(0.1, 0.1));
      controller.appendStrokePoint(const Point2D(0.2, 0.2));
      controller.finishStroke();

      expect(controller.state.strokes.length, equals(1));

      // Undo removes the unsnapped stroke
      controller.undo();
      expect(controller.state.strokes.isEmpty, isTrue);
      expect(controller.state.canRedo, isTrue);

      // Redo restores it
      controller.redo();
      expect(controller.state.strokes.length, equals(1));
    });

    test('Undo snap: snapped horizontal stroke reverts to raw freehand before deletion', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      // Draw horizontal line that triggers 0 deg snap
      controller.startStroke(const Point2D(0.1, 0.5));
      controller.appendStrokePoint(const Point2D(0.25, 0.502));
      controller.appendStrokePoint(const Point2D(0.4, 0.499));
      controller.finishStroke();

      expect(controller.state.strokes.length, equals(1));
      expect(controller.state.annotations.last.rawPoints, isNotNull);

      // First Undo: Restores raw hand-drawn stroke (Undo snap)
      controller.undo();
      expect(controller.state.strokes.length, equals(1));
      expect(controller.state.annotations.last.type, equals(AnnotationType.stroke));

      // Second Undo: Removes the stroke completely
      controller.undo();
      expect(controller.state.strokes.isEmpty, isTrue);
      expect(controller.state.canRedo, isTrue);
    });

    test('Switching pages loads page-specific markups', () async {
      // Add stroke to page 1
      controller.startStroke(const Point2D(0.1, 0.1));
      controller.finishStroke();
      await controller.saveNow();

      // Switch to page 2
      controller.setPage(2);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.currentPage, equals(2));
      expect(controller.state.strokes.isEmpty, isTrue);

      // Switch back to page 1
      controller.setPage(1);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.currentPage, equals(1));
      expect(controller.state.strokes.length, equals(1));
    });
  });
}
