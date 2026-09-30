import 'package:flutter/material.dart';

enum TakeoffItemType {
  pipe,
  valve,
  flange,
  elbow,
  tee,
  reducer,
  support,
  equipment,
  custom,
}

extension TakeoffItemTypeExtension on TakeoffItemType {
  String get displayName {
    switch (this) {
      case TakeoffItemType.pipe:
        return 'Piping Spool';
      case TakeoffItemType.valve:
        return 'Valve';
      case TakeoffItemType.flange:
        return 'Flange';
      case TakeoffItemType.elbow:
        return 'Elbow / Bend';
      case TakeoffItemType.tee:
        return 'Tee Fitting';
      case TakeoffItemType.reducer:
        return 'Reducer';
      case TakeoffItemType.support:
        return 'Pipe Support / Hanger';
      case TakeoffItemType.equipment:
        return 'Vessel / Equipment';
      case TakeoffItemType.custom:
        return 'Custom Component';
    }
  }

  IconData get icon {
    switch (this) {
      case TakeoffItemType.pipe:
        return Icons.linear_scale_rounded;
      case TakeoffItemType.valve:
        return Icons.adjust_rounded;
      case TakeoffItemType.flange:
        return Icons.radio_button_checked_rounded;
      case TakeoffItemType.elbow:
        return Icons.turn_sharp_right_rounded;
      case TakeoffItemType.tee:
        return Icons.call_split_rounded;
      case TakeoffItemType.reducer:
        return Icons.filter_list_rounded;
      case TakeoffItemType.support:
        return Icons.foundation_rounded;
      case TakeoffItemType.equipment:
        return Icons.inventory_2_rounded;
      case TakeoffItemType.custom:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TakeoffItemType.pipe:
        return const Color(0xFF0288D1);
      case TakeoffItemType.valve:
        return const Color(0xFFD32F2F);
      case TakeoffItemType.flange:
        return const Color(0xFF7B1FA2);
      case TakeoffItemType.elbow:
        return const Color(0xFFF57C00);
      case TakeoffItemType.tee:
        return const Color(0xFF388E3C);
      case TakeoffItemType.reducer:
        return const Color(0xFF0097A7);
      case TakeoffItemType.support:
        return const Color(0xFF5D4037);
      case TakeoffItemType.equipment:
        return const Color(0xFFC2185B);
      case TakeoffItemType.custom:
        return const Color(0xFF455A64);
    }
  }
}

class TakeoffItem {
  final String id;
  final String projectId;
  final String? drawingId;
  final int pageNumber;
  final TakeoffItemType itemType;
  final String itemName;
  final String? specification;
  final String? size;
  final double quantity;
  final String unit; // m, pcs, sets, kg, ft, joints
  final double unitWeightKg;
  final double unitCost;
  final String? notes;
  final String? linkedCountTag;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TakeoffItem({
    required this.id,
    required this.projectId,
    this.drawingId,
    this.pageNumber = 1,
    required this.itemType,
    required this.itemName,
    this.specification,
    this.size,
    required this.quantity,
    this.unit = 'pcs',
    this.unitWeightKg = 0.0,
    this.unitCost = 0.0,
    this.notes,
    this.linkedCountTag,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalWeightKg => quantity * unitWeightKg;
  double get totalCost => quantity * unitCost;

  TakeoffItem copyWith({
    String? id,
    String? projectId,
    String? drawingId,
    int? pageNumber,
    TakeoffItemType? itemType,
    String? itemName,
    String? specification,
    String? size,
    double? quantity,
    String? unit,
    double? unitWeightKg,
    double? unitCost,
    String? notes,
    String? linkedCountTag,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TakeoffItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      drawingId: drawingId ?? this.drawingId,
      pageNumber: pageNumber ?? this.pageNumber,
      itemType: itemType ?? this.itemType,
      itemName: itemName ?? this.itemName,
      specification: specification ?? this.specification,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitWeightKg: unitWeightKg ?? this.unitWeightKg,
      unitCost: unitCost ?? this.unitCost,
      notes: notes ?? this.notes,
      linkedCountTag: linkedCountTag ?? this.linkedCountTag,
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
      'item_type': itemType.name,
      'item_name': itemName,
      'specification': specification,
      'size': size,
      'quantity': quantity,
      'unit': unit,
      'unit_weight_kg': unitWeightKg,
      'unit_cost': unitCost,
      'notes': notes,
      'linked_count_tag': linkedCountTag,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TakeoffItem.fromMap(Map<String, dynamic> map) {
    return TakeoffItem(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      drawingId: map['drawing_id'] as String?,
      pageNumber: (map['page_number'] as num?)?.toInt() ?? 1,
      itemType: TakeoffItemType.values.firstWhere(
        (t) => t.name == map['item_type'],
        orElse: () => TakeoffItemType.pipe,
      ),
      itemName: map['item_name'] as String? ?? 'Unnamed Item',
      specification: map['specification'] as String?,
      size: map['size'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] as String? ?? 'pcs',
      unitWeightKg: (map['unit_weight_kg'] as num?)?.toDouble() ?? 0.0,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      linkedCountTag: map['linked_count_tag'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
