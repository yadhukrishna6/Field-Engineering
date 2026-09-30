import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/models/inspection.dart';
import '../../domain/models/inspection_item.dart';

class InspectionsLocalDataSource {
  final AppDatabase _appDatabase;

  InspectionsLocalDataSource({required AppDatabase appDatabase}) : _appDatabase = appDatabase;

  Future<void> insertInspection(Inspection inspection) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.insert(
          DatabaseTables.inspections,
          inspection.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Delete previous items for this inspection ID to prevent duplicate items
        await txn.delete(
          DatabaseTables.inspectionItems,
          where: '${DatabaseTables.colInspectionId} = ?',
          whereArgs: [inspection.id],
        );

        // Insert items
        for (final item in inspection.items) {
          await txn.insert(
            DatabaseTables.inspectionItems,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e, st) {
      throw DatabaseException('Failed to insert inspection: $e', details: st);
    }
  }

  Future<void> updateInspection(Inspection inspection) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.update(
          DatabaseTables.inspections,
          inspection.toMap(),
          where: '${DatabaseTables.colId} = ?',
          whereArgs: [inspection.id],
        );

        await txn.delete(
          DatabaseTables.inspectionItems,
          where: '${DatabaseTables.colInspectionId} = ?',
          whereArgs: [inspection.id],
        );

        for (final item in inspection.items) {
          await txn.insert(
            DatabaseTables.inspectionItems,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e, st) {
      throw DatabaseException('Failed to update inspection: $e', details: st);
    }
  }

  Future<void> updateInspectionItem(InspectionItem item) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DatabaseTables.inspectionItems,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw DatabaseException('Failed to update inspection item: $e', details: st);
    }
  }

  Future<void> deleteInspection(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.delete(
          DatabaseTables.inspectionItems,
          where: '${DatabaseTables.colInspectionId} = ?',
          whereArgs: [id],
        );
        await txn.delete(
          DatabaseTables.inspections,
          where: '${DatabaseTables.colId} = ?',
          whereArgs: [id],
        );
      });
    } catch (e, st) {
      throw DatabaseException('Failed to delete inspection: $e', details: st);
    }
  }

  Future<List<InspectionItem>> getInspectionItems(String inspectionId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.inspectionItems,
        where: '${DatabaseTables.colInspectionId} = ?',
        whereArgs: [inspectionId],
        orderBy: '${DatabaseTables.colOrderIndex} ASC',
      );
      return results.map((m) => InspectionItem.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get inspection items: $e', details: st);
    }
  }

  Future<Inspection?> getInspectionById(String id) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.inspections,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (results.isEmpty) return null;

      final items = await getInspectionItems(id);
      return Inspection.fromMap(results.first, items: items);
    } catch (e, st) {
      throw DatabaseException('Failed to get inspection: $e', details: st);
    }
  }

  Future<List<Inspection>> getInspectionsByProject(String projectId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.inspections,
        where: '${DatabaseTables.colProjectId} = ?',
        whereArgs: [projectId],
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );

      final List<Inspection> inspections = [];
      for (final r in results) {
        final id = r['id'] as String;
        final items = await getInspectionItems(id);
        inspections.add(Inspection.fromMap(r, items: items));
      }
      return inspections;
    } catch (e, st) {
      throw DatabaseException('Failed to get project inspections: $e', details: st);
    }
  }

  Future<List<Inspection>> getAllInspections() async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.inspections,
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );

      final List<Inspection> inspections = [];
      for (final r in results) {
        final id = r['id'] as String;
        final items = await getInspectionItems(id);
        inspections.add(Inspection.fromMap(r, items: items));
      }
      return inspections;
    } catch (e, st) {
      throw DatabaseException('Failed to get all inspections: $e', details: st);
    }
  }
}
