import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/models/equipment_item.dart';

class EquipmentLocalDataSource {
  final AppDatabase _appDatabase;

  EquipmentLocalDataSource({required AppDatabase appDatabase}) : _appDatabase = appDatabase;

  Future<void> insertEquipment(EquipmentItem item) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DatabaseTables.equipment,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw DatabaseException('Failed to insert equipment: $e', details: st);
    }
  }

  Future<void> updateEquipment(EquipmentItem item) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DatabaseTables.equipment,
        item.toMap(),
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [item.id],
      );
    } catch (e, st) {
      throw DatabaseException('Failed to update equipment: $e', details: st);
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        DatabaseTables.equipment,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw DatabaseException('Failed to delete equipment: $e', details: st);
    }
  }

  Future<EquipmentItem?> getEquipmentById(String id) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.equipment,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return EquipmentItem.fromMap(results.first);
    } catch (e, st) {
      throw DatabaseException('Failed to get equipment by id: $e', details: st);
    }
  }

  Future<EquipmentItem?> getEquipmentByTagNumber(String tagNumber) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.equipment,
        where: '${DatabaseTables.colTagNumber} = ?',
        whereArgs: [tagNumber],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return EquipmentItem.fromMap(results.first);
    } catch (e, st) {
      throw DatabaseException('Failed to get equipment by tag: $e', details: st);
    }
  }

  Future<List<EquipmentItem>> getEquipmentByProject(String projectId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.equipment,
        where: '${DatabaseTables.colProjectId} = ?',
        whereArgs: [projectId],
        orderBy: '${DatabaseTables.colTagNumber} ASC',
      );
      return results.map((m) => EquipmentItem.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get project equipment: $e', details: st);
    }
  }

  Future<List<EquipmentItem>> getEquipmentByDrawing(String drawingId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.equipment,
        where: '${DatabaseTables.colDrawingId} = ?',
        whereArgs: [drawingId],
        orderBy: '${DatabaseTables.colTagNumber} ASC',
      );
      return results.map((m) => EquipmentItem.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get drawing equipment: $e', details: st);
    }
  }

  Future<List<EquipmentItem>> getAllEquipment() async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.equipment,
        orderBy: '${DatabaseTables.colTagNumber} ASC',
      );
      return results.map((m) => EquipmentItem.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get all equipment: $e', details: st);
    }
  }
}
