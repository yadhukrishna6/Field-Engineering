import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/models/voice_note.dart';

class VoiceNotesLocalDataSource {
  final AppDatabase _appDatabase;

  VoiceNotesLocalDataSource({required AppDatabase appDatabase}) : _appDatabase = appDatabase;

  Future<void> insertVoiceNote(VoiceNote voiceNote) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DatabaseTables.voiceNotes,
        voiceNote.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw DatabaseException('Failed to insert voice note: $e', details: st);
    }
  }

  Future<void> deleteVoiceNote(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        DatabaseTables.voiceNotes,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw DatabaseException('Failed to delete voice note: $e', details: st);
    }
  }

  Future<List<VoiceNote>> getVoiceNotesByIssue(String issueId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.voiceNotes,
        where: '${DatabaseTables.colIssueId} = ?',
        whereArgs: [issueId],
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => VoiceNote.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get issue voice notes: $e', details: st);
    }
  }

  Future<List<VoiceNote>> getVoiceNotesByInspection(String inspectionId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.voiceNotes,
        where: '${DatabaseTables.colInspectionId} = ?',
        whereArgs: [inspectionId],
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => VoiceNote.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get inspection voice notes: $e', details: st);
    }
  }

  Future<List<VoiceNote>> getVoiceNotesByDrawing(String drawingId, {int? pageNumber}) async {
    try {
      final db = await _appDatabase.database;
      String where = '${DatabaseTables.colDrawingId} = ?';
      List<dynamic> whereArgs = [drawingId];

      if (pageNumber != null) {
        where += ' AND ${DatabaseTables.colPageNumber} = ?';
        whereArgs.add(pageNumber);
      }

      final results = await db.query(
        DatabaseTables.voiceNotes,
        where: where,
        whereArgs: whereArgs,
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => VoiceNote.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get drawing voice notes: $e', details: st);
    }
  }

  Future<List<VoiceNote>> getAllVoiceNotes() async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.voiceNotes,
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => VoiceNote.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get all voice notes: $e', details: st);
    }
  }
}
