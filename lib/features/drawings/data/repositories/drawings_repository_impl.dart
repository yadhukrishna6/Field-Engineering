import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/drawing.dart';
import '../../domain/models/drawing_type.dart';
import '../../domain/repositories/drawings_repository.dart';
import '../datasources/drawings_local_datasource.dart';
import '../../../../core/storage/offline_storage_manager.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/app_exceptions.dart';

class DrawingsRepositoryImpl implements DrawingsRepository {
  final DrawingsLocalDataSource localDataSource;
  final OfflineStorageManager storageManager;
  final _uuid = const Uuid();
  final _drawingsStreamController = StreamController<List<Drawing>>.broadcast();

  DrawingsRepositoryImpl({
    required this.localDataSource,
    required this.storageManager,
  });

  @override
  Future<List<Drawing>> getDrawingsForProject(
    String projectId, {
    String? searchQuery,
    DrawingType? typeFilter,
    String? revisionFilter,
  }) async {
    try {
      return await localDataSource.getDrawingsForProject(
        projectId,
        searchQuery: searchQuery,
        typeFilter: typeFilter,
        revisionFilter: revisionFilter,
      );
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error getting drawings for project: $e');
    }
  }

  @override
  Future<List<Drawing>> getAllDrawings({
    String? searchQuery,
    DrawingType? typeFilter,
    bool? downloadedOnly,
  }) async {
    try {
      return await localDataSource.getAllDrawings(
        searchQuery: searchQuery,
        typeFilter: typeFilter,
        downloadedOnly: downloadedOnly,
      );
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error getting all drawings: $e');
    }
  }

  @override
  Future<Drawing?> getDrawingById(String id) async {
    try {
      return await localDataSource.getDrawingById(id);
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error getting drawing by id: $e');
    }
  }

  @override
  Future<Drawing> addDrawing(Drawing drawing) async {
    try {
      final result = await localDataSource.insertDrawing(drawing);
      _notifyStream(drawing.projectId);
      return result;
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error adding drawing: $e');
    }
  }

  @override
  Future<Drawing> updateDrawing(Drawing drawing) async {
    try {
      final updated = drawing.copyWith(updatedAt: DateTime.now());
      final result = await localDataSource.updateDrawing(updated);
      _notifyStream(drawing.projectId);
      return result;
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error updating drawing: $e');
    }
  }

  @override
  Future<bool> deleteDrawing(String id) async {
    try {
      final drawing = await localDataSource.getDrawingById(id);
      if (drawing != null) {
        // Remove underlying PDF and thumbnail files from offline disk storage
        if (drawing.filePath.isNotEmpty) {
          await storageManager.deleteFile(drawing.filePath);
        }
        if (drawing.thumbnailPath != null && drawing.thumbnailPath!.isNotEmpty) {
          await storageManager.deleteFile(drawing.thumbnailPath!);
        }

        final success = await localDataSource.deleteDrawing(id);
        if (success) {
          _notifyStream(drawing.projectId);
        }
        return success;
      }
      return false;
    } on DatabaseException catch (e) {
      throw DatabaseFailure(e.message, e.details);
    } catch (e) {
      throw DatabaseFailure('Unexpected error deleting drawing: $e');
    }
  }

  @override
  Future<Drawing> importPdfDrawing({
    required String projectId,
    required String sourceFilePath,
    required String drawingNumber,
    required String title,
    required DrawingType drawingType,
    required String revision,
  }) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        throw StorageFailure('Source PDF file does not exist at $sourceFilePath');
      }

      final fileSize = await sourceFile.length();
      final targetFileName = '${drawingNumber.replaceAll(RegExp(r'[^\w\-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final savedFile = await storageManager.importPdfFromPath(
        sourceFilePath: sourceFilePath,
        customFileName: targetFileName,
      );

      final newDrawing = Drawing(
        id: _uuid.v4(),
        projectId: projectId,
        drawingNumber: drawingNumber,
        title: title,
        drawingType: drawingType,
        revision: revision,
        filePath: savedFile.path,
        thumbnailPath: null,
        pageCount: 1,
        fileSize: fileSize,
        downloaded: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await localDataSource.insertDrawing(newDrawing);
      _notifyStream(projectId);
      return result;
    } catch (e) {
      throw StorageFailure('Failed to import PDF drawing: $e');
    }
  }

  @override
  Future<void> markDrawingDownloaded(String id, bool downloaded) async {
    try {
      await localDataSource.updateDownloadedStatus(id, downloaded);
      final drawing = await localDataSource.getDrawingById(id);
      if (drawing != null) {
        _notifyStream(drawing.projectId);
      }
    } catch (e) {
      throw DatabaseFailure('Failed to update download status: $e');
    }
  }

  void _notifyStream(String projectId) async {
    try {
      final drawings = await localDataSource.getDrawingsForProject(projectId);
      if (!_drawingsStreamController.isClosed) {
        _drawingsStreamController.add(drawings);
      }
    } catch (e) {
      debugPrint('Error notifying drawings stream: $e');
    }
  }

  @override
  Stream<List<Drawing>> watchDrawingsForProject(String projectId) {
    _notifyStream(projectId);
    return _drawingsStreamController.stream;
  }
}
