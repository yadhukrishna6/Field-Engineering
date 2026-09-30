class EquipmentItem {
  final String id;
  final String projectId;
  final String equipmentNumber;
  final String tagNumber;
  final String name;
  final String type; // e.g., Pump, Vessel, Exchanger, Compressor, Tank, Valve, Transformer
  final String? location;
  final String? drawingId;
  final String? notes;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EquipmentItem({
    required this.id,
    required this.projectId,
    required this.equipmentNumber,
    required this.tagNumber,
    required this.name,
    required this.type,
    this.location,
    this.drawingId,
    this.notes,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.status = 'Operational',
    required this.createdAt,
    required this.updatedAt,
  });

  EquipmentItem copyWith({
    String? id,
    String? projectId,
    String? equipmentNumber,
    String? tagNumber,
    String? name,
    String? type,
    String? location,
    String? drawingId,
    String? notes,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      equipmentNumber: equipmentNumber ?? this.equipmentNumber,
      tagNumber: tagNumber ?? this.tagNumber,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      drawingId: drawingId ?? this.drawingId,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'equipment_number': equipmentNumber,
      'tag_number': tagNumber,
      'name': name,
      'drawing_type': type,
      'location': location,
      'drawing_id': drawingId,
      'notes': notes,
      'photo_path': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EquipmentItem.fromMap(Map<String, dynamic> map) {
    return EquipmentItem(
      id: map['id'] as String,
      projectId: (map['project_id'] ?? map['projectId'] ?? '') as String,
      equipmentNumber: (map['equipment_number'] ?? map['equipmentNumber'] ?? '') as String,
      tagNumber: (map['tag_number'] ?? map['tagNumber'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      type: (map['drawing_type'] ?? map['type'] ?? 'General') as String,
      location: (map['location']) as String?,
      drawingId: (map['drawing_id'] ?? map['drawingId']) as String?,
      notes: (map['notes']) as String?,
      photoPath: (map['photo_path'] ?? map['photoPath']) as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      status: (map['status'] ?? 'Operational') as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
