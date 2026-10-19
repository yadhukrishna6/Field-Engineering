import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/markup/domain/models/drawing_file.dart';
import 'package:field_engineering/features/markup/domain/models/drawing_text_token.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/domain/utils/title_block_extractor.dart';
import 'package:field_engineering/features/markup/presentation/controllers/markup_editor_controller.dart';
import 'package:field_engineering/features/markup/data/repositories/markup_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PHASE C - Use What is Already on the Drawing', () {
    test('10. Title-Block Reading: extracts job, dwg, rev, project, title from text', () async {
      const samplePdfText = '''
        JOB NO: 4500-DESERT-EXP
        DRAWING NUMBER: ISO-3001-HC
        REVISION: REV C
        PROJECT: DESERT GATHERING CENTER 14
        TITLE: 10 INCH CRUDE OIL ISOMETRIC SPOOL LAYOUT
      ''';

      final result = await TitleBlockExtractor.extractTitleBlock(
        filePath: '',
        fileName: 'ISO-3001-HC.pdf',
        isPdf: true,
        bytes: samplePdfText.codeUnits as dynamic,
      );

      expect(result.jobNumber, contains('4500-DESERT-EXP'));
      expect(result.drawingNumber, contains('ISO-3001-HC'));
      expect(result.revision, contains('REV C'));
      expect(result.projectName, contains('DESERT GATHERING CENTER 14'));
      expect(result.title, contains('10 INCH CRUDE OIL ISOMETRIC SPOOL LAYOUT'));
      expect(result.tokens.isNotEmpty, isTrue);

      // Fault tolerance test: Corrupt / empty data never throws and returns safe fallbacks
      final fallback = await TitleBlockExtractor.extractTitleBlock(
        filePath: 'non_existent_path.pdf',
        fileName: 'PID-1002.pdf',
        isPdf: true,
      );

      expect(fallback.jobNumber.isNotEmpty, isTrue);
      expect(fallback.drawingNumber, contains('PID-1002'));
      expect(fallback.tokens.isNotEmpty, isTrue);
    });

    test('11. In-Drawing Text Search: finds tokens by substring and provides jump target', () {
      const tokens = [
        DrawingTextToken(text: '10"-HC-3001-A1', pageNumber: 1, x: 0.22, y: 0.32, isTag: true),
        DrawingTextToken(text: '6"-CW-102-B2', pageNumber: 1, x: 0.48, y: 0.45, isTag: true),
        DrawingTextToken(text: 'P-101A', pageNumber: 1, x: 0.18, y: 0.58, isTag: true),
        DrawingTextToken(text: 'V-204', pageNumber: 2, x: 0.65, y: 0.38, isTag: true),
      ];

      // Query line tag "3001"
      final match1 = tokens.where((t) => t.text.toLowerCase().contains('3001')).toList();
      expect(match1.length, 1);
      expect(match1.first.text, '10"-HC-3001-A1');
      expect(match1.first.isTag, isTrue);

      // Query pump "P-101"
      final match2 = tokens.where((t) => t.text.toLowerCase().contains('p-101')).toList();
      expect(match2.length, 1);
      expect(match2.first.text, 'P-101A');

      // Query valve "V-204" on page 2
      final match3 = tokens.where((t) => t.text.toLowerCase().contains('v-204')).toList();
      expect(match3.length, 1);
      expect(match3.first.pageNumber, 2);
    });

    test('12. Tap-to-Attach: attaches line tag when tap is within 24px, plain coordinates otherwise', () {
      final repo = MarkupRepositoryImpl();
      final drawing = DrawingFile(
        id: 'dwg-test-attach',
        name: 'ISO-4001.pdf',
        fileType: 'PDF',
        pageCount: 1,
        localPath: '/tmp/test.pdf',
        createdAt: DateTime.now(),
        extractedTokens: const [
          DrawingTextToken(text: '10"-HC-3001-A1', pageNumber: 1, x: 0.20, y: 0.30, width: 0.10, height: 0.04, isTag: true),
        ],
      );

      final controller = MarkupEditorController(repo, drawing);
      const canvasSize = Size(1000, 1000);

      // Token center is at x = 0.25 (250px), y = 0.32 (320px)
      // Tap 1: Close tap at x = 0.24 (240px), y = 0.31 (310px) -> distance = sqrt(10^2 + 10^2) = 14.14px <= 24px
      final attachedTag1 = controller.findAttachedTagAt(const Point2D(0.24, 0.31), canvasSize, thresholdPixels: 24.0);
      expect(attachedTag1, isNotNull);
      expect(attachedTag1!.text, '10"-HC-3001-A1');
      expect(attachedTag1.bbox, isNotNull);

      // Place quick note with attached tag
      controller.addQuickNote(
        text: 'VERIFY IN FIELD',
        changeType: 'verify',
        color: const Color(0xFF1E88E5),
        x: 0.24,
        y: 0.31,
        attachedTag: attachedTag1,
      );

      expect(controller.state.annotations.length, 1);
      final ann = controller.state.annotations.first;
      expect(ann.attachedTag, isNotNull);
      expect(ann.attachedTag!.text, '10"-HC-3001-A1');

      // Tap 2: Far tap at x = 0.80 (800px), y = 0.80 (800px) -> distance > 500px >> 24px
      final attachedTag2 = controller.findAttachedTagAt(const Point2D(0.80, 0.80), canvasSize, thresholdPixels: 24.0);
      expect(attachedTag2, isNull);
    });
  });
}
