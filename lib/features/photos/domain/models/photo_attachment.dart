class PhotoAttachment {
  final String id;
  final String filePath;
  final String? thumbnailPath;
  final String? title;
  final String? caption;
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;
  final DateTime? gpsTimestamp;
  final String? drawingId;
  final int pageNumber;
  final double? positionX;
  final double? positionY;
  final String? issueId;
  final String? inspectionId;
  final String? equipmentId;
  final int fileSize;
  final DateTime createdAt;

  const PhotoAttachment({
    required this.id,
    required this.filePath,
    this.thumbnailPath,
    this.title,
    this.caption,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.gpsTimestamp,
    this.drawingId,
    this.pageNumber = 1,
    this.positionX,
    this.positionY,
    this.issueId,
    this.inspectionId,
    this.equipmentId,
    this.fileSize = 0,
    required this.createdAt,
  });

  bool get isDrawingPin => drawingId != null && positionX != null && positionY != null;

  PhotoAttachment copyWith({
    String? id,
    String? filePath,
    String? thumbnailPath,
    String? title,
    String? caption,
    double? latitude,
    double? longitude,
    double? gpsAccuracy,
    DateTime? gpsTimestamp,
    String? drawingId,
    int? pageNumber,
    double? positionX,
    double? positionY,
    String? issueId,
    String? inspectionId,
    String? equipmentId,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return PhotoAttachment(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      gpsTimestamp: gpsTimestamp ?? this.gpsTimestamp,
      drawingId: drawingId ?? this.drawingId,
      pageNumber: pageNumber ?? this.pageNumber,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      issueId: issueId ?? this.issueId,
      inspectionId: inspectionId ?? this.inspectionId,
      equipmentId: equipmentId ?? this.equipmentId,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'title': title,
      'caption': caption,
      'latitude': latitude,
      'longitude': longitude,
      'gps_accuracy': gpsAccuracy,
      'gps_timestamp': gpsTimestamp?.toIso8601String(),
      'drawing_id': drawingId,
      'page_number': pageNumber,
      'position_x': positionX,
      'position_y': positionY,
      'issue_id': issueId,
      'inspection_id': inspectionId,
      'equipment_id': equipmentId,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PhotoAttachment.fromMap(Map<String, dynamic> map) {
    return PhotoAttachment(
      id: map['id'] as String,
      filePath: (map['file_path'] ?? map['filePath']) as String,
      thumbnailPath: (map['thumbnail_path'] ?? map['thumbnailPath']) as String?,
      title: map['title'] as String?,
      caption: map['caption'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      gpsAccuracy: map['gps_accuracy'] != null ? (map['gps_accuracy'] as num).toDouble() : null,
      gpsTimestamp: map['gps_timestamp'] != null
          ? DateTime.parse(map['gps_timestamp'] as String)
          : null,
      drawingId: (map['drawing_id'] ?? map['drawingId']) as String?,
      pageNumber: (map['page_number'] ?? map['pageNumber'] ?? 1) as int,
      positionX: map['position_x'] != null ? (map['position_x'] as num).toDouble() : null,
      positionY: map['position_y'] != null ? (map['position_y'] as num).toDouble() : null,
      issueId: (map['issue_id'] ?? map['issueId']) as String?,
      inspectionId: (map['inspection_id'] ?? map['inspectionId']) as String?,
      equipmentId: (map['equipment_id'] ?? map['equipmentId']) as String?,
      fileSize: (map['file_size'] ?? map['fileSize'] ?? 0) as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
