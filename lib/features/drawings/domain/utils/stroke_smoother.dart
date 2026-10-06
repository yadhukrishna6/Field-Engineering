import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/markup.dart';

/// Catmull-Rom Spline Smoother, Point Decimator & Collision Detector
/// Provides high-precision digital stylus ("LED pen") curve smoothing,
/// stroke-level eraser collision detection, and rotation snapping.
class StrokeSmoother {
  /// Converts raw control points into Catmull-Rom smoothed spline points.
  static List<Point2D> smoothPoints(
    List<Point2D> points, {
    int subdivisions = 4,
  }) {
    if (points.length < 3) return List<Point2D>.from(points);

    final List<Point2D> result = [];
    final int count = points.length;

    for (int i = 0; i < count - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < count ? points[i + 2] : p2;

      for (int step = 0; step < subdivisions; step++) {
        final double t = step / subdivisions;
        final double t2 = t * t;
        final double t3 = t2 * t;

        // Standard Catmull-Rom Spline equation:
        // Q(t) = 0.5 * ((2*P1) + (-P0 + P2)*t + (2*P0 - 5*P1 + 4*P2 - P3)*t^2 + (-P0 + 3*P1 - 3*P2 + P3)*t^3)
        final double x = 0.5 *
            ((2 * p1.x) +
                (-p0.x + p2.x) * t +
                (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
                (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3);

        final double y = 0.5 *
            ((2 * p1.y) +
                (-p0.y + p2.y) * t +
                (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
                (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3);

        result.add(Point2D(x, y));
      }
    }

    result.add(points.last);
    return result;
  }

  /// Converts points directly into a smooth hardware-accelerated Flutter [Path]
  /// using Catmull-Rom to Cubic Bezier conversion for 120fps GPU drawing.
  static Path createSmoothPath(List<Point2D> points, Size canvasSize) {
    final path = Path();
    if (points.isEmpty) return path;

    final first = points.first.toOffset(canvasSize);
    if (points.length == 1) {
      path.moveTo(first.dx, first.dy);
      path.lineTo(first.dx + 0.1, first.dy + 0.1);
      return path;
    }

    if (points.length == 2) {
      final second = points.last.toOffset(canvasSize);
      path.moveTo(first.dx, first.dy);
      path.lineTo(second.dx, second.dy);
      return path;
    }

    path.moveTo(first.dx, first.dy);
    final count = points.length;

    for (int i = 0; i < count - 1; i++) {
      final p0Point = i > 0 ? points[i - 1] : points[i];
      final p1Point = points[i];
      final p2Point = points[i + 1];
      final p3Point = i + 2 < count ? points[i + 2] : p2Point;

      final p0 = p0Point.toOffset(canvasSize);
      final p1 = p1Point.toOffset(canvasSize);
      final p2 = p2Point.toOffset(canvasSize);
      final p3 = p3Point.toOffset(canvasSize);

      // Conversion of Catmull-Rom control points to cubic Bezier control points:
      // CP1 = P1 + (P2 - P0) / 6
      // CP2 = P2 - (P3 - P1) / 6
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6.0,
        p1.dy + (p2.dy - p0.dy) / 6.0,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6.0,
        p2.dy - (p3.dy - p1.dy) / 6.0,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  /// Ramer-Douglas-Peucker (RDP) algorithm for point reduction / decimation.
  /// Cleans up redundant sample jitter from fast stylus movements.
  static List<Point2D> simplifyRDP(List<Point2D> points, {double epsilon = 0.0015}) {
    if (points.length < 3) return List<Point2D>.from(points);

    double maxDistance = 0.0;
    int index = 0;
    final int end = points.length - 1;

    for (int i = 1; i < end; i++) {
      final double dist = perpendicularDistance(points[i], points[0], points[end]);
      if (dist > maxDistance) {
        maxDistance = dist;
        index = i;
      }
    }

    if (maxDistance > epsilon) {
      final recResults1 = simplifyRDP(points.sublist(0, index + 1), epsilon: epsilon);
      final recResults2 = simplifyRDP(points.sublist(index, end + 1), epsilon: epsilon);

      return [...recResults1.sublist(0, recResults1.length - 1), ...recResults2];
    } else {
      return [points[0], points[end]];
    }
  }

  /// Calculates perpendicular distance from point P to line AB in normalized space.
  static double perpendicularDistance(Point2D p, Point2D a, Point2D b) {
    final double dx = b.x - a.x;
    final double dy = b.y - a.y;
    final double lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      final double pdx = p.x - a.x;
      final double pdy = p.y - a.y;
      return math.sqrt(pdx * pdx + pdy * pdy);
    }

    final double num = ((p.x - a.x) * dy - (p.y - a.y) * dx).abs();
    return num / math.sqrt(lengthSquared);
  }

  /// Calculates minimum Euclidean distance from point P to line segment AB.
  static double distanceToSegment(Point2D p, Point2D a, Point2D b) {
    final double dx = b.x - a.x;
    final double dy = b.y - a.y;
    final double lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      final double pdx = p.x - a.x;
      final double pdy = p.y - a.y;
      return math.sqrt(pdx * pdx + pdy * pdy);
    }

    // Projection parameter t clamped to segment [0, 1]
    final double t = math.max(
      0.0,
      math.min(1.0, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared),
    );

    final double projX = a.x + t * dx;
    final double projY = a.y + t * dy;

    final double distDx = p.x - projX;
    final double distDy = p.y - projY;
    return math.sqrt(distDx * distDx + distDy * distDy);
  }

  /// Tests if a markup is hit by the eraser at [hitPoint] with radius [normalizedRadius].
  static bool isMarkupHit(
    Markup markup,
    Point2D hitPoint,
    double normalizedRadius,
  ) {
    // 1. Check text / bounds
    if (markup.bounds != null) {
      final expandedBounds = markup.bounds!.inflate(normalizedRadius);
      if (expandedBounds.contains(Offset(hitPoint.x, hitPoint.y))) {
        return true;
      }
    }

    // 2. Check points & segments (pen strokes, lines, polylines, leader arrows)
    final points = markup.points;
    if (points.isEmpty) return false;

    if (points.length == 1) {
      final dx = points[0].x - hitPoint.x;
      final dy = points[0].y - hitPoint.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      return dist <= normalizedRadius;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final dist = distanceToSegment(hitPoint, points[i], points[i + 1]);
      if (dist <= normalizedRadius) {
        return true;
      }
    }

    // Check leader arrow endpoint if present
    if (markup.leaderPoint != null && points.isNotEmpty) {
      final dist = distanceToSegment(hitPoint, points.first, markup.leaderPoint!);
      if (dist <= normalizedRadius) {
        return true;
      }
    }

    return false;
  }

  /// Snaps rotation angles in degrees to common engineering angles (0, 30, 60, 90, etc.)
  static double snapRotationDegrees(
    double angleDegrees, {
    List<double> snapAngles = const [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360],
    double toleranceDegrees = 8.0,
  }) {
    final normalized = (angleDegrees % 360 + 360) % 360;
    for (final snap in snapAngles) {
      if ((normalized - snap).abs() <= toleranceDegrees ||
          (normalized - (snap + 360)).abs() <= toleranceDegrees) {
        return snap % 360;
      }
    }
    return normalized;
  }

  /// Snaps rotation angles in radians
  static double snapRotationRadians(double radians, {double toleranceDegrees = 8.0}) {
    final degrees = radians * 180.0 / math.pi;
    final snappedDegrees = snapRotationDegrees(degrees, toleranceDegrees: toleranceDegrees);
    return snappedDegrees * math.pi / 180.0;
  }
}
