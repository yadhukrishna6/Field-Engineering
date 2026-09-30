enum EquipmentStatus { operational, inInspection, maintenanceRequired, decommissioned }

class Equipment {
  final String id;
  final String projectId;
  final String tagNumber;
  final String name;
  final String category;
  final String? designPressure;
  final String? designTemperature;
  final EquipmentStatus status;
  final DateTime lastInspectedDate;
  final DateTime nextInspectionDue;

  const Equipment({
    required this.id,
    required this.projectId,
    required this.tagNumber,
    required this.name,
    required this.category,
    this.designPressure,
    this.designTemperature,
    required this.status,
    required this.lastInspectedDate,
    required this.nextInspectionDue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'tagNumber': tagNumber,
      'name': name,
      'category': category,
      'designPressure': designPressure,
      'designTemperature': designTemperature,
      'status': status.name,
      'lastInspectedDate': lastInspectedDate.toIso8601String(),
      'nextInspectionDue': nextInspectionDue.toIso8601String(),
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      tagNumber: map['tagNumber'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      designPressure: map['designPressure'] as String?,
      designTemperature: map['designTemperature'] as String?,
      status: EquipmentStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => EquipmentStatus.operational),
      lastInspectedDate: DateTime.parse(map['lastInspectedDate'] as String),
      nextInspectionDue: DateTime.parse(map['nextInspectionDue'] as String),
    );
  }
}
