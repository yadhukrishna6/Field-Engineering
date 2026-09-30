import 'dart:convert';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:field_engineering/core/database/app_database.dart';
import 'package:field_engineering/core/database/database_tables.dart';
import 'package:field_engineering/core/ai/field_ai_service.dart';
import 'package:field_engineering/core/security/digital_signature_service.dart';
import 'package:field_engineering/core/security/rbac_manager.dart';
import 'package:field_engineering/core/security/audit_logger.dart';
import 'package:field_engineering/core/reliability/crash_recovery_service.dart';
import 'package:field_engineering/core/reliability/diagnostics_service.dart';
import 'package:field_engineering/core/sync/sync_queue_item.dart';
import 'package:field_engineering/features/drawings/domain/models/drawing.dart';
import 'package:field_engineering/features/drawings/domain/models/drawing_type.dart';
import 'package:field_engineering/features/drawings/domain/models/drawing_calibration.dart';
import 'package:field_engineering/features/drawings/domain/models/engineering_symbol.dart';
import 'package:field_engineering/features/drawings/domain/models/as_built_lifecycle.dart';
import 'package:field_engineering/features/drawings/domain/models/markup.dart';
import 'package:field_engineering/features/drawings/domain/models/measurement.dart';
import 'package:field_engineering/features/drawings/domain/utils/measurement_calculator.dart';
import 'package:field_engineering/features/equipment/domain/models/equipment_qr_payload.dart';
import 'package:field_engineering/features/issues/domain/models/issue.dart';
import 'package:field_engineering/features/inspections/domain/models/inspection.dart';
import 'package:field_engineering/features/inspections/domain/models/inspection_item.dart';
import 'package:field_engineering/features/takeoff/domain/models/takeoff_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 6 — Final Production Platform 22-Step Field Engineer Test Suite', () {
    setUpAll(() async {
      final db = await AppDatabase.instance.database;
      await db.delete('projects');
      await db.delete('drawings');
      await db.delete('markups');
      await db.delete('measurements');
      await db.delete('calibrations');
      await db.delete('issues');
      await db.delete('photos');
      await db.delete('inspections');
      await db.delete('equipment');
      await db.delete('audit_logs');
      await db.delete('sync_queue');
    });

    test('Step 1-2: Project Setup & Drawing Navigation', () async {
      final db = await AppDatabase.instance.database;

      await db.insert('projects', {
        'id': 'prj-desert-01',
        'project_number': 'PRJ-SA-2026',
        'name': 'Safaniya Offshore Separation Facility',
        'description': 'EPC Offshore separation and treatment platform',
        'location': 'Arabian Gulf / Remote Field',
        'client': 'Saudi Aramco / EPC Consortium',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final drawing = Drawing(
        id: 'dwg-p-402',
        projectId: 'prj-desert-01',
        drawingNumber: 'DWG-P-402-01',
        title: 'High Pressure Separation Piping P&ID',
        drawingType: DrawingType.pid,
        revision: 'Rev 01',
        filePath: 'assets/sample_drawings/pid_drawing_sample.pdf',
        pageCount: 3,
        fileSize: 409600,
        downloaded: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insert('drawings', drawing.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      final results = await db.query('drawings', where: 'id = ?', whereArgs: ['dwg-p-402']);
      expect(results.isNotEmpty, isTrue);
      expect(results.first['drawing_number'], 'DWG-P-402-01');
    });

    test('Step 3: Drawing Scale Calibration (1000 mm Known Distance)', () async {
      const p1 = Point2D(0.10, 0.20);
      const p2 = Point2D(0.30, 0.20);

      final calibration = DrawingCalibration.fromPoints(
        id: 'cal-dwg-402-p1',
        drawingId: 'dwg-p-402',
        pageNumber: 1,
        point1: p1,
        point2: p2,
        knownDistance: 1000.0,
        unit: CalibrationUnit.mm,
      );

      expect(calibration.scaleFactor, greaterThan(0));
      expect(calibration.unit, CalibrationUnit.mm);
      expect(calibration.formattedScale(), '1000 mm');
    });

    test('Step 4-5: Engineering Distance & Polyline Measurements', () {
      final cal = DrawingCalibration.fromPoints(
        id: 'cal-1',
        drawingId: 'dwg-p-402',
        pageNumber: 1,
        point1: const Point2D(0.0, 0.0),
        point2: const Point2D(1.0, 0.0),
        knownDistance: 10.0,
        unit: CalibrationUnit.m,
      );

      // 4. Distance
      final dist = MeasurementCalculator.calculateValue(
        type: MeasurementType.distance,
        points: const [Point2D(0.1, 0.1), Point2D(0.525, 0.1)],
        calibration: cal,
      );
      expect(dist, closeTo(4.25, 0.01));

      // 5. Polyline
      final polyDist = MeasurementCalculator.calculateValue(
        type: MeasurementType.polylineDistance,
        points: const [
          Point2D(0.1, 0.1),
          Point2D(0.3, 0.1),
          Point2D(0.3, 0.4),
        ],
        calibration: cal,
      );
      expect(polyDist, closeTo(5.0, 0.01));
    });

    test('Step 6: Material Takeoff (MTO) & Component Counts', () async {
      final item = TakeoffItem(
        id: 'to-01',
        projectId: 'prj-desert-01',
        drawingId: 'dwg-p-402',
        itemType: TakeoffItemType.valve,
        itemName: 'Gate Valve 8" ASME Class 300# Carbon Steel',
        specification: 'ASME B16.34',
        size: '8"',
        quantity: 5,
        unit: 'pcs',
        unitWeightKg: 85.0,
        unitCost: 1450.0,
        notes: 'Sheet 1, Grid C-4',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(item.totalWeightKg, 425.0);
      expect(item.totalCost, 7250.0);
    });

    test('Step 7: P&ID Standard Engineering Symbols Library Stamping', () {
      final symbols = EngineeringSymbol.standardLibrary;
      expect(symbols.length, greaterThanOrEqualTo(15));

      final gateValve = symbols.firstWhere((s) => s.tagPrefix == 'GV');
      final psv = symbols.firstWhere((s) => s.tagPrefix == 'PSV');
      final pt = symbols.firstWhere((s) => s.tagPrefix == 'PT');

      expect(gateValve.category, SymbolCategory.valves);
      expect(psv.category, SymbolCategory.valves);
      expect(pt.category, SymbolCategory.instrumentation);
    });

    test('Step 8: Engineering Certification Stamps (APPROVED IFC & AS-BUILT)', () {
      final stamps = EngineeringSymbol.standardLibrary.where((s) => s.isStamp).toList();
      expect(stamps.length, greaterThanOrEqualTo(4));

      final ifcStamp = stamps.firstWhere((s) => s.id == 'stamp-approved-ifc');
      final asBuiltStamp = stamps.firstWhere((s) => s.id == 'stamp-as-built');

      expect(ifcStamp.stampText, contains('APPROVED FOR CONSTRUCTION'));
      expect(asBuiltStamp.stampText, contains('AS-BUILT RECORD DRAWING'));
    });

    test('Step 9-10: Field Issue Creation & Offline GPS Telemetry', () async {
      final db = await AppDatabase.instance.database;

      final issue = Issue(
        id: 'iss-desert-01',
        projectId: 'prj-desert-01',
        drawingId: 'dwg-p-402',
        pageNumber: 1,
        positionX: 0.42,
        positionY: 0.58,
        title: 'Gasket specification mismatch on 8" HP Separator inlet',
        description: 'Installed 150# spiral wound instead of 300# RTJ ring gasket.',
        category: IssueCategory.piping,
        priority: IssuePriority.critical,
        status: IssueStatus.open,
        assignedTo: 'Mechanical QC Lead',
        createdBy: 'Lead Field Engineer',
        latitude: 28.4521,
        longitude: 48.7892,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insert('issues', issue.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      final results = await db.query('issues', where: 'id = ?', whereArgs: ['iss-desert-01']);
      expect(results.first['priority'].toString().toLowerCase(), 'critical');
      expect(results.first['category'].toString().toLowerCase(), 'piping');
    });

    test('Step 11-12: AI Voice-to-Issue Parsing (Safe Human-in-the-Loop)', () async {
      final aiService = FieldAiService();
      const voiceTranscript = 'Found high pressure gas leak on flange FLG-102 near separator V-101';

      final proposal = await aiService.parseVoiceToIssue(voiceTranscript);

      expect(proposal.confidence, greaterThan(0.85));
      expect(proposal.data['category'], 'Piping');
      expect(proposal.data['priority'], 'Critical');
      expect(proposal.isAccepted, isFalse); // AI Safety: requires engineer confirmation
    });

    test('Step 13: AI Safe Blueprint OCR Label Recognition', () async {
      final aiService = FieldAiService();
      final labels = await aiService.detectDrawingLabels('dwg-p-402', 1);

      expect(labels.isNotEmpty, isTrue);
      expect(labels.any((l) => l.text == 'V-101'), isTrue);
      expect(labels.any((l) => l.text == 'FCV-101'), isTrue);
    });

    test('Step 14: Inspection Checklist Execution', () {
      final inspection = Inspection(
        id: 'insp-001',
        drawingId: 'dwg-p-402',
        projectId: 'prj-desert-01',
        title: 'ASME B31.3 Piping Flange & Bolt Walkdown',
        inspectorName: 'Lead Field Engineer',
        inspectionType: 'Piping Quality',
        status: InspectionStatus.completed,
        inspectionDate: DateTime.now(),
        items: const [
          InspectionItem(id: '1', inspectionId: 'insp-001', category: 'Piping', description: 'Flange Rating Verification', status: ChecklistStatus.pass),
          InspectionItem(id: '2', inspectionId: 'insp-001', category: 'Piping', description: 'Gasket Type Verification', status: ChecklistStatus.pass),
          InspectionItem(id: '3', inspectionId: 'insp-001', category: 'Piping', description: 'Bolt Torque & Tightening Pattern', status: ChecklistStatus.fail, comments: 'Missing torque paint mark'),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(inspection.items.length, 3);
      expect(inspection.passCount, 2);
      expect(inspection.failCount, 1);
      expect(inspection.completionPercentage, 1.0);
    });

    test('Step 15: Digital Cryptographic Signature & Audit Verification', () {
      final sigService = DigitalSignatureService();

      final sig = sigService.createSignature(
        signerName: 'Eng. Yadhukrishna (Lead Field Engineer)',
        signerTitle: 'Lead Piping Engineer',
        signerCompany: 'Saudi Aramco / EPC',
        signerRole: UserRole.leadEngineer,
        purpose: 'AS_BUILT_VERIFICATION',
        targetEntityId: 'dwg-p-402',
        strokePaths: [
          [const Offset(10, 20), const Offset(25, 30), const Offset(60, 45)],
        ],
      );

      expect(sig.signatureHash.isNotEmpty, isTrue);
      expect(sig.signerRole, UserRole.leadEngineer);
      expect(sig.targetEntityId, 'dwg-p-402');
    });

    test('Step 16: Equipment QR / Barcode Scanner Deep Link Resolution', () {
      const qrData = '{"tag":"P-102A","eqNo":"EQ-P-102A","name":"Centrifugal Hydrocarbon Export Pump","prj":"PRJ-SA-2026","dwg":"dwg-p-402","disc":"Pumps"}';

      final payload = EquipmentQrPayload.parse(qrData);

      expect(payload, isNotNull);
      expect(payload!.tagNumber, 'P-102A');
      expect(payload.equipmentNumber, 'EQ-P-102A');
      expect(payload.drawingId, 'dwg-p-402');
      expect(payload.discipline, 'Pumps');
    });

    test('Step 17: As-Built 6-Stage Lifecycle State Machine Progression', () {
      var stage = AsBuiltStage.issuedDrawing;

      expect(stage.displayName, contains('Issued Drawing'));
      stage = stage.nextStage!;
      expect(stage, AsBuiltStage.fieldMarkup);

      stage = stage.nextStage!;
      expect(stage, AsBuiltStage.fieldVerification);

      stage = stage.nextStage!;
      expect(stage, AsBuiltStage.engineerReview);

      stage = stage.nextStage!;
      expect(stage, AsBuiltStage.approved);

      stage = stage.nextStage!;
      expect(stage, AsBuiltStage.asBuiltRecord);
      expect(stage.nextStage, isNull);
    });

    test('Step 18-19: Markup Annotation Filtering & Multi-Discipline Search', () {
      final markups = [
        Markup(
          id: 'm-1',
          drawingId: 'dwg-p-402',
          pageNumber: 1,
          layer: DrawingLayer.markup,
          type: MarkupType.text,
          color: const Color(0xFFD32F2F),
          strokeWidth: 2.0,
          opacity: 1.0,
          points: [const Point2D(0.2, 0.2)],
          text: 'Piping Tie-in Spec 8"-HC-1002',
          createdBy: 'Eng. Field',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Markup(
          id: 'm-2',
          drawingId: 'dwg-p-402',
          pageNumber: 1,
          layer: DrawingLayer.issue,
          type: MarkupType.issuePin,
          color: const Color(0xFFFF0000),
          strokeWidth: 2.0,
          opacity: 1.0,
          points: [const Point2D(0.4, 0.4)],
          text: 'Electrical grounding clamp loose',
          createdBy: 'Eng. Field',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final filtered = markups.where((m) => m.text?.toLowerCase().contains('tie-in') ?? false).toList();
      expect(filtered.length, 1);
      expect(filtered.first.id, 'm-1');
    });

    test('Step 20: Crash Recovery & Session State Restoration', () async {
      final recovery = CrashRecoveryService();

      await recovery.autosaveDrawingSession(
        drawingId: 'dwg-p-402',
        pageNumber: 2,
        zoomScale: 2.5,
        panOffsetX: -150.0,
        panOffsetY: -80.0,
        activeTool: 'pen',
      );

      final restored = await recovery.restoreLastSession();

      expect(restored, isNotNull);
      expect(restored!.drawingId, 'dwg-p-402');
      expect(restored.pageNumber, 2);
      expect(restored.zoomScale, 2.5);
      expect(restored.panOffsetX, -150.0);
    });

    test('Step 21: SQLite PRAGMA Integrity & Diagnostic Diagnostics', () async {
      final diagService = DiagnosticsService();
      final report = await diagService.runDiagnostics();

      expect(report.isDatabaseHealthy, isTrue);
      expect(report.integrityCheckResult.toLowerCase(), 'ok');
      expect(report.tableCounts.containsKey('drawings'), isTrue);
      expect(report.tableCounts.containsKey('issues'), isTrue);
    });

    test('Step 22: Offline-to-Cloud Sync Engine & Tamper-Evident Audit Trail', () async {
      final db = await AppDatabase.instance.database;

      // 1. Enqueue offline sync mutation
      final syncItem = SyncQueueItem.create(
        entityType: 'AS_BUILT_DRAWING',
        entityId: 'dwg-p-402',
        operation: SyncOperation.update,
        payload: {
          'stage': 'asBuiltRecord',
          'certifiedBy': 'Lead Field Engineer',
        },
      );

      await db.insert(DatabaseTables.syncQueue, syncItem.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Log immutable audit entry
      await AuditLogger().log(
        action: 'AS_BUILT_CERTIFICATION',
        entityType: 'DRAWING',
        entityId: 'dwg-p-402',
        details: jsonEncode({'stage': 'AsBuiltRecord', 'signer': 'PE-ARAMCO-99824'}),
      );

      final pendingOps = await db.query(DatabaseTables.syncQueue, where: '${DatabaseTables.colSyncStatus} = ?', whereArgs: [SyncStatus.pending.name]);
      expect(pendingOps.length, greaterThanOrEqualTo(1));
      await db.delete(DatabaseTables.syncQueue, where: '${DatabaseTables.colId} = ?', whereArgs: [syncItem.id]);

      final auditLogs = await AuditLogger().getRecentLogs();
      expect(auditLogs.any((l) => l.action == 'AS_BUILT_CERTIFICATION'), isTrue);
    });
  });
}
