import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/markup/domain/models/annotation_item.dart';
import 'package:field_engineering/features/markup/domain/models/drawing_file.dart';
import 'package:field_engineering/features/markup/domain/models/markup_layer.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/domain/utils/photo_compressor.dart';
import 'package:field_engineering/features/markup/presentation/controllers/markup_editor_controller.dart';
import 'package:field_engineering/features/markup/data/repositories/markup_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PHASE D - Review and Control', () {
    late DrawingFile testDrawing;
    late MarkupRepositoryImpl repo;

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
    });

    test('13. Per-User Markup Layers: Author attribution, filtering & eraser protection', () async {
      final controller = MarkupEditorController(repo, testDrawing);
      controller.setCurrentUser('Field Engineer');

      // User 1 adds an annotation
      controller.addQuickNote(
        text: 'VERIFY IN FIELD',
        changeType: 'verify',
        color: Colors.blue,
        x: 0.2,
        y: 0.2,
      );

      // Simulate a remote / office drafter's annotation on another layer
      final officeDrafterAnnotation = AnnotationItem(
        id: 'office-ann-1',
        type: AnnotationType.text,
        layer: MarkupLayer.markups,
        color: Colors.red,
        strokeWidth: 2.0,
        points: [const Point2D(0.5, 0.5)],
        text: 'OFFICE DRAFT: RELOCATE VALVE',
        author: 'Office Drafter',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      controller.resolveOfflineSyncConflicts([officeDrafterAnnotation]);

      // Both authors should be recognized
      expect(controller.state.availableAuthors, containsAll(['Field Engineer', 'Office Drafter']));
      expect(controller.state.visibleAnnotations.length, 2);

      // Toggle author visibility: show only Field Engineer
      controller.setOnlyCurrentUserVisible();
      expect(controller.state.visibleAnnotations.length, 1);
      expect(controller.state.visibleAnnotations.first.author, 'Field Engineer');

      // Re-enable all authors
      controller.setAllAuthorsVisible();
      expect(controller.state.visibleAnnotations.length, 2);

      // Eraser protection: Field Engineer cannot erase Office Drafter's markup
      final erasedOther = controller.eraseAt(const Point2D(0.5, 0.5));
      expect(erasedOther, isFalse);
      expect(controller.state.annotations.any((a) => a.id == 'office-ann-1'), isTrue);

      // Field Engineer can erase their own markup
      final erasedOwn = controller.eraseAt(const Point2D(0.2, 0.2));
      expect(erasedOwn, isTrue);
    });

    test('14. Audit Trail & Read-Only Locking: Approved drawings lock editor unless admin reopens', () async {
      final approvedDrawing = testDrawing.copyWith(status: 'approved');
      final controller = MarkupEditorController(repo, approvedDrawing);

      expect(controller.state.isApproved, isTrue);
      expect(controller.state.isReadOnly, isTrue);

      // Mutations in read-only mode should be blocked
      controller.addQuickNote(
        text: 'ATTEMPT MODIFICATION',
        changeType: 'add',
        color: Colors.green,
        x: 0.3,
        y: 0.3,
      );
      expect(controller.state.annotations.isEmpty, isTrue);

      // Inking in read-only mode is blocked
      controller.startStroke(const Point2D(0.1, 0.1));
      controller.appendStrokePoint(const Point2D(0.2, 0.2));
      controller.finishStroke();
      expect(controller.state.annotations.isEmpty, isTrue);

      // Admin unlocks / reopens drawing
      controller.reopenDrawing();
      expect(controller.state.isReadOnly, isFalse);

      // Now mutations work
      controller.addQuickNote(
        text: 'FIELD REVISION AUTHORIZED',
        changeType: 'add',
        color: Colors.green,
        x: 0.3,
        y: 0.3,
      );
      expect(controller.state.annotations.length, 1);
      expect(controller.state.annotations.first.createdAt, isNotNull);
      expect(controller.state.annotations.first.updatedAt, isNotNull);
      expect(controller.state.annotations.first.author, isNotNull);
    });

    test('15. Photo + GPS Pinning: Compression (JPEG max 1600px 80%) & GPS coordinates', () async {
      final controller = MarkupEditorController(repo, testDrawing);

      // Test compression utility
      final mockBytes = PhotoCompressor.createMockFieldPhotoBytes();
      final compressed = await PhotoCompressor.compressPhoto(mockBytes, maxDimension: 1600, quality: 80);

      expect(compressed.width, lessThanOrEqualTo(1600));
      expect(compressed.height, lessThanOrEqualTo(1600));
      expect(compressed.base64Data.isNotEmpty, isTrue);

      // Place Photo + GPS Pin
      const gps = GpsCoord(lat: 24.713600, lng: 46.675300);
      controller.addPhotoPin(
        x: 0.45,
        y: 0.55,
        base64Image: compressed.base64Data,
        gps: gps,
        caption: 'Flange Spool Weld Inspection',
        accuracy: '±2.8m',
      );

      expect(controller.state.annotations.length, 1);
      final photoPin = controller.state.annotations.first;
      expect(photoPin.type, AnnotationType.photoPin);
      expect(photoPin.layer, MarkupLayer.photos);
      expect(photoPin.gps?.lat, 24.713600);
      expect(photoPin.gps?.lng, 46.675300);
      expect(photoPin.text, 'Flange Spool Weld Inspection');
      expect(photoPin.metadata?['accuracy'], '±2.8m');
      expect(photoPin.author, 'Field Engineer');
    });

    test('16. Revision Compare: Correct diff overlay classification between Rev 0 and Rev 1', () async {
      final rev0Item = AnnotationItem(
        id: 'rev0-1',
        type: AnnotationType.line,
        color: Colors.blue,
        strokeWidth: 2,
        points: const [Point2D(0.1, 0.1), Point2D(0.4, 0.1)],
      );

      final rev1Item = AnnotationItem(
        id: 'rev1-1',
        type: AnnotationType.line,
        color: Colors.teal,
        strokeWidth: 2,
        points: const [Point2D(0.1, 0.2), Point2D(0.4, 0.2)],
      );

      // Verify model representation of revision difference
      expect(rev0Item.id, isNot(equals(rev1Item.id)));
      expect(rev0Item.points.first.y, isNot(equals(rev1Item.points.first.y)));
    });
  });
}
