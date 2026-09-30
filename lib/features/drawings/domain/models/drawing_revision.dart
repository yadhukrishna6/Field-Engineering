import 'package:uuid/uuid.dart';

enum RevisionStatus {
  draft,
  approved,
  superseded,
  asBuilt,
  voided,
}

extension RevisionStatusExtension on RevisionStatus {
  String get displayName {
    switch (this) {
      case RevisionStatus.draft:
        return 'Draft / In-Review';
      case RevisionStatus.approved:
        return 'Approved (IFC)';
      case RevisionStatus.superseded:
        return 'Superseded';
      case RevisionStatus.asBuilt:
        return 'As-Built Certified';
      case RevisionStatus.voided:
        return 'Void';
    }
  }
}

class DrawingRevision {
  final String id;
  final String drawingId;
  final String revisionNumber; // Rev 00, Rev 01, Rev 02, Rev 03
  final String revisionDescription;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String filePath;
  final RevisionStatus status;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DrawingRevision({
    required this.id,
    required this.drawingId,
    required this.revisionNumber,
    required this.revisionDescription,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.filePath,
    this.status = RevisionStatus.approved,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DrawingRevision.create({
    required String drawingId,
    required String revisionNumber,
    required String revisionDescription,
    required String uploadedBy,
    required String filePath,
    RevisionStatus status = RevisionStatus.approved,
  }) {
    final now = DateTime.now();
    return DrawingRevision(
      id: const Uuid().v4(),
      drawingId: drawingId,
      revisionNumber: revisionNumber,
      revisionDescription: revisionDescription,
      uploadedBy: uploadedBy,
      uploadedAt: now,
      filePath: filePath,
      status: status,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drawing_id': drawingId,
      'revision_number': revisionNumber,
      'revision_description': revisionDescription,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
      'file_path': filePath,
      'revision_status': status.name,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DrawingRevision.fromMap(Map<String, dynamic> map) {
    RevisionStatus st;
    final stStr = (map['revision_status'] as String? ?? 'approved').toLowerCase();
    if (stStr == 'draft') {
      st = RevisionStatus.draft;
    } else if (stStr == 'superseded') {
      st = RevisionStatus.superseded;
    } else if (stStr == 'asbuilt' || stStr == 'as_built') {
      st = RevisionStatus.asBuilt;
    } else if (stStr == 'void' || stStr == 'voided') {
      st = RevisionStatus.voided;
    } else {
      st = RevisionStatus.approved;
    }

    return DrawingRevision(
      id: map['id'] as String,
      drawingId: map['drawing_id'] as String,
      revisionNumber: map['revision_number'] as String? ?? 'Rev 00',
      revisionDescription: map['revision_description'] as String? ?? '',
      uploadedBy: map['uploaded_by'] as String? ?? 'Lead Engineer',
      uploadedAt: DateTime.tryParse(map['uploaded_at'] as String? ?? '') ?? DateTime.now(),
      filePath: map['file_path'] as String? ?? '',
      status: st,
      version: (map['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
