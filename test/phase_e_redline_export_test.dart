import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/markup/domain/models/annotation_item.dart';
import 'package:field_engineering/features/markup/domain/models/drawing_file.dart';
import 'package:field_engineering/features/markup/domain/models/field_change_item.dart';
import 'package:field_engineering/features/markup/domain/models/markup_layer.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/domain/utils/change_list_csv_exporter.dart';
import 'package:field_engineering/features/markup/domain/utils/markup_pdf_exporter.dart';
import 'package:field_engineering/features/markup/data/repositories/markup_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PHASE E - Redline Export & Structured Hand-off', () {
    late DrawingFile testDrawing;
    late MarkupRepositoryImpl repo;
    late List<AnnotationItem> sampleAnnotations;

    setUp(() {
      repo = MarkupRepositoryImpl();
      testDrawing = DrawingFile(
        id: 'dwg-iso-3001',
        name: '10"-HC-3001-A1.pdf',
        fileType: 'PDF',
        pageCount: 1,
        localPath: '',
        createdAt: DateTime.now(),
        jobNumber: 'JOB-4500-DESERT',
        drawingNumber: 'ISO-3001-HC',
        revision: 'REV 1',
        projectName: 'DESERT PIPELINE EXPANSION',
        title: '10 INCH CRUDE OIL ISOMETRIC SPOOL',
        status: 'in_progress',
      );

      sampleAnnotations = [
        AnnotationItem(
          id: 'ann-del-1',
          type: AnnotationType.strikeOut,
          layer: MarkupLayer.markups,
          color: const Color(0xFFD03A33),
          strokeWidth: 3.0,
          points: const [Point2D(0.2, 0.3), Point2D(0.4, 0.3)],
          text: 'DELETE SPOOL 04',
          changeType: 'delete',
          attachedTag: const AttachedTag(text: '10"-HC-3001-A1'),
          author: 'Field Engineer',
          createdAt: DateTime(2026, 10, 7, 14, 30),
        ),
        AnnotationItem(
          id: 'ann-add-2',
          type: AnnotationType.text,
          layer: MarkupLayer.markups,
          color: const Color(0xFF08605B),
          strokeWidth: 2.0,
          points: const [Point2D(0.5, 0.45)],
          text: 'ADD 2" DRAIN BYPASS VALVE',
          changeType: 'add',
          attachedTag: const AttachedTag(text: 'V-204'),
          author: 'Field Engineer',
          createdAt: DateTime(2026, 10, 7, 14, 35),
        ),
        AnnotationItem(
          id: 'ann-photo-3',
          type: AnnotationType.photoPin,
          layer: MarkupLayer.photos,
          color: const Color(0xFF185FA5),
          strokeWidth: 2.0,
          points: const [Point2D(0.65, 0.6)],
          text: 'Flange Spool Weld Inspection',
          changeType: 'photo',
          photoIds: const ['data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='],
          gps: const GpsCoord(lat: 24.713600, lng: 46.675300),
          author: 'Lead Drafter',
          createdAt: DateTime(2026, 10, 7, 14, 40),
        ),
        AnnotationItem(
          id: 'ann-stamp-4',
          type: AnnotationType.stamp,
          layer: MarkupLayer.inspection,
          color: const Color(0xFF08605B),
          strokeWidth: 2.0,
          points: const [Point2D(0.75, 0.8)],
          text: 'APPROVED FOR CONSTRUCTION',
          changeType: 'stamp',
          author: 'Chief Inspector',
          createdAt: DateTime(2026, 10, 7, 14, 45),
        ),
      ];
    });

    test('17. Structured Change List: extracts items with sequential callouts, tags, authors, and GPS', () {
      final changes = FieldChangeItem.extractChanges(sampleAnnotations);

      expect(changes.length, 4);

      // Callout #1 (Delete)
      expect(changes[0].itemNumber, 1);
      expect(changes[0].changeType, 'DELETE');
      expect(changes[0].attachedTag, '10"-HC-3001-A1');
      expect(changes[0].description, 'DELETE SPOOL 04');
      expect(changes[0].author, 'Field Engineer');

      // Callout #2 (Add)
      expect(changes[1].itemNumber, 2);
      expect(changes[1].changeType, 'ADD');
      expect(changes[1].attachedTag, 'V-204');
      expect(changes[1].description, 'ADD 2" DRAIN BYPASS VALVE');

      // Callout #3 (Photo Pin with GPS)
      expect(changes[2].itemNumber, 3);
      expect(changes[2].changeType, 'PHOTO');
      expect(changes[2].gps?.lat, 24.713600);
      expect(changes[2].gps?.lng, 46.675300);

      // Callout #4 (Official Stamp)
      expect(changes[3].itemNumber, 4);
      expect(changes[3].changeType, 'STAMP');
      expect(changes[3].description, 'APPROVED FOR CONSTRUCTION');
    });

    test('18. Redline PDF Export: Generates vector PDF with title block footer and Appendix page', () async {
      // Save markups to repository for PDF export
      final pageMarkup = await repo.getPageMarkup(testDrawing.id, 1);
      final updatedMarkup = pageMarkup.copyWith(annotations: sampleAnnotations);
      await repo.savePageMarkup(updatedMarkup);

      final pdfBytes = await MarkupPdfExporter.exportFlattenedPdf(
        drawing: testDrawing,
        repository: repo,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
      // Starts with standard PDF magic header (%PDF-)
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), '%PDF');
    });

    test('19. CSV Export: Generates RFC-4180 CAD spreadsheet table with all metadata', () {
      final changes = FieldChangeItem.extractChanges(sampleAnnotations);
      final csv = ChangeListCsvExporter.generateCsv(
        drawing: testDrawing,
        changes: changes,
      );

      expect(csv.contains('Item_No,Change_Type,Drawing_No,Revision'), isTrue);
      expect(csv.contains('1,DELETE,ISO-3001-HC,REV 1,1,"10""-HC-3001-A1",DELETE SPOOL 04'), isTrue);
      expect(csv.contains('2,ADD,ISO-3001-HC,REV 1,1,V-204,"ADD 2"" DRAIN BYPASS VALVE"'), isTrue);
      expect(csv.contains('24.713600,46.675300'), isTrue);
    });

    test('20. Executive Markdown Summary: Generates formatted hand-off report for 1-tap clipboard sharing', () {
      final changes = FieldChangeItem.extractChanges(sampleAnnotations);
      final summary = ChangeListCsvExporter.generateSummaryMarkdown(
        drawing: testDrawing,
        changes: changes,
      );

      expect(summary.contains('# FIELD REDLINE & CHANGE SUMMARY'), isTrue);
      expect(summary.contains('**Drawing:** ISO-3001-HC'), isTrue);
      expect(summary.contains('| #1 | **DELETE** | `10"-HC-3001-A1` | DELETE SPOOL 04 |'), isTrue);
      expect(summary.contains('| #2 | **ADD** | `V-204` | ADD 2" DRAIN BYPASS VALVE |'), isTrue);
      expect(summary.contains('24.7136°, 46.6753°'), isTrue);
    });
  });
}
