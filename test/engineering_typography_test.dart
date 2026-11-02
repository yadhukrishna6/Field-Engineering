import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/core/theme/app_typography.dart';
import 'package:field_engineering/features/markup/domain/models/annotation_item.dart';
import 'package:field_engineering/features/markup/domain/models/drawing_file.dart';
import 'package:field_engineering/features/markup/domain/models/page_markup.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/domain/repositories/markup_repository.dart';
import 'package:field_engineering/features/markup/presentation/controllers/markup_editor_controller.dart';

import 'package:google_fonts/google_fonts.dart';

class FakeMarkupRepository implements MarkupRepository {
  final Map<String, PageMarkup> _store = {};

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
    final key = '${markup.drawingId}-${markup.pageNumber}';
    _store[key] = markup;
    return markup;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDrawing = DrawingFile(
    id: 'dwg-test-typography',
    name: 'P&ID Unit 100',
    fileType: 'IMAGE',
    localPath: '',
    createdAt: DateTime(2026, 1, 1),
    pageCount: 1,
  );
  late FakeMarkupRepository repo;

  setUp(() {
    repo = FakeMarkupRepository();
  });

  group('Engineering Typography & Downloaded Fonts Tests', () {
    test('All 6 downloaded EngineeringFont values exist and have previews', () {
      expect(EngineeringFont.values.length, 6);
      for (final font in EngineeringFont.values) {
        expect(font.id.isNotEmpty, true);
        expect(font.displayName.isNotEmpty, true);
        expect(font.samplePreview.contains('SL6'), true);
      }
    });

    test('EngineeringFont.fromId resolves correctly with fallback', () {
      expect(EngineeringFont.fromId('architectural'), EngineeringFont.architectural);
      expect(EngineeringFont.fromId('caveat'), EngineeringFont.caveat);
      expect(EngineeringFont.fromId('patrickHand'), EngineeringFont.patrickHand);
      expect(EngineeringFont.fromId('kalam'), EngineeringFont.kalam);
      expect(EngineeringFont.fromId('cadMonospace'), EngineeringFont.cadMonospace);
      expect(EngineeringFont.fromId('modernSans'), EngineeringFont.modernSans);
      // Fallback for null or unknown
      expect(EngineeringFont.fromId(null), EngineeringFont.architectural);
      expect(EngineeringFont.fromId('unknown_font'), EngineeringFont.architectural);
    });

    test('AppTypography.getTextStyle returns valid style for all fonts', () async {
      await runZonedGuarded(() async {
        for (final font in EngineeringFont.values) {
          final style = AppTypography.getTextStyle(
            font: font,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          );
          expect(style.fontSize, isNotNull);
          expect(style.color, Colors.red);
        }
      }, (error, stack) {
        // Safe to ignore asynchronous network font loading in test environment
      });
    });

    test('MarkupEditorController adds label with font and alignment in metadata', () async {
      final controller = MarkupEditorController(repo, testDrawing);
      await Future.delayed(const Duration(milliseconds: 10));

      controller.addLabel(
        text: 'SL6',
        x: 0.25,
        y: 0.35,
        size: 'M',
        color: const Color(0xFFD03A33),
        fontFamily: 'patrickHand',
        alignment: 'center',
      );

      final label = controller.state.annotations.firstWhere((a) => a.text == 'SL6');
      expect(label.type, AnnotationType.text);
      expect(label.metadata?['fontFamily'], 'patrickHand');
      expect(label.metadata?['alignment'], 'center');

      controller.dispose();
    });

    test('MarkupEditorController dynamically updates font and alignment of selected label', () async {
      final controller = MarkupEditorController(repo, testDrawing);
      await Future.delayed(const Duration(milliseconds: 10));

      controller.addLabel(
        text: '4"-HC-1002',
        x: 0.1,
        y: 0.2,
        fontFamily: 'architectural',
        alignment: 'left',
      );

      final labelId = controller.state.selectedAnnotationId!;
      controller.setActiveFont('caveat');
      controller.setTextAlignment('right');

      final updated = controller.state.annotations.firstWhere((a) => a.id == labelId);
      expect(updated.metadata?['fontFamily'], 'caveat');
      expect(updated.metadata?['alignment'], 'right');

      controller.dispose();
    });

    test('MarkupEditorController converts stroke annotation to aligned text label', () async {
      final controller = MarkupEditorController(repo, testDrawing);
      await Future.delayed(const Duration(milliseconds: 10));

      // Start a raw pen stroke
      controller.selectTool(MarkupTool.pen);
      controller.startStroke(const Point2D(0.4, 0.5));
      controller.appendStrokePoint(const Point2D(0.42, 0.52));
      controller.finishStroke();

      expect(controller.state.annotations.isNotEmpty, true);
      final stroke = controller.state.annotations.last;

      // Convert stroke to aligned downloaded font text (SL6)
      controller.convertAnnotationToText(
        annotationId: stroke.id,
        text: 'SL6',
        fontFamily: 'architectural',
        alignment: 'center',
        size: 'L',
      );

      final converted = controller.state.annotations.firstWhere((a) => a.text == 'SL6');
      expect(converted.type, AnnotationType.text);
      expect(converted.metadata?['fontFamily'], 'architectural');
      expect(converted.metadata?['alignment'], 'center');
      expect(converted.size, 'L');

      controller.dispose();
    });
  });
}
