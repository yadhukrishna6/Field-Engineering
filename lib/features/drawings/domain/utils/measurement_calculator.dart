import 'dart:math' as math;
import '../models/markup.dart';
import '../models/measurement.dart';
import '../models/drawing_calibration.dart';

class MeasurementCalculator {
  /// Calculate real-world measurement value based on calibration scale
  static double calculateValue({
    required MeasurementType type,
    required List<Point2D> points,
    required DrawingCalibration calibration,
  }) {
    if (points.isEmpty) return 0.0;

    switch (type) {
      case MeasurementType.distance:
        if (points.length < 2) return 0.0;
        final dNorm = distanceBetween(points[0], points[1]);
        return calibration.normalizedToRealDistance(dNorm);

      case MeasurementType.polylineDistance:
        if (points.length < 2) return 0.0;
        double totalNorm = 0.0;
        for (int i = 0; i < points.length - 1; i++) {
          totalNorm += distanceBetween(points[i], points[i + 1]);
        }
        return calibration.normalizedToRealDistance(totalNorm);

      case MeasurementType.area:
        if (points.length < 3) return 0.0;
        final areaNorm = polygonArea(points);
        return calibration.normalizedToRealArea(areaNorm);

      case MeasurementType.angle:
        if (points.length < 3) return 0.0;
        // P0: Arm 1, P1: Vertex, P2: Arm 2
        return angleBetweenThreePoints(points[0], points[1], points[2]);

      case MeasurementType.radius:
        if (points.length < 2) return 0.0;
        final rNorm = distanceBetween(points[0], points[1]);
        return calibration.normalizedToRealDistance(rNorm);

      case MeasurementType.diameter:
        if (points.length < 2) return 0.0;
        final dNorm = distanceBetween(points[0], points[1]);
        return calibration.normalizedToRealDistance(dNorm);

      case MeasurementType.perimeter:
        if (points.length < 2) return 0.0;
        double periNorm = 0.0;
        for (int i = 0; i < points.length; i++) {
          periNorm += distanceBetween(points[i], points[(i + 1) % points.length]);
        }
        return calibration.normalizedToRealDistance(periNorm);

      case MeasurementType.count:
        return points.length.toDouble();
    }
  }

  /// Euclidean distance between two normalized points
  static double distanceBetween(Point2D p1, Point2D p2) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Polygon area using Shoelace algorithm (in normalized square units)
  static double polygonArea(List<Point2D> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }

    return (area.abs()) / 2.0;
  }

  /// Angle in degrees at vertex P1 formed by arms P0-P1 and P2-P1
  static double angleBetweenThreePoints(Point2D p0, Point2D p1, Point2D p2) {
    final v1x = p0.x - p1.x;
    final v1y = p0.y - p1.y;
    final v2x = p2.x - p1.x;
    final v2y = p2.y - p1.y;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);

    if (mag1 < 0.00001 || mag2 < 0.00001) return 0.0;

    final cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final radians = math.acos(cosTheta);
    return (radians * 180.0) / math.pi;
  }

  /// Formatted unit symbol according to measurement type and calibration
  static String getUnitSymbol(MeasurementType type, DrawingCalibration calibration) {
    switch (type) {
      case MeasurementType.distance:
      case MeasurementType.polylineDistance:
      case MeasurementType.radius:
      case MeasurementType.diameter:
      case MeasurementType.perimeter:
        return calibration.unit.symbol;
      case MeasurementType.area:
        return calibration.unit.areaSymbol;
      case MeasurementType.angle:
        return 'deg';
      case MeasurementType.count:
        return 'count';
    }
  }
}
