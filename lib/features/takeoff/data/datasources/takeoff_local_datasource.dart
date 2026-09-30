import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/models/takeoff_item.dart';
import '../../../../core/errors/app_exceptions.dart';

class TakeoffLocalDataSource {
  final AppDatabase appDatabase;

  TakeoffLocalDataSource({required this.appDatabase});

  Future<List<TakeoffItem>> getItemsForProject(
    String? projectId, {
    String? drawingId,
    TakeoffItemType? itemType,
    String? searchQuery,
  }) async {
    try {
      final db = await appDatabase.database;
      String? where;
      List<dynamic> args = [];

      if (projectId != null && projectId.isNotEmpty) {
        where = '${DatabaseTables.colProjectId} = ?';
        args.add(projectId);
      }

      if (drawingId != null && drawingId.isNotEmpty) {
        where = where != null ? '$where AND ${DatabaseTables.colDrawingId} = ?' : '${DatabaseTables.colDrawingId} = ?';
        args.add(drawingId);
      }

      if (itemType != null) {
        where = where != null ? '$where AND ${DatabaseTables.colItemType} = ?' : '${DatabaseTables.colItemType} = ?';
        args.add(itemType.name);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final searchClause = '(${DatabaseTables.colItemName} LIKE ? OR ${DatabaseTables.colSpecification} LIKE ? OR ${DatabaseTables.colSize} LIKE ? OR ${DatabaseTables.colNotes} LIKE ?)';
        where = where != null ? '$where AND $searchClause' : searchClause;
        final q = '%${searchQuery.trim()}%';
        args.addAll([q, q, q, q]);
      }

      final results = await db.query(
        DatabaseTables.takeoffItems,
        where: where,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: '${DatabaseTables.colItemType} ASC, ${DatabaseTables.colCreatedAt} DESC',
      );

      return results.map((m) => TakeoffItem.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Error querying takeoff items: $e', details: st);
    }
  }

  Future<TakeoffItem> saveItem(TakeoffItem item) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        DatabaseTables.takeoffItems,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return item;
    } catch (e, st) {
      throw DatabaseException('Error saving takeoff item: $e', details: st);
    }
  }

  Future<List<TakeoffItem>> saveItemsBatch(List<TakeoffItem> items) async {
    try {
      final db = await appDatabase.database;
      final batch = db.batch();
      for (final item in items) {
        batch.insert(
          DatabaseTables.takeoffItems,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return items;
    } catch (e, st) {
      throw DatabaseException('Error batch saving takeoff items: $e', details: st);
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      final db = await appDatabase.database;
      final count = await db.delete(
        DatabaseTables.takeoffItems,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error deleting takeoff item: $e', details: st);
    }
  }

  Future<bool> deleteItemsForDrawing(String drawingId) async {
    try {
      final db = await appDatabase.database;
      final count = await db.delete(
        DatabaseTables.takeoffItems,
        where: '${DatabaseTables.colDrawingId} = ?',
        whereArgs: [drawingId],
      );
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error clearing takeoff items: $e', details: st);
    }
  }
}
