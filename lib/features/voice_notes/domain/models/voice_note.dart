class VoiceNote {
  final String id;
  final String filePath;
  final String title;
  final int durationSeconds;
  final String? drawingId;
  final int pageNumber;
  final double? positionX;
  final double? positionY;
  final String? issueId;
  final String? inspectionId;
  final String? createdBy;
  final DateTime createdAt;

  const VoiceNote({
    required this.id,
    required this.filePath,
    required this.title,
    this.durationSeconds = 0,
    this.drawingId,
    this.pageNumber = 1,
    this.positionX,
    this.positionY,
    this.issueId,
    this.inspectionId,
    this.createdBy,
    required this.createdAt,
  });

  bool get isDrawingPin => drawingId != null && positionX != null && positionY != null;

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  VoiceNote copyWith({
    String? id,
    String? filePath,
    String? title,
    int? durationSeconds,
    String? drawingId,
    int? pageNumber,
    double? positionX,
    double? positionY,
    String? issueId,
    String? inspectionId,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      drawingId: drawingId ?? this.drawingId,
      pageNumber: pageNumber ?? this.pageNumber,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      issueId: issueId ?? this.issueId,
      inspectionId: inspectionId ?? this.inspectionId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'title': title,
      'duration_seconds': durationSeconds,
      'drawing_id': drawingId,
      'page_number': pageNumber,
      'position_x': positionX,
      'position_y': positionY,
      'issue_id': issueId,
      'inspection_id': inspectionId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VoiceNote.fromMap(Map<String, dynamic> map) {
    return VoiceNote(
      id: map['id'] as String,
      filePath: (map['file_path'] ?? map['filePath']) as String,
      title: (map['title'] ?? 'Voice Note') as String,
      durationSeconds: (map['duration_seconds'] ?? map['durationSeconds'] ?? 0) as int,
      drawingId: (map['drawing_id'] ?? map['drawingId']) as String?,
      pageNumber: (map['page_number'] ?? map['pageNumber'] ?? 1) as int,
      positionX: map['position_x'] != null ? (map['position_x'] as num).toDouble() : null,
      positionY: map['position_y'] != null ? (map['position_y'] as num).toDouble() : null,
      issueId: (map['issue_id'] ?? map['issueId']) as String?,
      inspectionId: (map['inspection_id'] ?? map['inspectionId']) as String?,
      createdBy: (map['created_by'] ?? map['createdBy']) as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
