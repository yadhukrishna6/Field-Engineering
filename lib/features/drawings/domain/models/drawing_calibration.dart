import 'dart:math' as math;
import 'markup.dart';

enum CalibrationUnit {
  mm,
  cm,
  m,
  inch,
  ft,
}

extension CalibrationUnitExtension on CalibrationUnit {
  String get symbol {
    switch (this) {
      case CalibrationUnit.mm:
        return 'mm';
      case CalibrationUnit.cm:
        return 'cm';
      case CalibrationUnit.m:
        return 'm';
      case CalibrationUnit.inch:
        return 'in';
      case CalibrationUnit.ft:
        return 'ft';
    }
  }

  String get displayName {
    switch (this) {
      case CalibrationUnit.mm:
        return 'Millimeters (mm)';
      case CalibrationUnit.cm:
        return 'Centimeters (cm)';
      case CalibrationUnit.m:
        return 'Meters (m)';
      case CalibrationUnit.inch:
        return 'Inches (in)';
      case CalibrationUnit.ft:
        return 'Feet (ft)';
    }
  }

  String get areaSymbol {
    switch (this) {
      case CalibrationUnit.mm:
        return 'mm²';
      case CalibrationUnit.cm:
        return 'cm²';
      case CalibrationUnit.m:
        return 'm²';
      case CalibrationUnit.inch:
        return 'sq in';
      case CalibrationUnit.ft:
        return 'sq ft';
    }
  }

  /// Conversion factor from this unit to millimeters
  double get toMmFactor {
    switch (this) {
      case CalibrationUnit.mm:
        return 1.0;
      case CalibrationUnit.cm:
        return 10.0;
      case CalibrationUnit.m:
        return 1000.0;
      case CalibrationUnit.inch:
        return 25.4;
      case CalibrationUnit.ft:
        return 304.8;
    }
  }

  static CalibrationUnit fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'mm':
      case 'millimeters':
        return CalibrationUnit.mm;
      case 'cm':
      case 'centimeters':
        return CalibrationUnit.cm;
      case 'm':
      case 'meters':
        return CalibrationUnit.m;
      case 'in':
      case 'inch':
      case 'inches':
        return CalibrationUnit.inch;
      case 'ft':
      case 'feet':
        return CalibrationUnit.ft;
      default:
        return CalibrationUnit.mm;
    }
  }
}

class DrawingCalibration {
  final String id;
  final String drawingId;
  final int pageNumber;
  final Point2D point1;
  final Point2D point2;
  final double knownDistance;
  final CalibrationUnit unit;
  final double scaleFactor; // Real units per normalized distance unit [0.0 - 1.0]
  final DateTime createdAt;
  final DateTime updatedAt;

  const DrawingCalibration({
    required this.id,
    required this.drawingId,
    this.pageNumber = 1,
    required this.point1,
    required this.point2,
    required this.knownDistance,
    required this.unit,
    required this.scaleFactor,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculates scale factor from two normalized points and a known real distance
  factory DrawingCalibration.fromPoints({
    required String id,
    required String drawingId,
    int pageNumber = 1,
    required Point2D point1,
    required Point2D point2,
    required double knownDistance,
    required CalibrationUnit unit,
  }) {
    final dx = point2.x - point1.x;
    final dy = point2.y - point1.y;
    final normalizedDist = math.sqrt(dx * dx + dy * dy);

    final scaleFactor = normalizedDist > 0.0001 ? (knownDistance / normalizedDist) : 1000.0;

    return DrawingCalibration(
      id: id,
      drawingId: drawingId,
      pageNumber: pageNumber,
      point1: point1,
      point2: point2,
      knownDistance: knownDistance,
      unit: unit,
      scaleFactor: scaleFactor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Default fallback scale (assuming 1:50 scale on standard A3 landscape drawing ~ 21000mm total width)
  factory DrawingCalibration.defaultScale(String drawingId, {int pageNumber = 1}) {
    return DrawingCalibration(
      id: 'default_$drawingId',
      drawingId: drawingId,
      pageNumber: pageNumber,
      point1: const Point2D(0.0, 0.0),
      point2: const Point2D(1.0, 0.0),
      knownDistance: 21000.0, // 21 meters across A3 blueprint at 1:50
      unit: CalibrationUnit.mm,
      scaleFactor: 21000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert normalized distance (dx, dy) to calibrated real-world distance
  double normalizedToRealDistance(double normalizedDistance) {
    return normalizedDistance * scaleFactor;
  }

  /// Convert normalized area to calibrated real-world area
  double normalizedToRealArea(double normalizedArea) {
    return normalizedArea * scaleFactor * scaleFactor;
  }

  /// Formats real distance with appropriate precision
  String formatDistance(double realValue, {CalibrationUnit? targetUnit}) {
    final u = targetUnit ?? unit;
    if (u == CalibrationUnit.m) {
      return '${realValue.toStringAsFixed(2)} m';
    } else if (u == CalibrationUnit.ft) {
      return '${realValue.toStringAsFixed(2)} ft';
    } else if (u == CalibrationUnit.inch) {
      return '${realValue.toStringAsFixed(1)} in';
    } else if (u == CalibrationUnit.cm) {
      return '${realValue.toStringAsFixed(1)} cm';
    } else {
      return '${realValue.round()} mm';
    }
  }

  /// Formats real area with appropriate precision
  String formatArea(double realArea, {CalibrationUnit? targetUnit}) {
    final u = targetUnit ?? unit;
    if (u == CalibrationUnit.m) {
      return '${realArea.toStringAsFixed(2)} m²';
    } else if (u == CalibrationUnit.ft) {
      return '${realArea.toStringAsFixed(2)} sq ft';
    } else {
      return '${(realArea / (u.toMmFactor * u.toMmFactor)).toStringAsFixed(1)} ${u.areaSymbol}';
    }
  }

  /// Formatted scale string for badge display
  String formattedScale([String? targetUnit]) {
    return '${knownDistance.toStringAsFixed(0)} ${targetUnit ?? unit.symbol}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drawing_id': drawingId,
      'page_number': pageNumber,
      'point1_x': point1.x,
      'point1_y': point1.y,
      'point2_x': point2.x,
      'point2_y': point2.y,
      'known_distance': knownDistance,
      'unit': unit.symbol,
      'scale_factor': scaleFactor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DrawingCalibration.fromMap(Map<String, dynamic> map) {
    return DrawingCalibration(
      id: map['id'] as String,
      drawingId: map['drawing_id'] as String,
      pageNumber: (map['page_number'] as num?)?.toInt() ?? 1,
      point1: Point2D(
        (map['point1_x'] as num).toDouble(),
        (map['point1_y'] as num).toDouble(),
      ),
      point2: Point2D(
        (map['point2_x'] as num).toDouble(),
        (map['point2_y'] as num).toDouble(),
      ),
      knownDistance: (map['known_distance'] as num).toDouble(),
      unit: CalibrationUnitExtension.fromString(map['unit'] as String? ?? 'mm'),
      scaleFactor: (map['scale_factor'] as num).toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
