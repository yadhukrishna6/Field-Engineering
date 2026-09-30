import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseException;
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
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
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

      return await openDatabase(
        dbPath,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, st) {
      throw DatabaseException('Failed to initialize local SQLite database: $e', details: st);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Projects Table
    batch.execute('''
      CREATE TABLE ${DatabaseTables.projects} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colProjectNumber} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.colName} TEXT NOT NULL,
        ${DatabaseTables.colDescription} TEXT NOT NULL,
        ${DatabaseTables.colClient} TEXT NOT NULL,
        ${DatabaseTables.colLocation} TEXT NOT NULL,
        ${DatabaseTables.colStatus} TEXT NOT NULL,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // Drawings Table
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
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.colProjectId}) REFERENCES ${DatabaseTables.projects}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // Download Queue Table
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

    // Markups Table
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
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.colDrawingId}) REFERENCES ${DatabaseTables.drawings}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // Calibrations Table (Phase 3)
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

    // Measurements Table (Phase 3)
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
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.colDrawingId}) REFERENCES ${DatabaseTables.drawings}(${DatabaseTables.colId}) ON DELETE CASCADE
      )
    ''');

    // Material Takeoff (MTO / BOM) Table (Phase 3)
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
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // Saved Calculations Table (Phase 3)
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

    // Indexes for fast tablet search and filters
    batch.execute('CREATE INDEX IF NOT EXISTS idx_drawings_project_id ON ${DatabaseTables.drawings}(${DatabaseTables.colProjectId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_drawings_type ON ${DatabaseTables.drawings}(${DatabaseTables.colDrawingType});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_projects_status ON ${DatabaseTables.projects}(${DatabaseTables.colStatus});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_markups_drawing_page ON ${DatabaseTables.markups}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_markups_layer ON ${DatabaseTables.markups}(${DatabaseTables.colLayer});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_calibrations_dwg_page ON ${DatabaseTables.calibrations}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_measurements_dwg_page ON ${DatabaseTables.measurements}(${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_takeoff_project ON ${DatabaseTables.takeoffItems}(${DatabaseTables.colProjectId});');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_takeoff_drawing ON ${DatabaseTables.takeoffItems}(${DatabaseTables.colDrawingId});');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Create any missing tables on upgrade
    await db.execute('''
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
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');
    await db.execute('''
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
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');
    await db.execute('''
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
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');
    await db.execute('''
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
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL
      )
    ''');
    await db.execute('''
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
