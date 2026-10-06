import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/repositories/markup_repository.dart';

class MarkupRepositoryImpl implements MarkupRepository {
  static final List<DrawingFile> _inMemoryDrawings = [];
  static final Map<String, PageMarkup> _inMemoryMarkups = {};

  Future<Database?> _getDb() async {
    try {
      return await AppDatabase.instance.database;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DrawingFile>> getDrawings() async {
    final db = await _getDb();
    if (db == null) return List.unmodifiable(_inMemoryDrawings);

    try {
      await _ensureTables(db);
      final maps = await db.query('drawing_files', orderBy: 'createdAt DESC');
      final list = maps.map((m) => DrawingFile.fromJson(m)).toList();
      _inMemoryDrawings.clear();
      _inMemoryDrawings.addAll(list);
      return list;
    } catch (e) {
      debugPrint('Error loading drawings from DB: $e');
      return List.unmodifiable(_inMemoryDrawings);
    }
  }

  @override
  Future<DrawingFile?> getDrawing(String id) async {
    final db = await _getDb();
    if (db == null) {
      return _inMemoryDrawings.where((d) => d.id == id).firstOrNull;
    }

    try {
      await _ensureTables(db);
      final maps = await db.query('drawing_files', where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return DrawingFile.fromJson(maps.first);
      }
    } catch (_) {}
    return _inMemoryDrawings.where((d) => d.id == id).firstOrNull;
  }

  @override
  Future<DrawingFile> saveDrawing(DrawingFile drawing) async {
    _inMemoryDrawings.removeWhere((d) => d.id == drawing.id);
    _inMemoryDrawings.insert(0, drawing);

    final db = await _getDb();
    if (db != null) {
      try {
        await _ensureTables(db);
        await db.insert(
          'drawing_files',
          drawing.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error persisting drawing: $e');
      }
    }
    return drawing;
  }

  @override
  Future<void> deleteDrawing(String id) async {
    _inMemoryDrawings.removeWhere((d) => d.id == id);
    _inMemoryMarkups.removeWhere((key, _) => key.startsWith('$id:'));

    final db = await _getDb();
    if (db != null) {
      try {
        await _ensureTables(db);
        await db.delete('drawing_files', where: 'id = ?', whereArgs: [id]);
        await db.delete('page_markups', where: 'drawingId = ?', whereArgs: [id]);
      } catch (_) {}
    }
  }

  @override
  Future<PageMarkup> getPageMarkup(String drawingId, int pageNumber) async {
    final key = '$drawingId:$pageNumber';
    final db = await _getDb();
    if (db == null) {
      return _inMemoryMarkups[key] ?? PageMarkup(drawingId: drawingId, pageNumber: pageNumber, strokes: const []);
    }

    try {
      await _ensureTables(db);
      final maps = await db.query(
        'page_markups',
        where: 'drawingId = ? AND pageNumber = ?',
        whereArgs: [drawingId, pageNumber],
      );
      if (maps.isNotEmpty) {
        final markup = PageMarkup.fromJson(maps.first);
        _inMemoryMarkups[key] = markup;
        return markup;
      }
    } catch (e) {
      debugPrint('Error getting page markup: $e');
    }

    return _inMemoryMarkups[key] ?? PageMarkup(drawingId: drawingId, pageNumber: pageNumber, strokes: const []);
  }

  @override
  Future<PageMarkup> savePageMarkup(PageMarkup markup) async {
    final key = '${markup.drawingId}:${markup.pageNumber}';
    _inMemoryMarkups[key] = markup;

    final db = await _getDb();
    if (db != null) {
      try {
        await _ensureTables(db);
        await db.insert(
          'page_markups',
          {
            'drawingId': markup.drawingId,
            'pageNumber': markup.pageNumber,
            'payload': markup.toPayloadJson(),
            'version': markup.version,
            'updatedAt': (markup.updatedAt ?? DateTime.now()).toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error persisting page markup: $e');
      }
    }
    return markup;
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS drawing_files (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        fileType TEXT NOT NULL,
        pageCount INTEGER NOT NULL,
        localPath TEXT NOT NULL,
        fileUrl TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS page_markups (
        drawingId TEXT NOT NULL,
        pageNumber INTEGER NOT NULL,
        payload TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        updatedAt TEXT NOT NULL,
        PRIMARY KEY (drawingId, pageNumber)
      )
    ''');
  }
}
