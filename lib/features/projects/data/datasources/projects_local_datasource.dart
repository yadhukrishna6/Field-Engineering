import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../../../core/errors/app_exceptions.dart';

class ProjectsLocalDataSource {
  final AppDatabase appDatabase;

  ProjectsLocalDataSource({required this.appDatabase});

  Future<List<Project>> getProjects({
    String? searchQuery,
    ProjectStatus? statusFilter,
  }) async {
    try {
      final db = await appDatabase.database;
      
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        whereClause += '(${DatabaseTables.colName} LIKE ? OR ${DatabaseTables.colProjectNumber} LIKE ? OR ${DatabaseTables.colClient} LIKE ? OR ${DatabaseTables.colLocation} LIKE ?)';
        final queryParam = '%${searchQuery.trim()}%';
        whereArgs.addAll([queryParam, queryParam, queryParam, queryParam]);
      }

      if (statusFilter != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += '${DatabaseTables.colStatus} = ?';
        whereArgs.add(statusFilter.name);
      }

      final results = await db.query(
        DatabaseTables.projects,
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: '${DatabaseTables.colUpdatedAt} DESC',
      );

      final List<Project> projects = [];
      for (final map in results) {
        final projectId = map[DatabaseTables.colId] as String;
        
        // Aggregate drawing counts for tablet UI
        final drawingStats = await db.rawQuery('''
          SELECT 
            COUNT(*) as total_count,
            SUM(CASE WHEN ${DatabaseTables.colDownloaded} = 1 THEN 1 ELSE 0 END) as downloaded_count,
            SUM(${DatabaseTables.colFileSize}) as total_bytes
          FROM ${DatabaseTables.drawings}
          WHERE ${DatabaseTables.colProjectId} = ?
        ''', [projectId]);

        final totalCount = (drawingStats.first['total_count'] as num?)?.toInt() ?? 0;
        final downloadedCount = (drawingStats.first['downloaded_count'] as num?)?.toInt() ?? 0;
        final totalBytes = (drawingStats.first['total_bytes'] as num?)?.toInt() ?? 0;

        projects.add(Project.fromMap(
          map,
          drawingCount: totalCount,
          downloadedCount: downloadedCount,
          totalBytes: totalBytes,
        ));
      }

      return projects;
    } catch (e, st) {
      throw DatabaseException('Error querying projects: $e', details: st);
    }
  }

  Future<Project?> getProjectById(String id) async {
    try {
      final db = await appDatabase.database;
      final results = await db.query(
        DatabaseTables.projects,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final drawingStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_count,
          SUM(CASE WHEN ${DatabaseTables.colDownloaded} = 1 THEN 1 ELSE 0 END) as downloaded_count,
          SUM(${DatabaseTables.colFileSize}) as total_bytes
        FROM ${DatabaseTables.drawings}
        WHERE ${DatabaseTables.colProjectId} = ?
      ''', [id]);

      final totalCount = (drawingStats.first['total_count'] as num?)?.toInt() ?? 0;
      final downloadedCount = (drawingStats.first['downloaded_count'] as num?)?.toInt() ?? 0;
      final totalBytes = (drawingStats.first['total_bytes'] as num?)?.toInt() ?? 0;

      return Project.fromMap(
        results.first,
        drawingCount: totalCount,
        downloadedCount: downloadedCount,
        totalBytes: totalBytes,
      );
    } catch (e, st) {
      throw DatabaseException('Error querying project by id $id: $e', details: st);
    }
  }

  Future<Project> insertProject(Project project) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        DatabaseTables.projects,
        project.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return project;
    } catch (e, st) {
      throw DatabaseException('Error inserting project: $e', details: st);
    }
  }

  Future<Project> updateProject(Project project) async {
    try {
      final db = await appDatabase.database;
      await db.update(
        DatabaseTables.projects,
        project.toMap(),
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [project.id],
      );
      return project;
    } catch (e, st) {
      throw DatabaseException('Error updating project: $e', details: st);
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      final db = await appDatabase.database;
      final count = await db.delete(
        DatabaseTables.projects,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e, st) {
      throw DatabaseException('Error deleting project: $e', details: st);
    }
  }
}
