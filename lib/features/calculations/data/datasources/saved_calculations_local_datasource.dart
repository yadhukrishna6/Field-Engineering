import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/models/saved_calculation.dart';
import '../../../../core/errors/app_exceptions.dart';

class SavedCalculationsLocalDataSource {
  final AppDatabase appDatabase;

  SavedCalculationsLocalDataSource({required this.appDatabase});

  Future<List<SavedCalculation>> getSavedCalculations({String? calcType}) async {
    try {
      final db = await appDatabase.database;
      String? where;
      List<dynamic>? args;

      if (calcType != null && calcType.isNotEmpty) {
        where = '${DatabaseTables.colCalcType} = ?';
        args = [calcType];
      }

      final results = await db.query(
        DatabaseTables.savedCalculations,
        where: where,
        whereArgs: args,
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );

      return results.map((m) => SavedCalculation.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Error querying saved calculations: $e', details: st);
    }
  }

  Future<SavedCalculation> saveCalculation(SavedCalculation calculation) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        DatabaseTables.savedCalculations,
        calculation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return calculation;
    } catch (e, st) {
      throw DatabaseException('Error saving calculation sheet: $e', details: st);
    }
  }

  Future<bool> deleteCalculation(String id) async {
    try {
      final db = await appDatabase.database;
      final count = await db.delete(
        DatabaseTables.savedCalculations,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error deleting calculation: $e', details: st);
    }
  }
}
