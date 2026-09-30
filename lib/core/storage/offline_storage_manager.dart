import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'storage_models.dart';
import '../errors/app_exceptions.dart';

class OfflineStorageManager {
  static final OfflineStorageManager instance = OfflineStorageManager._internal();
  OfflineStorageManager._internal();

  Directory? _baseDir;
  late Directory _pdfsDir;
  late Directory _thumbnailsDir;
  late Directory _photosDir;
  late Directory _attachmentsDir;
  late Directory _reportsDir;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        _initialized = true;
        return;
      }

      Directory appDocDir;
      try {
        appDocDir = await getApplicationDocumentsDirectory();
      } catch (e) {
        // Fallback for desktop/testing if path_provider fails
        final currentDir = Directory.current.path;
        appDocDir = Directory(p.join(currentDir, '.field_engineering_data'));
      }

      _baseDir = Directory(p.join(appDocDir.path, 'FieldEngineeringStorage'));
      if (!await _baseDir!.exists()) {
        await _baseDir!.create(recursive: true);
      }

      _pdfsDir = Directory(p.join(_baseDir!.path, 'drawings_pdf'));
      _thumbnailsDir = Directory(p.join(_baseDir!.path, 'thumbnails'));
      _photosDir = Directory(p.join(_baseDir!.path, 'field_photos'));
      _attachmentsDir = Directory(p.join(_baseDir!.path, 'attachments'));
      _reportsDir = Directory(p.join(_baseDir!.path, 'exported_reports'));

      await Future.wait([
        _ensureDirectoryExists(_pdfsDir),
        _ensureDirectoryExists(_thumbnailsDir),
        _ensureDirectoryExists(_photosDir),
        _ensureDirectoryExists(_attachmentsDir),
        _ensureDirectoryExists(_reportsDir),
      ]);

      _initialized = true;
    } catch (e, st) {
      throw StorageException('Failed to initialize offline storage manager: $e', details: st);
    }
  }

  Future<void> _ensureDirectoryExists(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Directory get pdfsDirectory {
    _checkInit();
    return _pdfsDir;
  }

  Directory get thumbnailsDirectory {
    _checkInit();
    return _thumbnailsDir;
  }

  Directory get photosDirectory {
    _checkInit();
    return _photosDir;
  }

  Directory get attachmentsDirectory {
    _checkInit();
    return _attachmentsDir;
  }

  Directory get reportsDirectory {
    _checkInit();
    return _reportsDir;
  }

  Directory? get rootStorageDirectory => _baseDir;

  void _checkInit() {
    if (!_initialized) {
      // Lazy init fallback if not already initialized
    }
  }

  Future<File> savePdfFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    await initialize();
    final sanitizedName = p.basename(fileName);
    final targetPath = p.join(_pdfsDir.path, sanitizedName);
    final file = File(targetPath);
    return await file.writeAsBytes(bytes, flush: true);
  }

  Future<File> importPdfFromPath({
    required String sourceFilePath,
    String? customFileName,
  }) async {
    await initialize();
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw StorageException('Source PDF file does not exist at $sourceFilePath');
    }

    final targetName = customFileName ?? p.basename(sourceFilePath);
    final targetPath = p.join(_pdfsDir.path, targetName);
    return await sourceFile.copy(targetPath);
  }

  Future<File> saveThumbnail({
    required String fileName,
    required List<int> bytes,
  }) async {
    await initialize();
    final targetPath = p.join(_thumbnailsDir.path, p.basename(fileName));
    final file = File(targetPath);
    return await file.writeAsBytes(bytes, flush: true);
  }

  Future<File> saveReport({
    required String fileName,
    required List<int> bytes,
  }) async {
    await initialize();
    final targetPath = p.join(_reportsDir.path, p.basename(fileName));
    final file = File(targetPath);
    return await file.writeAsBytes(bytes, flush: true);
  }

  Future<File> savePhoto({
    required String fileName,
    required List<int> bytes,
  }) async {
    await initialize();
    final targetPath = p.join(_photosDir.path, p.basename(fileName));
    final file = File(targetPath);
    return await file.writeAsBytes(bytes, flush: true);
  }

  Future<File> saveAttachment({
    required String fileName,
    required List<int> bytes,
  }) async {
    await initialize();
    final targetPath = p.join(_attachmentsDir.path, p.basename(fileName));
    final file = File(targetPath);
    return await file.writeAsBytes(bytes, flush: true);
  }

  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file $filePath: $e');
      return false;
    }
  }

  Future<int> _calculateDirSize(Directory? dir) async {
    if (dir == null || !await dir.exists()) return 0;
    int totalSize = 0;
    try {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    } catch (e) {
      debugPrint('Error computing dir size for ${dir.path}: $e');
    }
    return totalSize;
  }

  Future<StorageUsage> calculateStorageUsage([int databaseBytes = 0]) async {
    await initialize();
    final pdfs = await _calculateDirSize(_pdfsDir);
    final thumbs = await _calculateDirSize(_thumbnailsDir);
    final photos = await _calculateDirSize(_photosDir);
    final attaches = await _calculateDirSize(_attachmentsDir);
    final reports = await _calculateDirSize(_reportsDir);

    final total = pdfs + thumbs + photos + attaches + reports + databaseBytes;

    return StorageUsage(
      pdfsBytes: pdfs,
      thumbnailsBytes: thumbs,
      photosBytes: photos,
      attachmentsBytes: attaches,
      reportsBytes: reports,
      databaseBytes: databaseBytes,
      totalUsedBytes: total,
    );
  }

  Future<void> clearCategory(StorageCategory category) async {
    await initialize();
    Directory? target;
    switch (category) {
      case StorageCategory.pdfs:
        target = _pdfsDir;
        break;
      case StorageCategory.thumbnails:
        target = _thumbnailsDir;
        break;
      case StorageCategory.photos:
        target = _photosDir;
        break;
      case StorageCategory.attachments:
        target = _attachmentsDir;
        break;
      case StorageCategory.reports:
        target = _reportsDir;
        break;
      case StorageCategory.database:
        return;
    }

    if (await target.exists()) {
      await for (final entity in target.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  Future<List<FileSystemEntity>> listCategoryFiles(StorageCategory category) async {
    await initialize();
    Directory target;
    switch (category) {
      case StorageCategory.pdfs:
        target = _pdfsDir;
        break;
      case StorageCategory.thumbnails:
        target = _thumbnailsDir;
        break;
      case StorageCategory.photos:
        target = _photosDir;
        break;
      case StorageCategory.attachments:
        target = _attachmentsDir;
        break;
      case StorageCategory.reports:
        target = _reportsDir;
        break;
      case StorageCategory.database:
        return [];
    }

    if (!await target.exists()) return [];
    return await target.list().toList();
  }
}
