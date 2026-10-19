import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/core/theme/glove_mode_controller.dart';
import 'package:field_engineering/core/theme/theme_controller.dart';
import 'package:field_engineering/features/markup/data/local/offline_sync_queue.dart';
import 'package:field_engineering/features/markup/domain/models/annotation_item.dart';
import 'package:field_engineering/features/markup/domain/models/drawing_file.dart';
import 'package:field_engineering/features/markup/domain/models/markup_layer.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/presentation/controllers/markup_editor_controller.dart';
import 'package:field_engineering/features/markup/presentation/widgets/quick_notes_sheet.dart';
import 'package:field_engineering/features/markup/presentation/widgets/stamps_sheet.dart';
import 'package:field_engineering/features/markup/data/repositories/markup_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PHASE A - Dust, Glove and Sun Usability', () {
    test('1. Glove Mode: touch targets >= 56dp and pen width >= 4px', () {
      const normalState = GloveModeState(isGloveMode: false);
      expect(normalState.minTouchTarget(false), 44.0);
      expect(normalState.minTouchTarget(true), 48.0);
      expect(normalState.minPenWidth(false), 3.0);
      expect(normalState.minPenWidth(true), 3.5);
      expect(normalState.tapDistanceThreshold, 0.02);

      const gloveState = GloveModeState(isGloveMode: true);
      expect(gloveState.minTouchTarget(false), greaterThanOrEqualTo(56.0));
      expect(gloveState.minTouchTarget(true), greaterThanOrEqualTo(56.0));
      expect(gloveState.minPenWidth(false), greaterThanOrEqualTo(4.0));
      expect(gloveState.minPenWidth(true), greaterThanOrEqualTo(4.0));
      expect(gloveState.tapDistanceThreshold, greaterThan(0.04));
      expect(gloveState.iconSize(false), greaterThanOrEqualTo(28.0));
    });

    test('2. Wipe Lock: freezes canvas and prevents stroke creation or erasing', () {
      final repo = MarkupRepositoryImpl();
      final drawing = DrawingFile(
        id: 'dwg-test-wipe',
        name: 'ISO-4001.pdf',
        fileType: 'PDF',
        pageCount: 1,
        localPath: '/tmp/test.pdf',
        createdAt: DateTime.now(),
      );

      final controller = MarkupEditorController(repo, drawing);

      // Verify initial state is unlocked
      expect(controller.state.isWipeLocked, isFalse);

      // Lock canvas
      controller.toggleWipeLock();
      expect(controller.state.isWipeLocked, isTrue);

      // Attempting to draw while locked must be ignored
      controller.startStroke(const Point2D(0.5, 0.5));
      controller.appendStrokePoint(const Point2D(0.6, 0.6));
      controller.finishStroke();
      expect(controller.state.annotations.isEmpty, isTrue);

      // Palm / cloth auto-lock
      controller.unlockWipe();
      expect(controller.state.isWipeLocked, isFalse);
      controller.triggerPalmClothAutoLock();
      expect(controller.state.isWipeLocked, isTrue);
      expect(controller.state.autoLockedDueToPalm, isTrue);

      // Unlock
      controller.unlockWipe();
      expect(controller.state.isWipeLocked, isFalse);
    });

    test('3. Auto Theme: ambient sensor and persisted manual override', () {
      final controller = ThemeController(null);
      expect(controller.state.themeMode, AppThemeMode.auto);
      expect(controller.state.activeTheme, AppActiveTheme.standard);

      // Direct sunlight > 25,000 lux
      controller.setAmbientSunlightDetected(true);
      expect(controller.state.isOutdoorActive, isTrue);
      expect(controller.state.activeTheme, AppActiveTheme.outdoor);

      // Low ambient light indoors
      controller.setAmbientSunlightDetected(false);
      expect(controller.state.isOutdoorActive, isFalse);

      // Manual outdoor override
      controller.setManualOutdoorOverride(true);
      expect(controller.state.isOutdoorActive, isTrue);
    });

    test('4. Fully Offline & Conflict Resolution: latest updatedAt wins, keeps loser as conflict copy', () {
      final t1 = DateTime(2026, 10, 7, 10, 0);
      final t2 = DateTime(2026, 10, 7, 10, 30); // newer

      final localAnn = AnnotationItem(
        id: 'ann-1',
        type: AnnotationType.stroke,
        color: const Color(0xFFD03A33),
        strokeWidth: 3.0,
        points: const [Point2D(0.1, 0.1), Point2D(0.2, 0.2)],
        text: 'Local Version',
        updatedAt: t2, // Local is newer
      );

      final remoteAnn = AnnotationItem(
        id: 'ann-1',
        type: AnnotationType.stroke,
        color: const Color(0xFF1E88E5),
        strokeWidth: 3.0,
        points: const [Point2D(0.1, 0.1), Point2D(0.3, 0.3)],
        text: 'Remote Version',
        updatedAt: t1, // Remote is older
      );

      final resolved = AnnotationConflictResolver.resolveConflicts(
        localAnnotations: [localAnn],
        remoteAnnotations: [remoteAnn],
      );

      expect(resolved.length, 2);
      final active = resolved.firstWhere((a) => !a.isConflictCopy);
      final conflictCopy = resolved.firstWhere((a) => a.isConflictCopy);

      expect(active.id, 'ann-1');
      expect(active.text, 'Local Version');
      expect(conflictCopy.conflictOriginalId, 'ann-1');
      expect(conflictCopy.text, 'Remote Version');

      // Test Restore conflict copy
      final restored = AnnotationConflictResolver.restoreConflictCopy(
        annotations: resolved,
        conflictCopyId: conflictCopy.id,
      );

      final newActive = restored.firstWhere((a) => !a.isConflictCopy);
      expect(newActive.id, 'ann-1');
      expect(newActive.text, 'Remote Version');
    });
  });

  group('PHASE B - Faster, Standardized Markup', () {
    test('5. Quick-Notes: Delete, Add, Replace, Relocate, Verify in field', () {
      final repo = MarkupRepositoryImpl();
      final drawing = DrawingFile(
        id: 'dwg-test-quicknotes',
        name: 'ISO-5002.pdf',
        fileType: 'PDF',
        pageCount: 1,
        localPath: '/tmp/test.pdf',
        createdAt: DateTime.now(),
      );

      final controller = MarkupEditorController(repo, drawing);

      // Add Quick Note: Delete (Red)
      controller.addQuickNote(
        text: QuickNoteType.delete.label,
        changeType: QuickNoteType.delete.changeType,
        color: QuickNoteType.delete.getColor(false),
        x: 0.25,
        y: 0.35,
      );

      // Add Quick Note: Add (Orange)
      controller.addQuickNote(
        text: QuickNoteType.add.label,
        changeType: QuickNoteType.add.changeType,
        color: QuickNoteType.add.getColor(false),
        x: 0.50,
        y: 0.50,
      );

      // Add Quick Note: Relocate (Blue)
      controller.addQuickNote(
        text: QuickNoteType.relocate.label,
        changeType: QuickNoteType.relocate.changeType,
        color: QuickNoteType.relocate.getColor(false),
        x: 0.70,
        y: 0.70,
      );

      expect(controller.state.annotations.length, 3);
      expect(controller.state.annotations[0].changeType, 'delete');
      expect(controller.state.annotations[0].color, const Color(0xFFD03A33));
      expect(controller.state.annotations[1].changeType, 'add');
      expect(controller.state.annotations[1].color, const Color(0xFFE06A26));
      expect(controller.state.annotations[2].changeType, 'relocate');
      expect(controller.state.annotations[2].color, const Color(0xFF1E88E5));
    });

    test('6. Strike-out Tool: draws clean cross-out with changeType = delete', () {
      final repo = MarkupRepositoryImpl();
      final drawing = DrawingFile(
        id: 'dwg-test-strikeout',
        name: 'ISO-5003.pdf',
        fileType: 'PDF',
        pageCount: 1,
        localPath: '/tmp/test.pdf',
        createdAt: DateTime.now(),
      );

      final controller = MarkupEditorController(repo, drawing);
      controller.selectTool(MarkupTool.strikeOut);

      controller.startStroke(const Point2D(0.2, 0.2));
      controller.appendStrokePoint(const Point2D(0.4, 0.2));
      controller.finishStroke();

      expect(controller.state.annotations.length, 1);
      final strike = controller.state.annotations.first;
      expect(strike.type, AnnotationType.strikeOut);
      expect(strike.changeType, 'delete');
      expect(strike.text, 'DELETE');
    });

    test('7. Note Box: boxed multi-line paragraph with changeType = note', () {
      final repo = MarkupRepositoryImpl();
      final drawing = DrawingFile(
        id: 'dwg-test-notebox',
        name: 'ISO-5004.pdf',
        fileType: 'PDF',
        pageCount: 1,
        localPath: '/tmp/test.pdf',
        createdAt: DateTime.now(),
      );

      final controller = MarkupEditorController(repo, drawing);
      controller.addNoteBox(
        text: 'NEW SPOOL TO BE INSTALLED\nFIELD VERIFY BEFORE CUTTING',
        x: 0.3,
        y: 0.4,
      );

      expect(controller.state.annotations.length, 1);
      final note = controller.state.annotations.first;
      expect(note.type, AnnotationType.noteBox);
      expect(note.changeType, 'note');
      expect(note.text, contains('NEW SPOOL TO BE INSTALLED'));
    });

    test('8. Stamps: placed on locked layer and cannot be erased by field eraser', () {
      final repo = MarkupRepositoryImpl();
      final drawing = DrawingFile(
        id: 'dwg-test-stamps',
        name: 'ISO-5005.pdf',
        fileType: 'PDF',
        pageCount: 1,
        localPath: '/tmp/test.pdf',
        createdAt: DateTime.now(),
      );

      final controller = MarkupEditorController(repo, drawing);
      controller.addStamp(
        stampTitle: StampType.approved.title,
        color: StampType.approved.getColor(false),
        x: 0.8,
        y: 0.85,
        userName: 'Eng. Yadhukrishna',
      );

      expect(controller.state.annotations.length, 1);
      final stamp = controller.state.annotations.first;
      expect(stamp.type, AnnotationType.stamp);
      expect(stamp.layer, MarkupLayer.inspection);
      expect(stamp.metadata?['isLocked'], isTrue);
      expect(stamp.metadata?['user'], 'Eng. Yadhukrishna');

      // Attempting to erase locked stamp with field eraser must fail
      final erased = controller.eraseAt(const Point2D(0.81, 0.86));
      expect(erased, isFalse);
      expect(controller.state.annotations.length, 1); // Stamp is preserved!
    });
  });
}
