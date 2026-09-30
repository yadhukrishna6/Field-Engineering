import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/models/drawing.dart';
import '../../domain/models/drawing_type.dart';
import '../../../../core/errors/app_exceptions.dart';

class DrawingsLocalDataSource {
  final AppDatabase appDatabase;

  DrawingsLocalDataSource({required this.appDatabase});

  Future<List<Drawing>> getDrawingsForProject(
    String projectId, {
    String? searchQuery,
    DrawingType? typeFilter,
    String? revisionFilter,
  }) async {
    try {
      final db = await appDatabase.database;
      String whereClause = '${DatabaseTables.colProjectId} = ?';
      List<dynamic> whereArgs = [projectId];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        whereClause += ' AND (${DatabaseTables.colTitle} LIKE ? OR ${DatabaseTables.colDrawingNumber} LIKE ?)';
        final queryParam = '%${searchQuery.trim()}%';
        whereArgs.addAll([queryParam, queryParam]);
      }

      if (typeFilter != null) {
        whereClause += ' AND ${DatabaseTables.colDrawingType} = ?';
        whereArgs.add(typeFilter.name);
      }

      if (revisionFilter != null && revisionFilter.trim().isNotEmpty && revisionFilter != 'All') {
        whereClause += ' AND ${DatabaseTables.colRevision} = ?';
        whereArgs.add(revisionFilter.trim());
      }

      final results = await db.query(
        DatabaseTables.drawings,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseTables.colDrawingNumber} ASC',
      );

      return results.map((e) => Drawing.fromMap(e)).toList();
    } catch (e, st) {
      throw DatabaseException('Error querying drawings for project $projectId: $e', details: st);
    }
  }

  Future<List<Drawing>> getAllDrawings({
    String? searchQuery,
    DrawingType? typeFilter,
    bool? downloadedOnly,
  }) async {
    try {
      final db = await appDatabase.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        whereClause += '(${DatabaseTables.colTitle} LIKE ? OR ${DatabaseTables.colDrawingNumber} LIKE ?)';
        final queryParam = '%${searchQuery.trim()}%';
        whereArgs.addAll([queryParam, queryParam]);
      }

      if (typeFilter != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '${DatabaseTables.colDrawingType} = ?';
        whereArgs.add(typeFilter.name);
      }

      if (downloadedOnly == true) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '${DatabaseTables.colDownloaded} = 1';
      }

      final results = await db.query(
        DatabaseTables.drawings,
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: '${DatabaseTables.colUpdatedAt} DESC',
      );

      return results.map((e) => Drawing.fromMap(e)).toList();
    } catch (e, st) {
      throw DatabaseException('Error querying all drawings: $e', details: st);
    }
  }

  Future<Drawing?> getDrawingById(String id) async {
    try {
      final db = await appDatabase.database;
      final results = await db.query(
        DatabaseTables.drawings,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return Drawing.fromMap(results.first);
    } catch (e, st) {
      throw DatabaseException('Error querying drawing by id $id: $e', details: st);
    }
  }

  Future<Drawing> insertDrawing(Drawing drawing) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        DatabaseTables.drawings,
        drawing.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return drawing;
    } catch (e, st) {
      throw DatabaseException('Error inserting drawing: $e', details: st);
    }
  }

  Future<Drawing> updateDrawing(Drawing drawing) async {
    try {
      final db = await appDatabase.database;
      await db.update(
        DatabaseTables.drawings,
        drawing.toMap(),
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [drawing.id],
      );
      return drawing;
    } catch (e, st) {
      throw DatabaseException('Error updating drawing: $e', details: st);
    }
  }

  Future<bool> deleteDrawing(String id) async {
    try {
      final db = await appDatabase.database;
      final count = await db.delete(
        DatabaseTables.drawings,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error deleting drawing $id: $e', details: st);
    }
  }

  Future<void> updateDownloadedStatus(String id, bool downloaded) async {
    try {
      final db = await appDatabase.database;
      await db.update(
        DatabaseTables.drawings,
        {
          DatabaseTables.colDownloaded: downloaded ? 1 : 0,
          DatabaseTables.colUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw DatabaseException('Error updating download status for drawing $id: $e', details: st);
    }
  }
}
