import 'package:flutter/material.dart';

enum IssueCategory {
  piping('Piping', Icons.plumbing_rounded, Color(0xFF0288D1)),
  mechanical('Mechanical', Icons.precision_manufacturing_rounded, Color(0xFFE65100)),
  electrical('Electrical', Icons.electric_bolt_rounded, Color(0xFFFFB300)),
  civil('Civil', Icons.foundation_rounded, Color(0xFF795548)),
  structural('Structural', Icons.architecture_rounded, Color(0xFF607D8B)),
  instrumentation('Instrumentation', Icons.speed_rounded, Color(0xFF9C27B0)),
  safety('Safety', Icons.warning_amber_rounded, Color(0xFFD32F2F)),
  other('Other', Icons.category_rounded, Color(0xFF757575));

  final String label;
  final IconData icon;
  final Color color;
  const IssueCategory(this.label, this.icon, this.color);

  static IssueCategory fromString(String? val) {
    if (val == null) return IssueCategory.piping;
    return IssueCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => IssueCategory.other,
    );
  }
}

enum IssuePriority {
  low('Low', Color(0xFF4CAF50), 1),
  medium('Medium', Color(0xFFFF9800), 2),
  high('High', Color(0xFFFF5722), 3),
  critical('Critical', Color(0xFFD32F2F), 4);

  final String label;
  final Color color;
  final int level;
  const IssuePriority(this.label, this.color, this.level);

  static IssuePriority fromString(String? val) {
    if (val == null) return IssuePriority.medium;
    return IssuePriority.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => IssuePriority.medium,
    );
  }
}

enum IssueStatus {
  open('Open', Icons.radio_button_unchecked_rounded, Color(0xFFE53935)),
  inProgress('In Progress', Icons.pending_actions_rounded, Color(0xFFFF9800)),
  resolved('Resolved', Icons.check_circle_outline_rounded, Color(0xFF00ACC1)),
  verified('Verified', Icons.verified_rounded, Color(0xFF43A047)),
  closed('Closed', Icons.lock_outline_rounded, Color(0xFF78909C));

  final String label;
  final IconData icon;
  final Color color;
  const IssueStatus(this.label, this.icon, this.color);

  static IssueStatus fromString(String? val) {
    if (val == null) return IssueStatus.open;
    final normalized = val.toLowerCase().replaceAll(' ', '');
    return IssueStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized || e.label.toLowerCase().replaceAll(' ', '') == normalized,
      orElse: () => IssueStatus.open,
    );
  }
}

class Issue {
  final String id;
  final String projectId;
  final String? drawingId;
  final int pageNumber;
  final double? positionX;
  final double? positionY;
  final String title;
  final String description;
  final IssueCategory category;
  final IssuePriority priority;
  final IssueStatus status;
  final String? assignedTo;
  final String createdBy;
  final String? dueDate;
  final String? equipmentId;
  final String? inspectionId;
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Issue({
    required this.id,
    required this.projectId,
    this.drawingId,
    this.pageNumber = 1,
    this.positionX,
    this.positionY,
    required this.title,
    required this.description,
    this.category = IssueCategory.piping,
    this.priority = IssuePriority.medium,
    this.status = IssueStatus.open,
    this.assignedTo,
    required this.createdBy,
    this.dueDate,
    this.equipmentId,
    this.inspectionId,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPinnedToDrawing => drawingId != null && positionX != null && positionY != null;

  Issue copyWith({
    String? id,
    String? projectId,
    String? drawingId,
    int? pageNumber,
    double? positionX,
    double? positionY,
    String? title,
    String? description,
    IssueCategory? category,
    IssuePriority? priority,
    IssueStatus? status,
    String? assignedTo,
    String? createdBy,
    String? dueDate,
    String? equipmentId,
    String? inspectionId,
    double? latitude,
    double? longitude,
    double? gpsAccuracy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Issue(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      drawingId: drawingId ?? this.drawingId,
      pageNumber: pageNumber ?? this.pageNumber,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      equipmentId: equipmentId ?? this.equipmentId,
      inspectionId: inspectionId ?? this.inspectionId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'drawing_id': drawingId,
      'page_number': pageNumber,
      'position_x': positionX,
      'position_y': positionY,
      'title': title,
      'description': description,
      'category': category.label,
      'priority': priority.label,
      'status': status.label,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'due_date': dueDate,
      'equipment_id': equipmentId,
      'inspection_id': inspectionId,
      'latitude': latitude,
      'longitude': longitude,
      'gps_accuracy': gpsAccuracy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Issue.fromMap(Map<String, dynamic> map) {
    return Issue(
      id: map['id'] as String,
      projectId: (map['project_id'] ?? map['projectId'] ?? '') as String,
      drawingId: (map['drawing_id'] ?? map['drawingId']) as String?,
      pageNumber: (map['page_number'] ?? map['pageNumber'] ?? 1) as int,
      positionX: map['position_x'] != null ? (map['position_x'] as num).toDouble() : null,
      positionY: map['position_y'] != null ? (map['position_y'] as num).toDouble() : null,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: IssueCategory.fromString((map['category']) as String?),
      priority: IssuePriority.fromString((map['priority'] ?? map['severity']) as String?),
      status: IssueStatus.fromString((map['status']) as String?),
      assignedTo: (map['assigned_to'] ?? map['assignedTo']) as String?,
      createdBy: (map['created_by'] ?? map['createdBy'] ?? 'Lead Engineer') as String,
      dueDate: (map['due_date'] ?? map['dueDate']) as String?,
      equipmentId: (map['equipment_id'] ?? map['equipmentId']) as String?,
      inspectionId: (map['inspection_id'] ?? map['inspectionId']) as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      gpsAccuracy: map['gps_accuracy'] != null ? (map['gps_accuracy'] as num).toDouble() : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : (map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()),
    );
  }
}
