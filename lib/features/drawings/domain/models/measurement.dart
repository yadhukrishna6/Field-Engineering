import 'dart:convert';
import 'package:flutter/material.dart';
import 'markup.dart';

enum MeasurementType {
  distance,
  polylineDistance,
  area,
  angle,
  radius,
  diameter,
  count,
  perimeter,
}

extension MeasurementTypeExtension on MeasurementType {
  String get displayName {
    switch (this) {
      case MeasurementType.distance:
        return 'Distance Dimension';
      case MeasurementType.polylineDistance:
        return 'Polyline Distance';
      case MeasurementType.area:
        return 'Area Measurement';
      case MeasurementType.angle:
        return 'Angle Dimension';
      case MeasurementType.radius:
        return 'Radius (R)';
      case MeasurementType.diameter:
        return 'Diameter (Ø)';
      case MeasurementType.count:
        return 'Component Counter';
      case MeasurementType.perimeter:
        return 'Perimeter Loop';
    }
  }

  IconData get icon {
    switch (this) {
      case MeasurementType.distance:
        return Icons.straighten_rounded;
      case MeasurementType.polylineDistance:
        return Icons.timeline_rounded;
      case MeasurementType.area:
        return Icons.texture_rounded;
      case MeasurementType.angle:
        return Icons.turn_right_rounded;
      case MeasurementType.radius:
        return Icons.radio_button_unchecked_rounded;
      case MeasurementType.diameter:
        return Icons.trip_origin_rounded;
      case MeasurementType.count:
        return Icons.pin_drop_rounded;
      case MeasurementType.perimeter:
        return Icons.crop_free_rounded;
    }
  }

  String get shortCode {
    switch (this) {
      case MeasurementType.distance:
        return 'DIST';
      case MeasurementType.polylineDistance:
        return 'POLY';
      case MeasurementType.area:
        return 'AREA';
      case MeasurementType.angle:
        return 'ANG';
      case MeasurementType.radius:
        return 'RAD';
      case MeasurementType.diameter:
        return 'DIA';
      case MeasurementType.count:
        return 'CNT';
      case MeasurementType.perimeter:
        return 'PERI';
    }
  }

  String get description {
    switch (this) {
      case MeasurementType.distance:
        return '2-point linear dimension';
      case MeasurementType.polylineDistance:
        return 'Multi-segment continuous path';
      case MeasurementType.area:
        return 'Closed boundary polygon area';
      case MeasurementType.angle:
        return '3-point vertex angular dimension';
      case MeasurementType.radius:
        return 'Radial dimension from center to arc';
      case MeasurementType.diameter:
        return 'Diameter across circular feature';
      case MeasurementType.count:
        return 'Sequential component tagging badge';
      case MeasurementType.perimeter:
        return 'Total perimeter loop length';
    }
  }
}

class Measurement {
  final String id;
  final String drawingId;
  final int pageNumber;
  final MeasurementType type;
  final List<Point2D> points;
  final double calculatedValue;
  final String unit; // mm, cm, m, in, ft, mm², m², sq ft, deg, count
  final String? calibrationId;
  final String? label;
  final Color color;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const Measurement({
    required this.id,
    required this.drawingId,
    this.pageNumber = 1,
    required this.type,
    required this.points,
    required this.calculatedValue,
    required this.unit,
    this.calibrationId,
    this.label,
    this.color = const Color(0xFF0288D1), // Engineering Blue / Cyan
    this.metadata,
    required this.createdAt,
  });

  String get countLabel => (metadata?['componentName'] as String?) ?? label ?? 'Item';

  Measurement copyWith({
    String? id,
    String? drawingId,
    int? pageNumber,
    MeasurementType? type,
    List<Point2D>? points,
    double? calculatedValue,
    String? unit,
    String? calibrationId,
    String? label,
    Color? color,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return Measurement(
      id: id ?? this.id,
      drawingId: drawingId ?? this.drawingId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      points: points ?? this.points,
      calculatedValue: calculatedValue ?? this.calculatedValue,
      unit: unit ?? this.unit,
      calibrationId: calibrationId ?? this.calibrationId,
      label: label ?? this.label,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedDisplay {
    if (label != null && label!.isNotEmpty) {
      return '$label: ${formatValueWithUnit()}';
    }
    return formatValueWithUnit();
  }

  String formatValueWithUnit() {
    switch (type) {
      case MeasurementType.distance:
      case MeasurementType.polylineDistance:
      case MeasurementType.perimeter:
        if (unit == 'm' || unit == 'ft') {
          return '${calculatedValue.toStringAsFixed(2)} $unit';
        } else if (unit == 'in' || unit == 'cm') {
          return '${calculatedValue.toStringAsFixed(1)} $unit';
        } else {
          return '${calculatedValue.round()} $unit';
        }
      case MeasurementType.area:
        if (unit == 'm²' || unit == 'sq ft') {
          return '${calculatedValue.toStringAsFixed(2)} $unit';
        }
        return '${calculatedValue.toStringAsFixed(1)} $unit';
      case MeasurementType.angle:
        return '${calculatedValue.toStringAsFixed(1)}°';
      case MeasurementType.radius:
        final prefix = 'R = ';
        if (unit == 'm' || unit == 'ft') {
          return '$prefix${calculatedValue.toStringAsFixed(2)} $unit';
        }
        return '$prefix${calculatedValue.round()} $unit';
      case MeasurementType.diameter:
        final prefix = 'Ø ';
        if (unit == 'm' || unit == 'ft') {
          return '$prefix${calculatedValue.toStringAsFixed(2)} $unit';
        }
        return '$prefix${calculatedValue.round()} $unit';
      case MeasurementType.count:
        final tag = metadata?['componentName'] ?? 'Items';
        return '$tag: ${calculatedValue.toInt()}';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drawing_id': drawingId,
      'page_number': pageNumber,
      'type': type.name,
      'points_data': jsonEncode(points.map((p) => p.toMap()).toList()),
      'calculated_value': calculatedValue,
      'unit': unit,
      'calibration_id': calibrationId,
      'label': label,
      'color': color.value,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    List<Point2D> pts = [];
    if (map['points_data'] != null && map['points_data'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['points_data'] as String) as List<dynamic>;
        pts = decoded.map((p) => Point2D.fromMap(p as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    Map<String, dynamic>? meta;
    if (map['metadata'] != null && map['metadata'].toString().isNotEmpty) {
      try {
        meta = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return Measurement(
      id: map['id'] as String,
      drawingId: map['drawing_id'] as String,
      pageNumber: (map['page_number'] as num?)?.toInt() ?? 1,
      type: MeasurementType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => MeasurementType.distance,
      ),
      points: pts,
      calculatedValue: (map['calculated_value'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'mm',
      calibrationId: map['calibration_id'] as String?,
      label: map['label'] as String?,
      color: Color((map['color'] as num?)?.toInt() ?? 0xFF0288D1),
      metadata: meta,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
