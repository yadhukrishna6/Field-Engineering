import 'project_status.dart';

class Project {
  final String id;
  final String projectNumber;
  final String name;
  final String description;
  final String client;
  final String location;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed / aggregated field properties (for rich tablet cards)
  final int drawingCount;
  final int downloadedCount;
  final int totalBytes;

  const Project({
    required this.id,
    required this.projectNumber,
    required this.name,
    required this.description,
    required this.client,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.drawingCount = 0,
    this.downloadedCount = 0,
    this.totalBytes = 0,
  });

  bool get isFullyDownloaded => drawingCount > 0 && downloadedCount >= drawingCount;
  double get downloadPercentage => drawingCount == 0 ? 1.0 : (downloadedCount / drawingCount).clamp(0.0, 1.0);

  Project copyWith({
    String? id,
    String? projectNumber,
    String? name,
    String? description,
    String? client,
    String? location,
    ProjectStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? drawingCount,
    int? downloadedCount,
    int? totalBytes,
  }) {
    return Project(
      id: id ?? this.id,
      projectNumber: projectNumber ?? this.projectNumber,
      name: name ?? this.name,
      description: description ?? this.description,
      client: client ?? this.client,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      drawingCount: drawingCount ?? this.drawingCount,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_number': projectNumber,
      'name': name,
      'description': description,
      'client': client,
      'location': location,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map, {
    int drawingCount = 0,
    int downloadedCount = 0,
    int totalBytes = 0,
  }) {
    return Project(
      id: map['id'] as String,
      projectNumber: map['project_number'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      client: map['client'] as String? ?? '',
      location: map['location'] as String? ?? '',
      status: ProjectStatusExtension.fromString(map['status'] as String? ?? 'active'),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      drawingCount: drawingCount,
      downloadedCount: downloadedCount,
      totalBytes: totalBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
