enum IssueSeverity { low, medium, high, critical }
enum IssueStatus { open, inProgress, resolved, closed }

class Issue {
  final String id;
  final String projectId;
  final String? drawingId;
  final String title;
  final String description;
  final IssueSeverity severity;
  final IssueStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Issue({
    required this.id,
    required this.projectId,
    this.drawingId,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'drawingId': drawingId,
      'title': title,
      'description': description,
      'severity': severity.name,
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Issue.fromMap(Map<String, dynamic> map) {
    return Issue(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      drawingId: map['drawingId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String,
      severity: IssueSeverity.values.firstWhere((e) => e.name == map['severity'], orElse: () => IssueSeverity.medium),
      status: IssueStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => IssueStatus.open),
      createdBy: map['createdBy'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
