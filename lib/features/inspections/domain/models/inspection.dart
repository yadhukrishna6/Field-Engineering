import 'package:uuid/uuid.dart';
import 'inspection_item.dart';

enum InspectionStatus {
  draft('Draft'),
  inProgress('In Progress'),
  completed('Completed'),
  approved('Approved');

  final String label;
  const InspectionStatus(this.label);

  static InspectionStatus fromString(String? val) {
    if (val == null) return InspectionStatus.draft;
    return InspectionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => InspectionStatus.draft,
    );
  }
}

class Inspection {
  final String id;
  final String projectId;
  final String? drawingId;
  final String? equipmentId;
  final String title;
  final String inspectionType;
  final InspectionStatus status;
  final String inspectorName;
  final String? inspectorSignaturePath;
  final String? clientSignaturePath;
  final DateTime inspectionDate;
  final String? summaryNotes;
  final double? latitude;
  final double? longitude;
  final List<InspectionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Inspection({
    required this.id,
    required this.projectId,
    this.drawingId,
    this.equipmentId,
    required this.title,
    required this.inspectionType,
    this.status = InspectionStatus.draft,
    required this.inspectorName,
    this.inspectorSignaturePath,
    this.clientSignaturePath,
    required this.inspectionDate,
    this.summaryNotes,
    this.latitude,
    this.longitude,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get passCount => items.where((i) => i.status == ChecklistStatus.pass).length;
  int get failCount => items.where((i) => i.status == ChecklistStatus.fail).length;
  int get pendingCount => items.where((i) => i.status == ChecklistStatus.pending).length;
  int get naCount => items.where((i) => i.status == ChecklistStatus.na).length;

  double get completionPercentage {
    if (items.isEmpty) return 0.0;
    final completed = items.where((i) => i.status != ChecklistStatus.pending).length;
    return completed / items.length;
  }

  Inspection copyWith({
    String? id,
    String? projectId,
    String? drawingId,
    String? equipmentId,
    String? title,
    String? inspectionType,
    InspectionStatus? status,
    String? inspectorName,
    String? inspectorSignaturePath,
    String? clientSignaturePath,
    DateTime? inspectionDate,
    String? summaryNotes,
    double? latitude,
    double? longitude,
    List<InspectionItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Inspection(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      drawingId: drawingId ?? this.drawingId,
      equipmentId: equipmentId ?? this.equipmentId,
      title: title ?? this.title,
      inspectionType: inspectionType ?? this.inspectionType,
      status: status ?? this.status,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectorSignaturePath: inspectorSignaturePath ?? this.inspectorSignaturePath,
      clientSignaturePath: clientSignaturePath ?? this.clientSignaturePath,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      summaryNotes: summaryNotes ?? this.summaryNotes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'drawing_id': drawingId,
      'equipment_id': equipmentId,
      'title': title,
      'inspection_type': inspectionType,
      'status': status.label,
      'inspector_name': inspectorName,
      'inspector_signature_path': inspectorSignaturePath,
      'client_signature_path': clientSignaturePath,
      'inspection_date': inspectionDate.toIso8601String(),
      'summary_notes': summaryNotes,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map, {List<InspectionItem> items = const []}) {
    return Inspection(
      id: map['id'] as String,
      projectId: (map['project_id'] ?? map['projectId']) as String,
      drawingId: (map['drawing_id'] ?? map['drawingId']) as String?,
      equipmentId: (map['equipment_id'] ?? map['equipmentId']) as String?,
      title: (map['title'] ?? '') as String,
      inspectionType: (map['inspection_type'] ?? map['inspectionType'] ?? 'Piping') as String,
      status: InspectionStatus.fromString(map['status'] as String?),
      inspectorName: (map['inspector_name'] ?? map['inspectorName'] ?? 'QC Inspector') as String,
      inspectorSignaturePath: (map['inspector_signature_path'] ?? map['inspectorSignaturePath']) as String?,
      clientSignaturePath: (map['client_signature_path'] ?? map['clientSignaturePath']) as String?,
      inspectionDate: map['inspection_date'] != null
          ? DateTime.parse(map['inspection_date'] as String)
          : (map['inspectionDate'] != null ? DateTime.parse(map['inspectionDate'] as String) : DateTime.now()),
      summaryNotes: (map['summary_notes'] ?? map['summaryNotes']) as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      items: items,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Generates default standard inspection checklist items for a chosen template
  static List<InspectionItem> createTemplateItems({
    required String inspectionId,
    required String templateType,
  }) {
    const uuid = Uuid();

    switch (templateType.toLowerCase()) {
      case 'piping':
        return [
          'Pipe installed according to drawing',
          'Correct diameter',
          'Correct material',
          'Flange installed',
          'Valve installed',
          'Support installed',
          'Welding completed',
          'Insulation completed',
          'Painting completed',
          'Hydro test completed',
        ].asMap().entries.map((e) => InspectionItem(
          id: uuid.v4(),
          inspectionId: inspectionId,
          category: 'Piping',
          description: e.value,
          status: ChecklistStatus.pending,
          orderIndex: e.key,
        )).toList();

      case 'mechanical':
        return [
          'Foundation & baseplate alignment verified',
          'Anchor bolts tightened to specified torque',
          'Shaft laser alignment within tolerance',
          'Coupling and guard installed properly',
          'Mechanical seal flush plan connected',
          'Lubrication oil filled to correct level',
          'Nozzle load check & piping strain free',
          'Rotation direction checked prior to coupling',
          'Vibration baseline recording completed',
        ].asMap().entries.map((e) => InspectionItem(
          id: uuid.v4(),
          inspectionId: inspectionId,
          category: 'Mechanical',
          description: e.value,
          status: ChecklistStatus.pending,
          orderIndex: e.key,
        )).toList();

      case 'electrical':
        return [
          'Cable tray & conduit route according to layout',
          'Cable megger insulation resistance test',
          'Grounding and bonding loop resistance < 1 ohm',
          'Gland termination & explosion-proof seal integrity',
          'Panel wiring and wire tagging verified',
          'Circuit breaker ratings match single-line diagram',
          'Emergency Stop pushbuttons function tested',
        ].asMap().entries.map((e) => InspectionItem(
          id: uuid.v4(),
          inspectionId: inspectionId,
          category: 'Electrical',
          description: e.value,
          status: ChecklistStatus.pending,
          orderIndex: e.key,
        )).toList();

      case 'civil':
      case 'structural':
        return [
          'Soil compaction and subgrade verification',
          'Rebar placement, spacing & concrete cover check',
          'Concrete slump and test cylinder sampling',
          'Anchor bolt projection and centerlines',
          'Structural steel torque verification (A325/A490)',
          'Grouting under equipment baseplates complete',
          'Fireproofing application and DFT check',
        ].asMap().entries.map((e) => InspectionItem(
          id: uuid.v4(),
          inspectionId: inspectionId,
          category: 'Structural',
          description: e.value,
          status: ChecklistStatus.pending,
          orderIndex: e.key,
        )).toList();

      case 'safety':
      case 'hse':
        return [
          'Hot work / Confined space permits valid and posted',
          'Fire extinguishers inspected and positioned',
          'Scaffolding green-tagged and inspected',
          'Lockout / Tagout (LOTO) isolation verified',
          'Gas detectors calibrated and active (H2S/LEL/O2)',
          'Eye wash stations and safety showers tested',
          'Emergency egress routes clear of obstruction',
        ].asMap().entries.map((e) => InspectionItem(
          id: uuid.v4(),
          inspectionId: inspectionId,
          category: 'Safety',
          description: e.value,
          status: ChecklistStatus.pending,
          orderIndex: e.key,
        )).toList();

      default:
        return [
          'Scope of work verified against engineering drawing',
          'Material certificates and heat numbers verified',
          'Installation complies with site standards',
          'Safety clearances and access verified',
          'Final housekeeping and area clean-up',
        ].asMap().entries.map((e) => InspectionItem(
          id: uuid.v4(),
          inspectionId: inspectionId,
          category: 'General',
          description: e.value,
          status: ChecklistStatus.pending,
          orderIndex: e.key,
        )).toList();
    }
  }
}
