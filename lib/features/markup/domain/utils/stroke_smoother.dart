import 'dart:math' as math;
import 'dart:ui';
import '../models/point_2d.dart';

class StrokeSmoother {
  /// Catmull-Rom spline interpolation converted to GPU-accelerated cubic Bezier path
  static Path createSmoothPath(List<Point2D> points, Size size) {
    final path = Path();
    if (points.isEmpty) return path;

    final offsets = points.map((p) => p.toOffset(size)).toList();
    if (offsets.length == 1) {
      path.addOval(Rect.fromCircle(center: offsets[0], radius: 1.0));
      return path;
    }

    if (offsets.length == 2) {
      path.moveTo(offsets[0].dx, offsets[0].dy);
      path.lineTo(offsets[1].dx, offsets[1].dy);
      return path;
    }

    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = i > 0 ? offsets[i - 1] : offsets[i];
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final p3 = (i + 2 < offsets.length) ? offsets[i + 2] : p2;

      // Catmull-Rom to Cubic Bezier control points conversion formula:
      // CP1 = P1 + (P2 - P0) / 6
      // CP2 = P2 - (P3 - P1) / 6
      final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6.0, p1.dy + (p2.dy - p0.dy) / 6.0);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6.0, p2.dy - (p3.dy - p1.dy) / 6.0);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  /// Ramer-Douglas-Peucker (RDP) point decimation
  static List<Point2D> simplifyRDP(List<Point2D> points, {double epsilon = 0.001}) {
    if (points.length < 3) return points;

    int maxIndex = 0;
    double maxDist = 0;

    final first = points.first;
    final last = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final dist = _perpendicularDistance(points[i], first, last);
      if (dist > maxDist) {
        maxDist = dist;
        maxIndex = i;
      }
    }

    if (maxDist > epsilon) {
      final left = simplifyRDP(points.sublist(0, maxIndex + 1), epsilon: epsilon);
      final right = simplifyRDP(points.sublist(maxIndex), epsilon: epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [first, last];
    }
  }

  static double _perpendicularDistance(Point2D p, Point2D lineStart, Point2D lineEnd) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;
    final lengthSq = dx * dx + dy * dy;
    if (lengthSq == 0) {
      return math.sqrt(math.pow(p.x - lineStart.x, 2) + math.pow(p.y - lineStart.y, 2));
    }
    final t = ((p.x - lineStart.x) * dx + (p.y - lineStart.y) * dy) / lengthSq;
    final clampedT = t.clamp(0.0, 1.0);
    final projX = lineStart.x + clampedT * dx;
    final projY = lineStart.y + clampedT * dy;
    return math.sqrt(math.pow(p.x - projX, 2) + math.pow(p.y - projY, 2));
  }
}
