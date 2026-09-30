import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/models/photo_attachment.dart';

class PhotosLocalDataSource {
  final AppDatabase _appDatabase;

  PhotosLocalDataSource({required AppDatabase appDatabase}) : _appDatabase = appDatabase;

  Future<void> insertPhoto(PhotoAttachment photo) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DatabaseTables.photos,
        photo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw DatabaseException('Failed to insert photo attachment: $e', details: st);
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        DatabaseTables.photos,
        where: '${DatabaseTables.colId} = ?',
        whereArgs: [photoId],
      );
    } catch (e, st) {
      throw DatabaseException('Failed to delete photo attachment: $e', details: st);
    }
  }

  Future<List<PhotoAttachment>> getPhotosByIssue(String issueId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.photos,
        where: '${DatabaseTables.colIssueId} = ?',
        whereArgs: [issueId],
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => PhotoAttachment.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get issue photos: $e', details: st);
    }
  }

  Future<List<PhotoAttachment>> getPhotosByInspection(String inspectionId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.photos,
        where: '${DatabaseTables.colInspectionId} = ?',
        whereArgs: [inspectionId],
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => PhotoAttachment.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get inspection photos: $e', details: st);
    }
  }

  Future<List<PhotoAttachment>> getPhotosByEquipment(String equipmentId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.photos,
        where: '${DatabaseTables.colEquipmentId} = ?',
        whereArgs: [equipmentId],
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => PhotoAttachment.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get equipment photos: $e', details: st);
    }
  }

  Future<List<PhotoAttachment>> getPhotosByDrawing(String drawingId, {int? pageNumber}) async {
    try {
      final db = await _appDatabase.database;
      String where = '${DatabaseTables.colDrawingId} = ?';
      List<dynamic> whereArgs = [drawingId];

      if (pageNumber != null) {
        where += ' AND ${DatabaseTables.colPageNumber} = ?';
        whereArgs.add(pageNumber);
      }

      final results = await db.query(
        DatabaseTables.photos,
        where: where,
        whereArgs: whereArgs,
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => PhotoAttachment.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get drawing photos: $e', details: st);
    }
  }

  Future<List<PhotoAttachment>> getAllPhotos() async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseTables.photos,
        orderBy: '${DatabaseTables.colCreatedAt} DESC',
      );
      return results.map((m) => PhotoAttachment.fromMap(m)).toList();
    } catch (e, st) {
      throw DatabaseException('Failed to get all photos: $e', details: st);
    }
  }
}
