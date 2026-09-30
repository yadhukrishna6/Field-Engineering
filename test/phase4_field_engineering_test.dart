import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:field_engineering/core/database/app_database.dart';
import 'package:field_engineering/core/services/field_gps_service.dart';
import 'package:field_engineering/features/issues/domain/models/issue.dart';
import 'package:field_engineering/features/issues/data/datasources/issues_local_datasource.dart';
import 'package:field_engineering/features/photos/domain/models/photo_attachment.dart';
import 'package:field_engineering/features/photos/data/datasources/photos_local_datasource.dart';
import 'package:field_engineering/features/voice_notes/domain/models/voice_note.dart';
import 'package:field_engineering/features/voice_notes/data/datasources/voice_notes_local_datasource.dart';
import 'package:field_engineering/features/inspections/domain/models/inspection.dart';
import 'package:field_engineering/features/inspections/domain/models/inspection_item.dart';
import 'package:field_engineering/features/inspections/data/datasources/inspections_local_datasource.dart';
import 'package:field_engineering/features/equipment/domain/models/equipment_item.dart';
import 'package:field_engineering/features/equipment/data/datasources/equipment_local_datasource.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Part 1 & 6: Field Issues & Punch List Lifecycle Tests', () {
    test('Issue domain model supports all 8 categories and 4 priorities', () {
      expect(IssueCategory.piping.label, 'Piping');
      expect(IssueCategory.mechanical.label, 'Mechanical');
      expect(IssueCategory.electrical.label, 'Electrical');
      expect(IssueCategory.civil.label, 'Civil');
      expect(IssueCategory.structural.label, 'Structural');
      expect(IssueCategory.instrumentation.label, 'Instrumentation');
      expect(IssueCategory.safety.label, 'Safety');
      expect(IssueCategory.other.label, 'Other');

      expect(IssuePriority.low.level, 1);
      expect(IssuePriority.medium.level, 2);
      expect(IssuePriority.high.level, 3);
      expect(IssuePriority.critical.level, 4);

      expect(IssueStatus.open.label, 'Open');
      expect(IssueStatus.inProgress.label, 'In Progress');
      expect(IssueStatus.resolved.label, 'Resolved');
      expect(IssueStatus.verified.label, 'Verified');
      expect(IssueStatus.closed.label, 'Closed');
    });

    test('Issue model serializes to and from Map for offline SQLite storage', () {
      final now = DateTime.now();
      final issue = Issue(
        id: 'ISSUE-001',
        projectId: 'PRJ-101',
        drawingId: 'DWG-201',
        pageNumber: 2,
        positionX: 0.452,
        positionY: 0.678,
        title: '6" Flange Bolt Torque Discrepancy',
        description: 'Stud bolts on nozzle N1 not tightened to ASME PCC-1 spec',
        category: IssueCategory.piping,
        priority: IssuePriority.critical,
        status: IssueStatus.open,
        assignedTo: 'Mechanical Crew A',
        createdBy: 'QC Lead Engineer',
        dueDate: '2026-10-15',
        latitude: 25.4321,
        longitude: 49.3142,
        gpsAccuracy: 1.8,
        createdAt: now,
        updatedAt: now,
      );

      final map = issue.toMap();
      expect(map['id'], 'ISSUE-001');
      expect(map['category'], 'Piping');
      expect(map['priority'], 'Critical');
      expect(map['status'], 'Open');
      expect(map['position_x'], 0.452);
      expect(map['position_y'], 0.678);

      final restored = Issue.fromMap(map);
      expect(restored.id, issue.id);
      expect(restored.category, IssueCategory.piping);
      expect(restored.priority, IssuePriority.critical);
      expect(restored.status, IssueStatus.open);
      expect(restored.isPinnedToDrawing, true);
      expect(restored.latitude, 25.4321);
    });

    test('Punch List status lifecycle transitions work smoothly', () {
      final issue = Issue(
        id: 'PUNCH-001',
        projectId: 'PRJ-101',
        title: 'Weld undercut on Joint W-12',
        description: 'Visual inspection failed root pass undercut',
        category: IssueCategory.piping,
        priority: IssuePriority.high,
        status: IssueStatus.open,
        createdBy: 'QC Inspector',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. Assign to crew -> In Progress
      final assigned = issue.copyWith(
        assignedTo: 'Welding Contractor Crew 3',
        status: IssueStatus.inProgress,
      );
      expect(assigned.status, IssueStatus.inProgress);
      expect(assigned.assignedTo, 'Welding Contractor Crew 3');

      // 2. Grind and re-weld complete -> Resolved
      final resolved = assigned.copyWith(status: IssueStatus.resolved);
      expect(resolved.status, IssueStatus.resolved);

      // 3. QC visual re-inspection -> Verified
      final verified = resolved.copyWith(status: IssueStatus.verified);
      expect(verified.status, IssueStatus.verified);

      // 4. Final sign-off -> Closed
      final closed = verified.copyWith(status: IssueStatus.closed);
      expect(closed.status, IssueStatus.closed);
    });
  });

  group('Part 2 & 3: Photos & Offline GPS Telemetry Tests', () {
    test('Field GPS Service provides coordinates, DMS string, and UTM format', () async {
      final gpsService = FieldGpsService.instance;
      final fix = await gpsService.getCurrentPosition(
        manualLat: 25.432100,
        manualLng: 49.314200,
        accuracy: 2.1,
      );

      expect(fix.latitude, 25.432100);
      expect(fix.longitude, 49.314200);
      expect(fix.accuracy, 2.1);

      final dms = fix.toDmsString();
      expect(dms, contains('25°'));
      expect(dms, contains('N'));
      expect(dms, contains('49°'));
      expect(dms, contains('E'));

      final utm = fix.toUtmString();
      expect(utm, contains('UTM Zone'));
    });

    test('PhotoAttachment serializes offline metadata and drawing pin coordinates', () {
      final photo = PhotoAttachment(
        id: 'PHOTO-001',
        filePath: '/data/photos/flange_leak_01.jpg',
        title: 'Flange Joint Leak',
        caption: 'Gasket blowout observed during 1.5x hydrotest',
        latitude: 25.432100,
        longitude: 49.314200,
        gpsAccuracy: 1.5,
        drawingId: 'DWG-100',
        pageNumber: 1,
        positionX: 0.35,
        positionY: 0.72,
        issueId: 'ISSUE-001',
        fileSize: 2048500,
        createdAt: DateTime.now(),
      );

      expect(photo.isDrawingPin, true);

      final map = photo.toMap();
      expect(map['file_path'], '/data/photos/flange_leak_01.jpg');
      expect(map['issue_id'], 'ISSUE-001');

      final fromMap = PhotoAttachment.fromMap(map);
      expect(fromMap.id, photo.id);
      expect(fromMap.latitude, photo.latitude);
      expect(fromMap.positionX, 0.35);
    });
  });

  group('Part 4: Voice Notes Engine Tests', () {
    test('VoiceNote model formats duration and preserves offline file link', () {
      final note = VoiceNote(
        id: 'VOICE-001',
        filePath: '/data/voice_notes/pump_cavitation.m4a',
        title: 'Pump P-101A Cavitation Sound Memo',
        durationSeconds: 145, // 2 minutes 25 seconds
        drawingId: 'DWG-100',
        pageNumber: 1,
        positionX: 0.82,
        positionY: 0.15,
        createdBy: 'Rotating Equipment Specialist',
        createdAt: DateTime.now(),
      );

      expect(note.formattedDuration, '02:25');
      expect(note.isDrawingPin, true);

      final map = note.toMap();
      expect(map['duration_seconds'], 145);

      final restored = VoiceNote.fromMap(map);
      expect(restored.id, note.id);
      expect(restored.formattedDuration, '02:25');
    });
  });

  group('Part 5: Inspection Checklists, Digital Signatures & Conversion Tests', () {
    test('Standard Piping Inspection checklist generates 10 standard items', () {
      final items = Inspection.createTemplateItems(
        inspectionId: 'INSP-101',
        templateType: 'Piping',
      );

      expect(items.length, 10);
      expect(items[0].description, 'Pipe installed according to drawing');
      expect(items[1].description, 'Correct diameter');
      expect(items[2].description, 'Correct material');
      expect(items[3].description, 'Flange installed');
      expect(items[4].description, 'Valve installed');
      expect(items[5].description, 'Support installed');
      expect(items[6].description, 'Welding completed');
      expect(items[7].description, 'Insulation completed');
      expect(items[8].description, 'Painting completed');
      expect(items[9].description, 'Hydro test completed');

      // All items start PENDING
      expect(items.every((i) => i.status == ChecklistStatus.pending), true);
    });

    test('Checklist item supports PASS, FAIL, N/A, PENDING status and comments', () {
      final item = InspectionItem(
        id: 'CHK-01',
        inspectionId: 'INSP-101',
        category: 'Piping',
        description: 'Welding completed',
        status: ChecklistStatus.pending,
      );

      final passItem = item.copyWith(status: ChecklistStatus.pass);
      expect(passItem.status, ChecklistStatus.pass);

      final failItem = item.copyWith(
        status: ChecklistStatus.fail,
        comments: 'Root pass weld lack of fusion on joint W-05',
      );
      expect(failItem.status, ChecklistStatus.fail);
      expect(failItem.comments, contains('lack of fusion'));

      final naItem = item.copyWith(status: ChecklistStatus.na);
      expect(naItem.status, ChecklistStatus.na);
    });

    test('Inspection model calculates completion percentage, counters, and signatures', () {
      final items = [
        const InspectionItem(id: '1', inspectionId: 'INSP-1', category: 'Piping', description: 'Item 1', status: ChecklistStatus.pass),
        const InspectionItem(id: '2', inspectionId: 'INSP-1', category: 'Piping', description: 'Item 2', status: ChecklistStatus.pass),
        const InspectionItem(id: '3', inspectionId: 'INSP-1', category: 'Piping', description: 'Item 3', status: ChecklistStatus.fail),
        const InspectionItem(id: '4', inspectionId: 'INSP-1', category: 'Piping', description: 'Item 4', status: ChecklistStatus.pending),
      ];

      final inspection = Inspection(
        id: 'INSP-1',
        projectId: 'PRJ-101',
        title: 'Line 101 Hydrotest QC',
        inspectionType: 'Piping',
        inspectorName: 'QC Lead Engineer',
        inspectorSignaturePath: '/data/signatures/inspector_sig.png',
        clientSignaturePath: '/data/signatures/client_sig.png',
        inspectionDate: DateTime.now(),
        items: items,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(inspection.passCount, 2);
      expect(inspection.failCount, 1);
      expect(inspection.pendingCount, 1);
      expect(inspection.naCount, 0);
      expect(inspection.completionPercentage, 0.75); // 3 out of 4 evaluated
      expect(inspection.inspectorSignaturePath, isNotNull);
      expect(inspection.clientSignaturePath, isNotNull);
    });
  });

  group('Part 7: Equipment Master Registry Tests', () {
    test('EquipmentItem model serializes and stores tag number, type and drawing links', () {
      final eq = EquipmentItem(
        id: 'EQ-001',
        projectId: 'PRJ-101',
        equipmentNumber: 'EQ-1004',
        tagNumber: 'P-101A',
        name: 'Crude Feed Centrifugal Pump',
        type: 'Pump',
        location: 'Unit 100 Crude Distillation Area - Bay 2',
        drawingId: 'DWG-PID-001',
        notes: 'API 610 11th Edition, Plan 53B Seal Flush',
        status: 'Operational',
        latitude: 25.432100,
        longitude: 49.314200,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = eq.toMap();
      expect(map['tag_number'], 'P-101A');
      expect(map['equipment_number'], 'EQ-1004');
      expect(map['drawing_type'], 'Pump');
      expect(map['drawing_id'], 'DWG-PID-001');

      final restored = EquipmentItem.fromMap(map);
      expect(restored.tagNumber, 'P-101A');
      expect(restored.name, 'Crude Feed Centrifugal Pump');
      expect(restored.status, 'Operational');
    });
  });

  group('Part 8: 100% Offline Inspection & Field Operations Verification', () {
    test('Engineer can create an issue, attach offline photos, record voice note, perform full inspection checklist, and link equipment completely offline', () async {
      // 1. Initialize SQLite Database
      final db = AppDatabase.instance;
      final issuesDataSource = IssuesLocalDataSource(appDatabase: db);
      final photosDataSource = PhotosLocalDataSource(appDatabase: db);
      final voiceDataSource = VoiceNotesLocalDataSource(appDatabase: db);
      final inspectionsDataSource = InspectionsLocalDataSource(appDatabase: db);
      final equipmentDataSource = EquipmentLocalDataSource(appDatabase: db);

      // 2. Create Project Equipment Master Record
      final equipment = EquipmentItem(
        id: 'EQ-OFFLINE-01',
        projectId: 'PRJ-DESERT-1',
        equipmentNumber: 'EQ-5001',
        tagNumber: 'E-201',
        name: 'Feed Preheater Exchanger',
        type: 'Exchanger',
        location: 'Desert Site Station 4',
        drawingId: 'DWG-OFFLINE-01',
        notes: 'TEMA Type AES Exchanger',
        status: 'Operational',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await equipmentDataSource.insertEquipment(equipment);

      final savedEq = await equipmentDataSource.getEquipmentByTagNumber('E-201');
      expect(savedEq, isNotNull);
      expect(savedEq!.name, 'Feed Preheater Exchanger');

      // 3. Create Full Inspection Checklist with 10 Piping Items
      final inspId = 'INSP-OFFLINE-01';
      final templateItems = Inspection.createTemplateItems(
        inspectionId: inspId,
        templateType: 'Piping',
      );

      // Engineer inspects items offline:
      // Item 0: PASS
      // Item 6 (Welding): FAIL
      final evaluatedItems = templateItems.map((item) {
        if (item.orderIndex == 0) {
          return item.copyWith(status: ChecklistStatus.pass);
        } else if (item.orderIndex == 6) {
          return item.copyWith(
            status: ChecklistStatus.fail,
            comments: 'Weld cap height exceeds 3mm API 1104 limit',
          );
        } else {
          return item.copyWith(status: ChecklistStatus.pass);
        }
      }).toList();

      final inspection = Inspection(
        id: inspId,
        projectId: 'PRJ-DESERT-1',
        drawingId: 'DWG-OFFLINE-01',
        equipmentId: savedEq.id,
        title: 'Desert Station 4 Piping QC',
        inspectionType: 'Piping',
        inspectorName: 'Desert Field QC Engineer',
        inspectorSignaturePath: '/offline_storage/inspector_signature.png',
        clientSignaturePath: '/offline_storage/client_signature.png',
        status: InspectionStatus.completed,
        inspectionDate: DateTime.now(),
        latitude: 25.432100,
        longitude: 49.314200,
        items: evaluatedItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await inspectionsDataSource.insertInspection(inspection);

      final loadedInspection = await inspectionsDataSource.getInspectionById(inspId);
      expect(loadedInspection, isNotNull);
      expect(loadedInspection!.passCount, 9);
      expect(loadedInspection.failCount, 1);

      // 4. 1-Tap Conversion of Failed Item into Field Issue Pin on Drawing
      final failedItem = loadedInspection.items.firstWhere((i) => i.status == ChecklistStatus.fail);
      final issuePin = Issue(
        id: 'ISSUE-OFFLINE-01',
        projectId: 'PRJ-DESERT-1',
        drawingId: 'DWG-OFFLINE-01',
        pageNumber: 1,
        positionX: 0.523,
        positionY: 0.412,
        title: 'FAILED: ${failedItem.description}',
        description: failedItem.comments!,
        category: IssueCategory.piping,
        priority: IssuePriority.high,
        status: IssueStatus.open,
        assignedTo: 'Desert Welding Team',
        createdBy: loadedInspection.inspectorName,
        equipmentId: savedEq.id,
        inspectionId: loadedInspection.id,
        latitude: 25.432100,
        longitude: 49.314200,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await issuesDataSource.insertIssue(issuePin);

      // 5. Attach Photo & Voice Note to the Issue Pin
      final photo = PhotoAttachment(
        id: 'PHOTO-OFFLINE-01',
        filePath: '/offline_storage/weld_cap_excess.jpg',
        title: 'Excess Weld Cap Profile',
        latitude: 25.432100,
        longitude: 49.314200,
        drawingId: 'DWG-OFFLINE-01',
        pageNumber: 1,
        positionX: 0.523,
        positionY: 0.412,
        issueId: issuePin.id,
        fileSize: 1540000,
        createdAt: DateTime.now(),
      );
      await photosDataSource.insertPhoto(photo);

      final voiceNote = VoiceNote(
        id: 'VOICE-OFFLINE-01',
        filePath: '/offline_storage/weld_defect_memo.m4a',
        title: 'Audio Observation - Weld W-14 Excessive Reinforcement',
        durationSeconds: 42,
        drawingId: 'DWG-OFFLINE-01',
        pageNumber: 1,
        positionX: 0.523,
        positionY: 0.412,
        issueId: issuePin.id,
        createdAt: DateTime.now(),
      );
      await voiceDataSource.insertVoiceNote(voiceNote);

      // 6. Verify Complete Data Integrity Offline
      final drawingIssues = await issuesDataSource.getIssuesByDrawing('DWG-OFFLINE-01', pageNumber: 1);
      expect(drawingIssues.length, 1);
      expect(drawingIssues.first.title, contains('FAILED: Welding completed'));

      final issuePhotos = await photosDataSource.getPhotosByIssue(issuePin.id);
      expect(issuePhotos.length, 1);
      expect(issuePhotos.first.title, 'Excess Weld Cap Profile');

      final issueVoiceNotes = await voiceDataSource.getVoiceNotesByIssue(issuePin.id);
      expect(issueVoiceNotes.length, 1);
      expect(issueVoiceNotes.first.durationSeconds, 42);

      // 7. Verify Punch List Resolution Workflow
      final resolvedIssue = issuePin.copyWith(
        status: IssueStatus.resolved,
        updatedAt: DateTime.now(),
      );
      await issuesDataSource.updateIssue(resolvedIssue);

      final verifiedIssue = (await issuesDataSource.getIssueById(issuePin.id))!.copyWith(
        status: IssueStatus.verified,
        updatedAt: DateTime.now(),
      );
      await issuesDataSource.updateIssue(verifiedIssue);

      final finalIssue = await issuesDataSource.getIssueById(issuePin.id);
      expect(finalIssue!.status, IssueStatus.verified);
    });
  });
}
