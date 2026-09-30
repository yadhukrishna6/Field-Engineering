import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:field_engineering/core/database/app_database.dart';
import 'package:field_engineering/core/database/database_tables.dart';
import 'package:field_engineering/core/sync/sync_engine.dart';
import 'package:field_engineering/core/sync/sync_queue_item.dart';
import 'package:field_engineering/core/sync/conflict_resolver.dart';
import 'package:field_engineering/core/security/secure_storage_service.dart';
import 'package:field_engineering/core/security/rbac_manager.dart';
import 'package:field_engineering/core/security/audit_logger.dart';
import 'package:field_engineering/features/drawings/domain/models/drawing_revision.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Phase 5 — Production Sync Engine & Document Management Test Suite', () {
    test('1. RBAC & Security: User role switching and permissions enforcement', () async {
      final sec = SecureStorageService();
      expect(sec.currentUser.role, UserRole.leadEngineer);
      expect(sec.currentUser.role.canApproveRevisions, isTrue);

      sec.switchUserRole(UserRole.clientRepresentative);
      expect(sec.currentUser.role, UserRole.clientRepresentative);
      expect(sec.currentUser.role.canApproveRevisions, isFalse);
      expect(sec.currentUser.role.canCreateMarkups, isFalse);

      sec.switchUserRole(UserRole.leadEngineer);
      expect(sec.currentUser.role.canApproveRevisions, isTrue);
    });

    test('2. Drawing Revisions: Historical revisions (Rev 00, Rev 01, Rev 02) immutability', () async {
      final rev0 = DrawingRevision.create(
        drawingId: 'dwg-test-101',
        revisionNumber: 'Rev 00',
        revisionDescription: 'Issued for Review (IFR)',
        uploadedBy: 'Lead Piping Engineer',
        filePath: 'test/path/dwg_rev00.pdf',
        status: RevisionStatus.superseded,
      );

      final rev1 = DrawingRevision.create(
        drawingId: 'dwg-test-101',
        revisionNumber: 'Rev 01',
        revisionDescription: 'Issued for Construction (IFC)',
        uploadedBy: 'Alex Morgan, Lead Engineer',
        filePath: 'test/path/dwg_rev01.pdf',
        status: RevisionStatus.approved,
      );

      expect(rev0.revisionNumber, 'Rev 00');
      expect(rev1.revisionNumber, 'Rev 01');
      expect(rev0.id, isNot(equals(rev1.id)));

      final map = rev1.toMap();
      final fromMap = DrawingRevision.fromMap(map);
      expect(fromMap.revisionNumber, 'Rev 01');
      expect(fromMap.status, RevisionStatus.approved);
    });

    test('3. Conflict Resolution: 3-way payload merge & optimistic versioning', () {
      final conflict = SyncConflictRecord.create(
        entityType: 'MARKUP',
        entityId: 'mkp-conflict-01',
        localPayload: {
          'id': 'mkp-conflict-01',
          'text': 'Field updated dimension to 14.85m',
          'color': 0xFFFF0000,
          'version': 2,
        },
        serverPayload: {
          'id': 'mkp-conflict-01',
          'text': 'Office updated notes: PSV tagged',
          'color': 0xFF00FF00,
          'version': 3,
        },
        localVersion: 2,
        serverVersion: 3,
      );

      expect(conflict.localVersion, 2);
      expect(conflict.serverVersion, 3);

      final merged = conflict.mergePayloads();
      expect(merged['version'], 4); // Bumps to version 4
      expect(merged['text'], 'Field updated dimension to 14.85m'); // Local update preserved
    });

    test('4. Complete Offline Field Workflow to Cloud Sync Simulation', () async {
      final db = await AppDatabase.instance.database;
      await db.delete(DatabaseTables.syncQueue);

      final engine = SyncEngine();

      // Step A: Turn off internet (Desert field mode)
      engine.setConnectivity(false);
      expect(engine.isOnline, isFalse);

      var status = await engine.getCurrentStatus();
      expect(status.state, SyncEngineState.offline);

      // Step B: Work in field - enqueue markups, measurements, issues, inspections
      await engine.enqueueOperation(
        entityType: 'project',
        entityId: 'prj-safaniya-01',
        operation: SyncOperation.create,
        payload: {
          'id': 'prj-safaniya-01',
          'project_number': 'PRJ-2026-SAF',
          'name': 'Safaniya Offshore Separation Skid',
          'version': 1,
        },
      );

      await engine.enqueueOperation(
        entityType: 'markup',
        entityId: 'mkp-field-01',
        operation: SyncOperation.create,
        payload: {
          'id': 'mkp-field-01',
          'drawing_id': 'dwg-p-402-01',
          'type': 'cloud',
          'color': 0xFFFF0000,
          'version': 1,
        },
      );

      await engine.enqueueOperation(
        entityType: 'issue',
        entityId: 'iss-field-01',
        operation: SyncOperation.create,
        payload: {
          'id': 'iss-field-01',
          'title': 'Gasket specification mismatch',
          'category': 'Piping',
          'priority': 'Critical',
          'status': 'Open',
          'version': 1,
        },
      );

      // Step C: Verify offline data was queued and NOT lost
      final pendingQueue = await engine.getPendingQueue();
      expect(pendingQueue.length, greaterThanOrEqualTo(3));

      status = await engine.getCurrentStatus();
      expect(status.state, SyncEngineState.offline);
      expect(status.pendingCount, greaterThanOrEqualTo(3));

      // Step D: Restore internet connectivity & Synchronize
      engine.setConnectivity(true);
      expect(engine.isOnline, isTrue);

      final syncSuccess = await engine.triggerSync();
      expect(syncSuccess, isTrue);

      // Step E: Verify status becomes Synced
      status = await engine.getCurrentStatus();
      expect(status.pendingCount, equals(0));
      expect(status.state, SyncEngineState.synced);
    });

    test('5. Audit Logger: Log creation and retrieval', () async {
      final logger = AuditLogger();
      await logger.log(
        action: 'APPROVE_REVISION',
        entityType: 'REVISION',
        entityId: 'rev-01-dwg',
        details: 'Approved Rev 01 for construction release',
      );

      final logs = await logger.getRecentLogs(limit: 10);
      expect(logs.any((l) => l.action == 'APPROVE_REVISION'), isTrue);
    });
  });
}
