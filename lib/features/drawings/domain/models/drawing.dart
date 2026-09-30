import 'drawing_type.dart';
import '../../../../core/storage/storage_models.dart';

class Drawing {
  final String id;
  final String projectId;
  final String drawingNumber;
  final String title;
  final DrawingType drawingType;
  final String revision;
  final String filePath;
  final String? thumbnailPath;
  final int pageCount;
  final int fileSize;
  final bool downloaded;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Drawing({
    required this.id,
    required this.projectId,
    required this.drawingNumber,
    required this.title,
    required this.drawingType,
    required this.revision,
    required this.filePath,
    this.thumbnailPath,
    this.pageCount = 1,
    this.fileSize = 0,
    this.downloaded = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedFileSize => StorageUsage.formatBytes(fileSize);

  Drawing copyWith({
    String? id,
    String? projectId,
    String? drawingNumber,
    String? title,
    DrawingType? drawingType,
    String? revision,
    String? filePath,
    String? thumbnailPath,
    int? pageCount,
    int? fileSize,
    bool? downloaded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Drawing(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      drawingNumber: drawingNumber ?? this.drawingNumber,
      title: title ?? this.title,
      drawingType: drawingType ?? this.drawingType,
      revision: revision ?? this.revision,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      pageCount: pageCount ?? this.pageCount,
      fileSize: fileSize ?? this.fileSize,
      downloaded: downloaded ?? this.downloaded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'drawing_number': drawingNumber,
      'title': title,
      'drawing_type': drawingType.name,
      'revision': revision,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'page_count': pageCount,
      'file_size': fileSize,
      'downloaded': downloaded ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Drawing.fromMap(Map<String, dynamic> map) {
    return Drawing(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      drawingNumber: map['drawing_number'] as String,
      title: map['title'] as String,
      drawingType: DrawingTypeExtension.fromString(map['drawing_type'] as String? ?? 'general'),
      revision: map['revision'] as String? ?? 'Rev 0',
      filePath: map['file_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      pageCount: (map['page_count'] as num?)?.toInt() ?? 1,
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      downloaded: (map['downloaded'] as num?)?.toInt() == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Drawing &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
