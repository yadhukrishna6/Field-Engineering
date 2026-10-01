import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseException;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'database_tables.dart';
import '../errors/app_exceptions.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    try {
      final DatabaseFactory factory;
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWebNoWebWorker;
        factory = databaseFactoryFfiWebNoWebWorker;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        factory = databaseFactoryFfi;
      } else {
        factory = databaseFactory;
      }

      String dbPath;
      if (kIsWeb) {
        dbPath = 'field_engineering.db';
      } else {
        Directory appDocDir;
        try {
          appDocDir = await getApplicationDocumentsDirectory();
        } catch (e) {
          appDocDir = Directory(p.join(Directory.current.path, '.field_engineering_data'));
          if (!await appDocDir.exists()) {
            await appDocDir.create(recursive: true);
          }
        }
        dbPath = p.join(appDocDir.path, 'field_engineering_v1.db');
      }

      if (kIsWeb) {
        return await factory.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: 4,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          ),
        ).timeout(const Duration(milliseconds: 500), onTimeout: () {
          return factory.openDatabase(inMemoryDatabasePath);
        });
      }

      return await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } catch (e, st) {
      throw DatabaseException('Failed to initialize local SQLite database: $e', details: st);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Projects Table
    batch.execute('''
      CREATE TABLE ${DatabaseTables.projects} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectNumber} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.colName} TEXT NOT NULL,
        ${DatabaseTables.colDescription} TEXT NOT NULL,
        ${DatabaseTables.colClient} TEXT NOT NULL,
        ${DatabaseTables.colLocation} TEXT NOT NULL,
        ${DatabaseTables.colStatus} TEXT NOT NULL,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // 2. Drawings Table
    batch.execute('''
      CREATE TABLE ${DatabaseTables.drawings} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colDrawingNumber} TEXT NOT NULL,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colDrawingType} TEXT NOT NULL,
        ${DatabaseTables.colRevision} TEXT NOT NULL,
        ${DatabaseTables.colFilePath} TEXT NOT NULL,
        ${DatabaseTables.colThumbnailPath} TEXT,
        ${DatabaseTables.colPageCount} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colFileSize} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseTables.colDownloaded} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.colProjectId}) REFERENCES ${DatabaseTables.projects}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // 3. Download Queue Table
    batch.execute('''
      CREATE TABLE ${DatabaseTables.downloadQueue} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colProgress} REAL NOT NULL DEFAULT 0.0,
        ${DatabaseTables.colQueueStatus} TEXT NOT NULL,
        ${DatabaseTables.colFileSize} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseTables.colErrorMessage} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    // 4. Markups Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.markups} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colDrawingId} TEXT NOT NULL,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colLayer} TEXT NOT NULL DEFAULT 'markup',
        ${DatabaseTables.colMarkupType} TEXT NOT NULL,
        ${DatabaseTables.colColor} INTEGER NOT NULL,
        ${DatabaseTables.colFillColor} INTEGER,
        ${DatabaseTables.colStrokeWidth} REAL NOT NULL DEFAULT 2.0,
        ${DatabaseTables.colOpacity} REAL NOT NULL DEFAULT 1.0,
        ${DatabaseTables.colGeometryData} TEXT NOT NULL,
        ${DatabaseTables.colText} TEXT,
        ${DatabaseTables.colMetadata} TEXT,
        ${DatabaseTables.colCreatedBy} TEXT NOT NULL,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.colDrawingId}) REFERENCES ${DatabaseTables.drawings}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // 5. Calibrations Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.calibrations} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colDrawingId} TEXT NOT NULL,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colPoint1X} REAL NOT NULL,
        ${DatabaseTables.colPoint1Y} REAL NOT NULL,
        ${DatabaseTables.colPoint2X} REAL NOT NULL,
        ${DatabaseTables.colPoint2Y} REAL NOT NULL,
        ${DatabaseTables.colKnownDistance} REAL NOT NULL,
        ${DatabaseTables.colScaleUnit} TEXT NOT NULL,
        ${DatabaseTables.colScaleFactor} REAL NOT NULL,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.colDrawingId}) REFERENCES ${DatabaseTables.drawings}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // 6. Measurements Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.measurements} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colDrawingId} TEXT NOT NULL,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colMeasurementType} TEXT NOT NULL,
        ${DatabaseTables.colPointsData} TEXT NOT NULL,
        ${DatabaseTables.colCalculatedValue} REAL NOT NULL,
        ${DatabaseTables.colUnit} TEXT NOT NULL,
        ${DatabaseTables.colCalibrationId} TEXT,
        ${DatabaseTables.colLabel} TEXT,
        ${DatabaseTables.colColor} INTEGER,
        ${DatabaseTables.colMetadata} TEXT,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.colDrawingId}) REFERENCES ${DatabaseTables.drawings}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // 7. Material Takeoff (MTO) Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.takeoffItems} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colPageNumber} INTEGER DEFAULT 1,
        ${DatabaseTables.colItemType} TEXT NOT NULL,
        ${DatabaseTables.colItemName} TEXT NOT NULL,
        ${DatabaseTables.colSpecification} TEXT,
        ${DatabaseTables.colSize} TEXT,
        ${DatabaseTables.colQuantity} REAL NOT NULL DEFAULT 1.0,
        ${DatabaseTables.colUnit} TEXT NOT NULL DEFAULT 'pcs',
        ${DatabaseTables.colUnitWeight} REAL DEFAULT 0.0,
        ${DatabaseTables.colUnitCost} REAL DEFAULT 0.0,
        ${DatabaseTables.colNotes} TEXT,
        ${DatabaseTables.colLinkedCountTag} TEXT,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // 8. Saved Calculations Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.savedCalculations} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colCalcType} TEXT NOT NULL,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colInputsJson} TEXT NOT NULL,
        ${DatabaseTables.colResultsJson} TEXT NOT NULL,
        ${DatabaseTables.colEngineerNotes} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    // 9. Phase 4: Issues Table (Punch List & Field Non-Conformances)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.issues} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colPositionX} REAL,
        ${DatabaseTables.colPositionY} REAL,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colDescription} TEXT NOT NULL,
        ${DatabaseTables.colCategory} TEXT NOT NULL DEFAULT 'Piping',
        ${DatabaseTables.colPriority} TEXT NOT NULL DEFAULT 'Medium',
        ${DatabaseTables.colStatus} TEXT NOT NULL DEFAULT 'Open',
        ${DatabaseTables.colAssignedTo} TEXT,
        ${DatabaseTables.colCreatedBy} TEXT NOT NULL,
        ${DatabaseTables.colDueDate} TEXT,
        ${DatabaseTables.colEquipmentId} TEXT,
        ${DatabaseTables.colInspectionId} TEXT,
        ${DatabaseTables.colLatitude} REAL,
        ${DatabaseTables.colLongitude} REAL,
        ${DatabaseTables.colGpsAccuracy} REAL,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // 10. Phase 4: Photos / Media Attachments Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.photos} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colFilePath} TEXT NOT NULL,
        ${DatabaseTables.colThumbnailPath} TEXT,
        ${DatabaseTables.colTitle} TEXT,
        ${DatabaseTables.colCaption} TEXT,
        ${DatabaseTables.colLatitude} REAL,
        ${DatabaseTables.colLongitude} REAL,
        ${DatabaseTables.colGpsAccuracy} REAL,
        ${DatabaseTables.colGpsTimestamp} TEXT,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colPositionX} REAL,
        ${DatabaseTables.colPositionY} REAL,
        ${DatabaseTables.colIssueId} TEXT,
        ${DatabaseTables.colInspectionId} TEXT,
        ${DatabaseTables.colEquipmentId} TEXT,
        ${DatabaseTables.colFileSize} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    // 11. Phase 4: Voice Notes Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.voiceNotes} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colFilePath} TEXT NOT NULL,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colDurationSeconds} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colPositionX} REAL,
        ${DatabaseTables.colPositionY} REAL,
        ${DatabaseTables.colIssueId} TEXT,
        ${DatabaseTables.colInspectionId} TEXT,
        ${DatabaseTables.colCreatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    // 12. Phase 4: Inspections Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.inspections} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colEquipmentId} TEXT,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colInspectionType} TEXT NOT NULL DEFAULT 'Piping',
        ${DatabaseTables.colStatus} TEXT NOT NULL DEFAULT 'Draft',
        ${DatabaseTables.colInspectorName} TEXT NOT NULL,
        ${DatabaseTables.colInspectorSignaturePath} TEXT,
        ${DatabaseTables.colClientSignaturePath} TEXT,
        ${DatabaseTables.colInspectionDate} TEXT NOT NULL,
        ${DatabaseTables.colSummaryNotes} TEXT,
        ${DatabaseTables.colLatitude} REAL,
        ${DatabaseTables.colLongitude} REAL,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // 13. Phase 4: Inspection Items Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.inspectionItems} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colInspectionId} TEXT NOT NULL,
        ${DatabaseTables.colCategory} TEXT NOT NULL,
        ${DatabaseTables.colDescription} TEXT NOT NULL,
        ${DatabaseTables.colStatus} TEXT NOT NULL DEFAULT 'PENDING',
        ${DatabaseTables.colComments} TEXT,
        ${DatabaseTables.colPhotoIdsJson} TEXT,
        ${DatabaseTables.colOrderIndex} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DatabaseTables.colInspectionId}) REFERENCES ${DatabaseTables.inspections}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // 14. Phase 4: Equipment Master Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.equipment} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colEquipmentNumber} TEXT NOT NULL,
        ${DatabaseTables.colTagNumber} TEXT NOT NULL,
        ${DatabaseTables.colName} TEXT NOT NULL,
        ${DatabaseTables.colDrawingType} TEXT NOT NULL DEFAULT 'Pump',
        ${DatabaseTables.colLocation} TEXT,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colNotes} TEXT,
        ${DatabaseTables.colPhotoPath} TEXT,
        ${DatabaseTables.colLatitude} REAL,
        ${DatabaseTables.colLongitude} REAL,
        ${DatabaseTables.colStatus} TEXT NOT NULL DEFAULT 'Operational',
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // 15. Phase 5: Sync Queue Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.syncQueue} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colEntityType} TEXT NOT NULL,
        ${DatabaseTables.colEntityId} TEXT NOT NULL,
        ${DatabaseTables.colOperation} TEXT NOT NULL,
        ${DatabaseTables.colPayloadJson} TEXT,
        ${DatabaseTables.colFilePath} TEXT,
        ${DatabaseTables.colRetryCount} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseTables.colSyncStatus} TEXT NOT NULL DEFAULT 'pending',
        ${DatabaseTables.colErrorMessage} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // 16. Phase 5: Drawing Revisions Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.revisions} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colDrawingId} TEXT NOT NULL,
        ${DatabaseTables.colRevisionNumber} TEXT NOT NULL,
        ${DatabaseTables.colRevisionDescription} TEXT NOT NULL,
        ${DatabaseTables.colUploadedBy} TEXT NOT NULL,
        ${DatabaseTables.colUploadedAt} TEXT NOT NULL,
        ${DatabaseTables.colFilePath} TEXT NOT NULL,
        ${DatabaseTables.colRevisionStatus} TEXT NOT NULL DEFAULT 'Approved',
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.colDrawingId}) REFERENCES ${DatabaseTables.drawings}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // 17. Phase 5: Audit Logs Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.auditLogs} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colAction} TEXT NOT NULL,
        ${DatabaseTables.colUserEmail} TEXT NOT NULL,
        ${DatabaseTables.colUserRole} TEXT NOT NULL,
        ${DatabaseTables.colEntityType} TEXT NOT NULL,
        ${DatabaseTables.colEntityId} TEXT,
        ${DatabaseTables.colDetails} TEXT,
        ${DatabaseTables.colIpAddress} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    // 18. Phase 5: Conflicts Table
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.conflicts} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colEntityType} TEXT NOT NULL,
        ${DatabaseTables.colEntityId} TEXT NOT NULL,
        ${DatabaseTables.colLocalPayloadJson} TEXT NOT NULL,
        ${DatabaseTables.colServerPayloadJson} TEXT NOT NULL,
        ${DatabaseTables.colLocalVersion} INTEGER NOT NULL,
        ${DatabaseTables.colServerVersion} INTEGER NOT NULL,
        ${DatabaseTables.colResolutionStatus} TEXT NOT NULL DEFAULT 'pending',
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // Fast Lookup Indexes
    batch.execute('CREATE INDEX IF NOT EXISTS idx_drawings_project_id ON ${DatabaseTables.drawings}(${DatabaseTables.colProjectId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_drawings_type ON ${DatabaseTables.drawings}(${DatabaseTables.colDrawingType});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_projects_status ON ${DatabaseTables.projects}(${DatabaseTables.colStatus});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_markups_drawing_page ON ${DatabaseTables.markups}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_markups_layer ON ${DatabaseTables.markups}(${DatabaseTables.colLayer});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_calibrations_dwg_page ON ${DatabaseTables.calibrations}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_measurements_dwg_page ON ${DatabaseTables.measurements}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_takeoff_project ON ${DatabaseTables.takeoffItems}(${DatabaseTables.colProjectId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_takeoff_drawing ON ${DatabaseTables.takeoffItems}(${DatabaseTables.colDrawingId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_issues_drawing_page ON ${DatabaseTables.issues}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_issues_project ON ${DatabaseTables.issues}(${DatabaseTables.colProjectId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_photos_drawing_page ON ${DatabaseTables.photos}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_photos_issue ON ${DatabaseTables.photos}(${DatabaseTables.colIssueId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_photos_inspection ON ${DatabaseTables.photos}(${DatabaseTables.colInspectionId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_voice_drawing_page ON ${DatabaseTables.voiceNotes}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_inspections_project ON ${DatabaseTables.inspections}(${DatabaseTables.colProjectId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_inspection_items_inspection ON ${DatabaseTables.inspectionItems}(${DatabaseTables.colInspectionId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_equipment_project ON ${DatabaseTables.equipment}(${DatabaseTables.colProjectId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON ${DatabaseTables.syncQueue}(${DatabaseTables.colSyncStatus});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_revisions_drawing ON ${DatabaseTables.revisions}(${DatabaseTables.colDrawingId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON ${DatabaseTables.auditLogs}(${DatabaseTables.colCreatedAt});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_conflicts_status ON ${DatabaseTables.conflicts}(${DatabaseTables.colResolutionStatus});');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Phase 4 Tables Check
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.issues} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colPositionX} REAL,
        ${DatabaseTables.colPositionY} REAL,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colDescription} TEXT NOT NULL,
        ${DatabaseTables.colCategory} TEXT NOT NULL DEFAULT 'Piping',
        ${DatabaseTables.colPriority} TEXT NOT NULL DEFAULT 'Medium',
        ${DatabaseTables.colStatus} TEXT NOT NULL DEFAULT 'Open',
        ${DatabaseTables.colAssignedTo} TEXT,
        ${DatabaseTables.colCreatedBy} TEXT NOT NULL,
        ${DatabaseTables.colDueDate} TEXT,
        ${DatabaseTables.colEquipmentId} TEXT,
        ${DatabaseTables.colInspectionId} TEXT,
        ${DatabaseTables.colLatitude} REAL,
        ${DatabaseTables.colLongitude} REAL,
        ${DatabaseTables.colGpsAccuracy} REAL,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.photos} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colFilePath} TEXT NOT NULL,
        ${DatabaseTables.colThumbnailPath} TEXT,
        ${DatabaseTables.colTitle} TEXT,
        ${DatabaseTables.colCaption} TEXT,
        ${DatabaseTables.colLatitude} REAL,
        ${DatabaseTables.colLongitude} REAL,
        ${DatabaseTables.colGpsAccuracy} REAL,
        ${DatabaseTables.colGpsTimestamp} TEXT,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colPositionX} REAL,
        ${DatabaseTables.colPositionY} REAL,
        ${DatabaseTables.colIssueId} TEXT,
        ${DatabaseTables.colInspectionId} TEXT,
        ${DatabaseTables.colEquipmentId} TEXT,
        ${DatabaseTables.colFileSize} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.voiceNotes} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colFilePath} TEXT NOT NULL,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colDurationSeconds} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colPositionX} REAL,
        ${DatabaseTables.colPositionY} REAL,
        ${DatabaseTables.colIssueId} TEXT,
        ${DatabaseTables.colInspectionId} TEXT,
        ${DatabaseTables.colCreatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.inspections} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colEquipmentId} TEXT,
        ${DatabaseTables.colTitle} TEXT NOT NULL,
        ${DatabaseTables.colInspectionType} TEXT NOT NULL DEFAULT 'Piping',
        ${DatabaseTables.colStatus} TEXT NOT NULL DEFAULT 'Draft',
        ${DatabaseTables.colInspectorName} TEXT NOT NULL,
        ${DatabaseTables.colInspectorSignaturePath} TEXT,
        ${DatabaseTables.colClientSignaturePath} TEXT,
        ${DatabaseTables.colInspectionDate} TEXT NOT NULL,
        ${DatabaseTables.colSummaryNotes} TEXT,
        ${DatabaseTables.colLatitude} REAL,
        ${DatabaseTables.colLongitude} REAL,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.inspectionItems} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colInspectionId} TEXT NOT NULL,
        ${DatabaseTables.colCategory} TEXT NOT NULL,
        ${DatabaseTables.colDescription} TEXT NOT NULL,
        ${DatabaseTables.colStatus} TEXT NOT NULL DEFAULT 'PENDING',
        ${DatabaseTables.colComments} TEXT,
        ${DatabaseTables.colPhotoIdsJson} TEXT,
        ${DatabaseTables.colOrderIndex} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DatabaseTables.colInspectionId}) REFERENCES ${DatabaseTables.inspections}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.equipment} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectId} TEXT NOT NULL,
        ${DatabaseTables.colEquipmentNumber} TEXT NOT NULL,
        ${DatabaseTables.colTagNumber} TEXT NOT NULL,
        ${DatabaseTables.colName} TEXT NOT NULL,
        ${DatabaseTables.colDrawingType} TEXT NOT NULL DEFAULT 'Pump',
        ${DatabaseTables.colLocation} TEXT,
        ${DatabaseTables.colDrawingId} TEXT,
        ${DatabaseTables.colNotes} TEXT,
        ${DatabaseTables.colPhotoPath} TEXT,
        ${DatabaseTables.colLatitude} REAL,
        ${DatabaseTables.colLongitude} REAL,
        ${DatabaseTables.colStatus} TEXT NOT NULL DEFAULT 'Operational',
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedBy} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // Phase 5: Tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.syncQueue} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colEntityType} TEXT NOT NULL,
        ${DatabaseTables.colEntityId} TEXT NOT NULL,
        ${DatabaseTables.colOperation} TEXT NOT NULL,
        ${DatabaseTables.colPayloadJson} TEXT,
        ${DatabaseTables.colFilePath} TEXT,
        ${DatabaseTables.colRetryCount} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseTables.colSyncStatus} TEXT NOT NULL DEFAULT 'pending',
        ${DatabaseTables.colErrorMessage} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.revisions} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colDrawingId} TEXT NOT NULL,
        ${DatabaseTables.colRevisionNumber} TEXT NOT NULL,
        ${DatabaseTables.colRevisionDescription} TEXT NOT NULL,
        ${DatabaseTables.colUploadedBy} TEXT NOT NULL,
        ${DatabaseTables.colUploadedAt} TEXT NOT NULL,
        ${DatabaseTables.colFilePath} TEXT NOT NULL,
        ${DatabaseTables.colRevisionStatus} TEXT NOT NULL DEFAULT 'Approved',
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.auditLogs} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colAction} TEXT NOT NULL,
        ${DatabaseTables.colUserEmail} TEXT NOT NULL,
        ${DatabaseTables.colUserRole} TEXT NOT NULL,
        ${DatabaseTables.colEntityType} TEXT NOT NULL,
        ${DatabaseTables.colEntityId} TEXT,
        ${DatabaseTables.colDetails} TEXT,
        ${DatabaseTables.colIpAddress} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.conflicts} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colEntityType} TEXT NOT NULL,
        ${DatabaseTables.colEntityId} TEXT NOT NULL,
        ${DatabaseTables.colLocalPayloadJson} TEXT NOT NULL,
        ${DatabaseTables.colServerPayloadJson} TEXT NOT NULL,
        ${DatabaseTables.colLocalVersion} INTEGER NOT NULL,
        ${DatabaseTables.colServerVersion} INTEGER NOT NULL,
        ${DatabaseTables.colResolutionStatus} TEXT NOT NULL DEFAULT 'pending',
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');
  }

  Future<int> getDatabaseSizeInBytes() async {
    try {
      if (kIsWeb) return 0;
      final db = await database;
      final file = File(db.path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
