import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'database_tables.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _db;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;
    if (kIsWeb) {
      dbPath = 'field_drawing_markup.db';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, 'field_drawing_markup.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Drawings Metadata Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.drawings} (
        ${DatabaseTables.colId} TEXT PRIMARY KEY,
        ${DatabaseTables.colName} TEXT NOT NULL,
        ${DatabaseTables.colFileType} TEXT NOT NULL,
        ${DatabaseTables.colPageCount} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colLocalPath} TEXT NOT NULL,
        ${DatabaseTables.colFileUrl} TEXT,
        ${DatabaseTables.colCreatedAt} TEXT NOT NULL
      )
    ''');

    // 2. Page Markups Table (Vector Strokes & Text Labels JSON payload with optimistic version)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.pageMarkups} (
        ${DatabaseTables.colDrawingId} TEXT NOT NULL,
        ${DatabaseTables.colPageNumber} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colPayload} TEXT NOT NULL,
        ${DatabaseTables.colVersion} INTEGER NOT NULL DEFAULT 1,
        ${DatabaseTables.colUpdatedAt} TEXT NOT NULL,
        PRIMARY KEY (${DatabaseTables.colDrawingId}, ${DatabaseTables.colPageNumber})
      )
    ''');
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
