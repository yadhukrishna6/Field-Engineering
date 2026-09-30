import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/models/drawing_revision.dart';

class RevisionsLocalDataSource {
  final AppDatabase appDatabase;
  RevisionsLocalDataSource(this.appDatabase);

  Future<List<DrawingRevision>> getRevisionsForDrawing(String drawingId) async {
    final db = await appDatabase.database;
    final results = await db.query(
      DatabaseTables.revisions,
      where: '${DatabaseTables.colDrawingId} = ?',
      whereArgs: [drawingId],
      orderBy: '${DatabaseTables.colUploadedAt} DESC',
    );
    return results.map((m) => DrawingRevision.fromMap(m)).toList();
  }

  Future<void> insertRevision(DrawingRevision revision) async {
    final db = await appDatabase.database;
    await db.insert(
      DatabaseTables.revisions,
      revision.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRevisionStatus(String revisionId, RevisionStatus status) async {
    final db = await appDatabase.database;
    await db.update(
      DatabaseTables.revisions,
      {
        DatabaseTables.colRevisionStatus: status.name,
        DatabaseTables.colUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseTables.colId} = ?',
      whereArgs: [revisionId],
    );
  }
}
