import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/models/markup.dart';
import '../../../../core/errors/app_exceptions.dart';

class MarkupsLocalDataSource {
  final AppDatabase appDatabase;

  MarkupsLocalDataSource({required this.appDatabase});

  Future<List<Markup>> getMarkupsForDrawing(String drawingId, {int? pageNumber}) async {
    try {
      final db = await appDatabase.database;
      String whereClause = '${DatabaseTables.colDrawingId} = ?';
      List<dynamic> whereArgs = [drawingId];

      if (pageNumber != null) {
        whereClause += ' AND ${DatabaseTables.colPageNumber} = ?';
        whereArgs.add(pageNumber);
      }

      final results = await db.query(
        DatabaseTables.markups,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseTables.colCreatedAt} ASC',
      );

      return results.map((m) => Markup.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Error querying markups for drawing $drawingId: $e', details: st);
    }
  }

  Future<Markup> insertOrUpdateMarkup(Markup markup) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        DatabaseTables.markups,
        markup.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return markup;
    } catch (e, st) {
      throw DatabaseException('Error saving markup ${markup.id}: $e', details: st);
    }
  }

  Future<List<Markup>> saveMarkupsBatch(List<Markup> markups) async {
    if (markups.isEmpty) return [];
    try {
      final db = await appDatabase.database;
      final batch = db.batch();
      for (final markup in markups) {
        batch.insert(
          DatabaseTables.markups,
          markup.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return markups;
    } catch (e, st) {
      throw DatabaseException('Error saving markups batch: $e', details: st);
    }
  }

  Future<bool> deleteMarkup(String id) async {
    try {
      final db = await appDatabase.database;
      final count = await db.delete(
        DatabaseTables.markups,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error deleting markup $id: $e', details: st);
    }
  }

  Future<bool> deleteMarkupsForDrawing(String drawingId, {int? pageNumber}) async {
    try {
      final db = await appDatabase.database;
      String whereClause = '${DatabaseTables.colDrawingId} = ?';
      List<dynamic> whereArgs = [drawingId];

      if (pageNumber != null) {
        whereClause += ' AND ${DatabaseTables.colPageNumber} = ?';
        whereArgs.add(pageNumber);
      }

      final count = await db.delete(
        DatabaseTables.markups,
        where: whereClause,
        whereArgs: whereArgs,
      );
      return count >= 0;
    } catch (e, st) {
      throw DatabaseException('Error clearing markups for drawing $drawingId: $e', details: st);
    }
  }
}
