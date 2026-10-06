import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/markup/domain/models/drawing_file.dart';
import 'package:field_engineering/features/markup/domain/models/page_markup.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/domain/models/stroke.dart';
import 'package:field_engineering/features/markup/domain/models/text_label.dart';
import 'package:field_engineering/features/markup/domain/repositories/markup_repository.dart';
import 'package:field_engineering/features/markup/domain/utils/markup_pdf_exporter.dart';
import 'package:field_engineering/features/markup/domain/utils/stroke_smoother.dart';
import 'package:field_engineering/features/markup/presentation/controllers/markup_editor_controller.dart';

class FakeMarkupRepository implements MarkupRepository {
  final Map<String, PageMarkup> _store = {};
  int saveCount = 0;

  @override
  Future<List<DrawingFile>> getDrawings() async => [];

  @override
  Future<DrawingFile?> getDrawing(String id) async => null;

  @override
  Future<DrawingFile> saveDrawing(DrawingFile file) async => file;

  @override
  Future<void> deleteDrawing(String id) async {}

  @override
  Future<PageMarkup> getPageMarkup(String drawingId, int pageNumber) async {
    final key = '$drawingId-$pageNumber';
    return _store[key] ?? PageMarkup(drawingId: drawingId, pageNumber: pageNumber, strokes: const [], labels: const []);
  }

