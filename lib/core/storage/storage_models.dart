import 'package:flutter/material.dart';

class StorageUsage {
  final int pdfsBytes;
  final int thumbnailsBytes;
  final int photosBytes;
  final int attachmentsBytes;
  final int reportsBytes;
  final int databaseBytes;
  final int totalUsedBytes;

  const StorageUsage({
    required this.pdfsBytes,
    required this.thumbnailsBytes,
    required this.photosBytes,
    required this.attachmentsBytes,
    required this.reportsBytes,
    required this.databaseBytes,
    required this.totalUsedBytes,
  });

  String get formattedTotal => formatBytes(totalUsedBytes);
  String get formattedPdfs => formatBytes(pdfsBytes);
  String get formattedThumbnails => formatBytes(thumbnailsBytes);
  String get formattedPhotos => formatBytes(photosBytes);
  String get formattedAttachments => formatBytes(attachmentsBytes);
  String get formattedReports => formatBytes(reportsBytes);
  String get formattedDatabase => formatBytes(databaseBytes);

  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}

enum StorageCategory {
  pdfs,
  thumbnails,
  photos,
  attachments,
  reports,
  database,
}

extension StorageCategoryExtension on StorageCategory {
  String get displayName {
    switch (this) {
      case StorageCategory.pdfs:
        return 'Vector PDFs';
      case StorageCategory.thumbnails:
        return 'Thumbnails';
      case StorageCategory.photos:
        return 'Field Photos';
      case StorageCategory.attachments:
        return 'Attachments';
      case StorageCategory.reports:
        return 'Exported Reports';
      case StorageCategory.database:
        return 'SQLite DB';
    }
  }

  IconData get icon {
    switch (this) {
      case StorageCategory.pdfs:
        return Icons.picture_as_pdf_rounded;
      case StorageCategory.thumbnails:
        return Icons.image_rounded;
      case StorageCategory.photos:
        return Icons.camera_alt_rounded;
      case StorageCategory.attachments:
        return Icons.attach_file_rounded;
      case StorageCategory.reports:
        return Icons.description_rounded;
      case StorageCategory.database:
        return Icons.storage_rounded;
    }
  }
}

