import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/models/measurement.dart';
import '../../domain/models/drawing_calibration.dart';
import '../../../../core/errors/app_exceptions.dart';

class MeasurementsLocalDataSource {
  final AppDatabase appDatabase;

  MeasurementsLocalDataSource({required this.appDatabase});

  // --- Calibration Operations ---

  Future<DrawingCalibration?> getCalibration(String drawingId, {int pageNumber = 1}) async {
    try {
      final db = await appDatabase.database;
      final results = await db.query(
        DatabaseTables.calibrations,
        where: '${DatabaseTables.colDrawingId} = ? AND ${DatabaseTables.colPageNumber} = ?',
        whereArgs: [drawingId, pageNumber],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return DrawingCalibration.fromMap(results.first);
    } catch (e, st) {
      throw DatabaseException('Error loading calibration: $e', details: st);
    }
  }

  Future<DrawingCalibration> saveCalibration(DrawingCalibration calibration) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        DatabaseTables.calibrations,
        calibration.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return calibration;
    } catch (e, st) {
      throw DatabaseException('Error saving calibration: $e', details: st);
    }
  }

  Future<bool> deleteCalibration(String drawingId, {int? pageNumber}) async {
    try {
      final db = await appDatabase.database;
      String where = '${DatabaseTables.colDrawingId} = ?';
      List<dynamic> args = [drawingId];
      if (pageNumber != null) {
        where += ' AND ${DatabaseTables.colPageNumber} = ?';
        args.add(pageNumber);
      }
      final count = await db.delete(DatabaseTables.calibrations, where: where, whereArgs: args);
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error deleting calibration: $e', details: st);
    }
  }

  // --- Measurement Operations ---

  Future<List<Measurement>> getMeasurementsForDrawing(String drawingId, {int? pageNumber}) async {
    try {
      final db = await appDatabase.database;
      String where = '${DatabaseTables.colDrawingId} = ?';
      List<dynamic> args = [drawingId];
      if (pageNumber != null) {
        where += ' AND ${DatabaseTables.colPageNumber} = ?';
        args.add(pageNumber);
      }

      final results = await db.query(
        DatabaseTables.measurements,
        where: where,
        whereArgs: args,
        orderBy: '${DatabaseTables.colCreatedAt} ASC',
      );

      return results.map((m) => Measurement.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Error loading measurements: $e', details: st);
    }
  }

  Future<Measurement> saveMeasurement(Measurement measurement) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        DatabaseTables.measurements,
        measurement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return measurement;
    } catch (e, st) {
      throw DatabaseException('Error saving measurement: $e', details: st);
    }
  }

  Future<List<Measurement>> saveMeasurementsBatch(List<Measurement> measurements) async {
    try {
      final db = await appDatabase.database;
      final batch = db.batch();
      for (final m in measurements) {
        batch.insert(
          DatabaseTables.measurements,
          m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return measurements;
    } catch (e, st) {
      throw DatabaseException('Error batch saving measurements: $e', details: st);
    }
  }

  Future<bool> deleteMeasurement(String id) async {
    try {
      final db = await appDatabase.database;
      final count = await db.delete(
        DatabaseTables.measurements,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error deleting measurement: $e', details: st);
    }
  }

  Future<bool> deleteMeasurementsForDrawing(String drawingId, {int? pageNumber}) async {
    try {
      final db = await appDatabase.database;
      String where = '${DatabaseTables.colDrawingId} = ?';
      List<dynamic> args = [drawingId];
      if (pageNumber != null) {
        where += ' AND ${DatabaseTables.colPageNumber} = ?';
        args.add(pageNumber);
      }
      final count = await db.delete(DatabaseTables.measurements, where: where, whereArgs: args);
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error clearing measurements: $e', details: st);
    }
  }
}