  @override
  Future<PageMarkup> savePageMarkup(PageMarkup markup) async {
    saveCount++;
    final key = '${markup.drawingId}-${markup.pageNumber}';
    _store[key] = markup;
    return markup;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 - TextLabel and PageMarkup Models', () {
    test('TextLabel JSON serialization and S/M/L fontSize mappings', () {
      const labelS = TextLabel(
        id: 'lbl-1',
        text: 'Tie-in Point #4',
        x: 0.25,
        y: 0.50,
        size: 'S',
        color: Color(0xFFFF3B30),
      );

      expect(labelS.fontSize, equals(11.0));

      final labelM = labelS.copyWith(size: 'M');
      expect(labelM.fontSize, equals(14.0));

      final labelL = labelS.copyWith(size: 'L');
      expect(labelL.fontSize, equals(18.0));

      final json = labelS.toJson();
      final deserialized = TextLabel.fromJson(json);

      expect(deserialized.id, equals('lbl-1'));
      expect(deserialized.text, equals('Tie-in Point #4'));
      expect(deserialized.x, equals(0.25));
      expect(deserialized.y, equals(0.50));
      expect(deserialized.size, equals('S'));
    });

    test('PageMarkup payload JSON serialization preserves strokes and labels', () {
      const stroke = Stroke(
        points: [Point2D(0.1, 0.1), Point2D(0.2, 0.2)],
        color: Color(0xFF007AFF),
        strokeWidth: 4.0,
      );
      const label = TextLabel(
        id: 'lbl-10',
        text: '4" FLANGE REVISION',
        x: 0.3,
        y: 0.4,
        size: 'L',
        color: Color(0xFF34C759),
      );

      final markup = PageMarkup(
        drawingId: 'dwg-101',
        pageNumber: 2,
        strokes: [stroke],
        labels: [label],
        version: 3,
      );

      final payloadJson = markup.toPayloadJson();
      expect(payloadJson.contains('FLANGE REVISION'), isTrue);

      final fullJson = markup.toJson();
      final restored = PageMarkup.fromJson(fullJson);

      expect(restored.strokes.length, equals(1));
      expect(restored.labels.length, equals(1));
      expect(restored.labels.first.text, equals('4" FLANGE REVISION'));
    });
  });

  group('Phase 2 - Hit Testing (Whole Item Eraser and Selection)', () {
    test('isStrokeHit detects points close to line segment', () {
      const stroke = Stroke(
        points: [Point2D(0.1, 0.1), Point2D(0.5, 0.5)],
        color: Color(0xFFFF3B30),
        strokeWidth: 4.0,
      );

      // Hit exactly on line
      expect(StrokeSmoother.isStrokeHit(stroke, const Point2D(0.3, 0.3)), isTrue);

      // Hit very close to line within threshold
      expect(StrokeSmoother.isStrokeHit(stroke, const Point2D(0.31, 0.30), threshold: 0.025), isTrue);

      // Point far away
      expect(StrokeSmoother.isStrokeHit(stroke, const Point2D(0.9, 0.1), threshold: 0.025), isFalse);
    });

    test('isLabelHit detects point within label bounds', () {
      const label = TextLabel(
        id: 'lbl-1',
        text: 'ISO-VALVE-01',
        x: 0.2,
        y: 0.3,
        size: 'M',
      );

      // Point inside bounding box
      expect(StrokeSmoother.isLabelHit(label, const Point2D(0.22, 0.32)), isTrue);

      // Point outside bounding box
      expect(StrokeSmoother.isLabelHit(label, const Point2D(0.8, 0.8)), isFalse);
    });
  });

  group('Phase 2 - MarkupEditorController Interactive Features', () {
    late FakeMarkupRepository repo;
    late DrawingFile testDrawing;

    setUp(() {
      repo = FakeMarkupRepository();
      testDrawing = DrawingFile(
        id: 'test-dwg',
        name: 'Isometric PID 01.pdf',
        localPath: 'sample.pdf',
        pageCount: 3,
        fileType: 'PDF',
        createdAt: DateTime.now(),
      );
    });

    test('Add label and move label updates state correctly', () async {
      final controller = MarkupEditorController(repo, testDrawing);
      await Future.delayed(const Duration(milliseconds: 10));

      controller.selectTool(MarkupTool.text);
      controller.addLabel(
        text: 'PSV-2001 SET 150 PSI',
        x: 0.4,
        y: 0.6,
        size: 'M',
        color: const Color(0xFFFF9500),
      );

      expect(controller.state.labels.length, equals(1));
      expect(controller.state.labels.first.text, equals('PSV-2001 SET 150 PSI'));
      expect(controller.state.labels.first.x, equals(0.4));
      expect(controller.state.selectedLabelId, isNotNull);

      // Move label
      final labelId = controller.state.selectedLabelId!;
      controller.moveLabel(labelId, const Point2D(0.45, 0.65));
      expect(controller.state.labels.first.x, equals(0.45));
      expect(controller.state.labels.first.y, equals(0.65));

      controller.finishMoveLabel();
      expect(controller.state.canUndo, isTrue);

      // Delete selected label
      controller.deleteSelectedLabel();
      expect(controller.state.labels.isEmpty, isTrue);

      controller.dispose();
    });

    test('Whole stroke/label eraser removes hit item and pushes snapshot', () async {
      final controller = MarkupEditorController(repo, testDrawing);
      await Future.delayed(const Duration(milliseconds: 10));

      // Draw stroke
      controller.selectTool(MarkupTool.pen);
      controller.startStroke(const Point2D(0.1, 0.1));
      controller.appendStrokePoint(const Point2D(0.2, 0.2));
      controller.finishStroke();
      expect(controller.state.strokes.length, equals(1));

      // Add label
      controller.selectTool(MarkupTool.text);
      controller.addLabel(text: 'NOTE 1', x: 0.7, y: 0.7, size: 'S');
      expect(controller.state.labels.length, equals(1));

      // Switch to eraser and erase stroke
      controller.selectTool(MarkupTool.eraser);
      final erasedStroke = controller.eraseAt(const Point2D(0.15, 0.15));
      expect(erasedStroke, isTrue);
      expect(controller.state.strokes.isEmpty, isTrue);
      expect(controller.state.labels.length, equals(1));

      // Erase label
      final erasedLabel = controller.eraseAt(const Point2D(0.71, 0.71));
      expect(erasedLabel, isTrue);
      expect(controller.state.labels.isEmpty, isTrue);

      // Undo restores label, then stroke
      controller.undo();
      expect(controller.state.labels.length, equals(1));

      controller.undo();
      expect(controller.state.strokes.length, equals(1));

      controller.dispose();
    });
  });

  group('Phase 2 - Multi-Page Vector PDF Export Engine', () {
    test('MarkupPdfExporter generates valid PDF bytes with embedded font and markups', () async {
      final repo = FakeMarkupRepository();
      final drawing = DrawingFile(
        id: 'export-dwg',
        name: 'PID Unit 102 Piping.pdf',
        localPath: 'test.pdf',
        pageCount: 2,
        fileType: 'PDF',
        createdAt: DateTime.now(),
      );

      // Add markup on page 1
      await repo.savePageMarkup(
        PageMarkup(
          drawingId: drawing.id,
          pageNumber: 1,
          strokes: const [
            Stroke(
              points: [Point2D(0.1, 0.1), Point2D(0.4, 0.4)],
              color: Color(0xFFFF3B30),
              strokeWidth: 4.0,
            ),
          ],
          labels: const [
            TextLabel(
              id: 'l1',
              text: 'VERIFY SPOOL LENGTH',
              x: 0.5,
              y: 0.5,
              size: 'M',
            ),
          ],
        ),
      );

      final pdfBytes = await MarkupPdfExporter.exportFlattenedPdf(
        drawing: drawing,
        repository: repo,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF magic header %PDF-
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });
}
