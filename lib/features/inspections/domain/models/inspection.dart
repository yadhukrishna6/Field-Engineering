enum InspectionStatus { scheduled, inProgress, passed, failed, pendingReview }

class Inspection {
  final String id;
  final String projectId;
  final String? drawingId;
  final String inspectionType;
  final String location;
  final InspectionStatus status;
  final String inspectorId;
  final String? notes;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final DateTime createdAt;

  const Inspection({
    required this.id,
    required this.projectId,
    this.drawingId,
    required this.inspectionType,
    required this.location,
    required this.status,
    required this.inspectorId,
    this.notes,
    required this.scheduledDate,
    this.completedDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'drawingId': drawingId,
      'inspectionType': inspectionType,
      'location': location,
      'status': status.name,
      'inspectorId': inspectorId,
      'notes': notes,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      drawingId: map['drawingId'] as String?,
      inspectionType: map['inspectionType'] as String,
      location: map['location'] as String,
      status: InspectionStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => InspectionStatus.scheduled),
      inspectorId: map['inspectorId'] as String,
      notes: map['notes'] as String?,
      scheduledDate: DateTime.parse(map['scheduledDate'] as String),
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate'] as String) : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
