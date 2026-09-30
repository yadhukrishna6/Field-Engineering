import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/models/issue.dart';

class IssuesLocalDataSource {
  final AppDatabase _appDatabase;

  IssuesLocalDataSource({required AppDatabase appDatabase}) : _appDatabase = appDatabase;

  Future<void> insertIssue(Issue issue) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DatabaseTables.issues,
        issue.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw DatabaseException('Failed to save issue: $e', details: st);
    }
  }

  Future<void> updateIssue(Issue issue) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DatabaseTables.issues,
        issue.toMap(),
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [issue.id],
      );
    } catch (e, st) {
      throw DatabaseException('Failed to update issue: $e', details: st);
    }
  }

  Future<void> deleteIssue(String issueId) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        DatabaseTables.issues,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [issueId],
      );
    } catch (e, st) {
      throw DatabaseException('Failed to delete issue: $e', details: st);
    }
  }

  Future<List<Issue>> getIssuesByProject(String projectId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.issues,
        where: '${DatabaseTables.colProjectId} = ?',
        whereArgs: [projectId],
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => Issue.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get project issues: $e', details: st);
    }
  }

  Future<List<Issue>> getIssuesByDrawing(String drawingId, {int? pageNumber}) async {
    try {
      final db = await _appDatabase.database;
      String where = '${DatabaseTables.colDrawingId} = ?';
      List<dynamic> whereArgs = [drawingId];

      if (pageNumber != null) {
        where += ' AND ${DatabaseTables.colPageNumber} = ?';
        whereArgs.add(pageNumber);
      }

      final results = await db.query(
        DatabaseTables.issues,
        where: where,
        whereArgs: whereArgs,
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => Issue.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get drawing issues: $e', details: st);
    }
  }

  Future<List<Issue>> getAllIssues() async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.issues,
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => Issue.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get all issues: $e', details: st);
    }
  }

  Future<Issue?> getIssueById(String id) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.issues,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return Issue.fromMap(results.first);
    } catch (e, st) {
      throw DatabaseException('Failed to get issue by id: $e', details: st);
    }
  }
}
