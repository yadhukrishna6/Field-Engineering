import 'dart:math' as math;
import 'dart:ui';
import '../models/annotation_item.dart';
import '../models/markup_layer.dart';
import '../models/point_2d.dart';
import '../models/snap_config.dart';

class BeautifiedResult {
  final AnnotationType type;
  final List<Point2D> points;
  final bool didSnap;
  final double? snappedAngle;
  final Map<String, dynamic>? metadata;

  const BeautifiedResult({
    required this.type,
    required this.points,
    this.didSnap = false,
    this.snappedAngle,
    this.metadata,
  });
}

class StrokeBeautifier {
  /// Main entry point: Beautifies a raw stroke in under 16ms
  static BeautifiedResult beautify({
    required List<Point2D> rawPoints,
    required Color color,
    required double strokeWidth,
    required SnapConfig snapConfig,
    MarkupLayer layer = MarkupLayer.markups,
    AnnotationType? forcedType, // If user picked a specific Shape tool
  }) {
    if (rawPoints.length < 2) {
      return BeautifiedResult(
        type: AnnotationType.stroke,
        points: rawPoints,
        didSnap: false,
      );
    }

    // Step 1: Pre-process (resample to ~64 points, moving average, jitter drop)
    final resampled = _resample(rawPoints, targetCount: 64);
    final smoothed = _movingAverage(resampled, windowSize: 3);

    // If a shape is explicitly forced (Shapes tool)
    if (forcedType != null) {
      switch (forcedType) {
        case AnnotationType.line:
          return _fitLine(smoothed, rawPoints, snapConfig);
        case AnnotationType.arrow:
          return _fitArrow(smoothed, rawPoints, snapConfig);
        case AnnotationType.rectangle:
          return _fitRectangle(smoothed, rawPoints, snapConfig);
        case AnnotationType.cloud:
          return _fitCloud(smoothed, rawPoints, snapConfig);
        case AnnotationType.circle:
          return _fitCircle(smoothed, rawPoints);
        default:
          break;
      }
    }

    if (!snapConfig.isEnabled) {
      return BeautifiedResult(
        type: AnnotationType.stroke,
        points: smoothed,
        didSnap: false,
      );
    }

    final isClosed = _isClosedLoop(smoothed);

    // Step 2: Auto-Classification in strict reference order
    // Check 2.1: Line (must not be closed)
    if (!isClosed) {
      final lineResult = _tryClassifyLine(smoothed, rawPoints, snapConfig);
      if (lineResult != null) return lineResult;

      // Check 2.2: Arrow (must not be closed, shaft must be straight, last 15% sharp V)
      final arrowResult = _tryClassifyArrow(smoothed, rawPoints, snapConfig);
      if (arrowResult != null) return arrowResult;
    }

    // Check 2.3: Closed Loop (Rectangle, Circle, Revision Cloud)
    if (isClosed) {
      final rectResult = _tryClassifyRectangle(smoothed, rawPoints, snapConfig);
      if (rectResult != null) return rectResult;

      final circleResult = _tryClassifyCircle(smoothed, rawPoints);
      if (circleResult != null) return circleResult;

      // Any other closed loop -> Revision cloud
      return _fitCloud(smoothed, rawPoints, snapConfig);
    }

    // Otherwise: keep smoothed freehand stroke
    return BeautifiedResult(
      type: AnnotationType.stroke,
      points: smoothed,
      didSnap: false,
    );
  }

  // --- Step 1: Pre-processing Utilities ---

  static List<Point2D> _resample(List<Point2D> points, {int targetCount = 64}) {
    if (points.length <= 2) return List.from(points);

    double totalLength = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalLength += _dist(points[i], points[i + 1]);
    }

    if (totalLength <= 0.0001) return [points.first, points.last];

    final interval = totalLength / (targetCount - 1);
    final result = <Point2D>[points.first];

    double currentDist = 0.0;
    int srcIdx = 0;
    Point2D currentPt = points[0];

    while (result.length < targetCount - 1 && srcIdx < points.length - 1) {
      final nextPt = points[srcIdx + 1];
      final segLen = _dist(currentPt, nextPt);

      if (currentDist + segLen >= interval) {
        final t = (interval - currentDist) / (segLen == 0 ? 1 : segLen);
        final interpolated = Point2D(
          currentPt.x + t * (nextPt.x - currentPt.x),
          currentPt.y + t * (nextPt.y - currentPt.y),
        );
        result.add(interpolated);
        currentPt = interpolated;
        currentDist = 0.0;
      } else {
        currentDist += segLen;
        srcIdx++;
        currentPt = points[srcIdx];
      }
    }

    if (result.length < targetCount) {
      result.add(points.last);
    }
    return result;
  }

  static List<Point2D> _movingAverage(List<Point2D> points, {int windowSize = 3}) {
    if (points.length <= windowSize) return List.from(points);
    final smoothed = <Point2D>[];
    final half = windowSize ~/ 2;

    for (int i = 0; i < points.length; i++) {
      double sumX = 0.0;
      double sumY = 0.0;
      int count = 0;

      for (int w = -half; w <= half; w++) {
        final idx = i + w;
        if (idx >= 0 && idx < points.length) {
          sumX += points[idx].x;
          sumY += points[idx].y;
          count++;
        }
      }
      smoothed.add(Point2D(sumX / count, sumY / count));
    }
    return smoothed;
  }

  // --- Step 2: Classifiers ---

  static BeautifiedResult? _tryClassifyLine(
    List<Point2D> smoothed,
    List<Point2D> raw,
    SnapConfig snapConfig,
  ) {
    final start = smoothed.first;
    final end = smoothed.last;
    final chordLen = _dist(start, end);

    if (chordLen < 0.015) return null;

    double maxDeviation = 0.0;
    for (int i = 1; i < smoothed.length - 1; i++) {
      final dev = _perpDist(smoothed[i], start, end);
      if (dev > maxDeviation) maxDeviation = dev;
    }

    if (maxDeviation / chordLen <= 0.045) {
      return _fitLine(smoothed, raw, snapConfig);
    }
    return null;
  }

  static BeautifiedResult _fitLine(
    List<Point2D> smoothed,
    List<Point2D> raw,
    SnapConfig snapConfig,
  ) {
    final start = raw.first;
    final end = raw.last;

    if (!snapConfig.isEnabled) {
      return BeautifiedResult(
        type: AnnotationType.line,
        points: [start, end],
        didSnap: false,
      );
    }

    final snappedEnd = snapAngle(
      origin: start,
      target: end,
      axisSet: snapConfig.axisSet,
      toleranceDegrees: snapConfig.angleToleranceDegrees,
    );

    final didSnap = snappedEnd.x != end.x || snappedEnd.y != end.y;

    return BeautifiedResult(
      type: AnnotationType.line,
      points: [start, snappedEnd],
      didSnap: didSnap,
    );
  }

  static BeautifiedResult? _tryClassifyArrow(
    List<Point2D> smoothed,
    List<Point2D> raw,
    SnapConfig snapConfig,
  ) {
    if (smoothed.length < 8) return null;

    final n = smoothed.length;
    final shaftEndIdx = (n * 0.85).toInt();

    final shaftStart = smoothed.first;
    final shaftEnd = smoothed[shaftEndIdx];
    final tipPoint = smoothed.last;

    final shaftVecX = shaftEnd.x - shaftStart.x;
    final shaftVecY = shaftEnd.y - shaftStart.y;
    final headVecX = tipPoint.x - shaftEnd.x;
    final headVecY = tipPoint.y - shaftEnd.y;

    final shaftLen = math.sqrt(shaftVecX * shaftVecX + shaftVecY * shaftVecY);
    final headLen = math.sqrt(headVecX * headVecX + headVecY * headVecY);

    if (shaftLen < 0.02 || headLen < 0.005) return null;

    // Check that shaft itself is reasonably straight
    double maxShaftDev = 0.0;
    for (int i = 1; i < shaftEndIdx; i++) {
      final dev = _perpDist(smoothed[i], shaftStart, shaftEnd);
      if (dev > maxShaftDev) maxShaftDev = dev;
    }
    if (maxShaftDev / shaftLen > 0.08) return null;

    final dot = (shaftVecX * headVecX + shaftVecY * headVecY) / (shaftLen * headLen);
    final angleRad = math.acos(dot.clamp(-1.0, 1.0));
    final angleDeg = angleRad * 180 / math.pi;

    if (angleDeg >= 110.0) {
      return _fitArrow(smoothed, raw, snapConfig, detectedTip: shaftEnd);
    }

    return null;
  }

  static BeautifiedResult _fitArrow(
    List<Point2D> smoothed,
    List<Point2D> raw,
    SnapConfig snapConfig, {
    Point2D? detectedTip,
  }) {
    final start = raw.first;
    final rawEnd = detectedTip ?? raw.last;

    Point2D end = rawEnd;
    bool didSnap = false;

    if (snapConfig.isEnabled) {
      end = snapAngle(
        origin: start,
        target: rawEnd,
        axisSet: snapConfig.axisSet,
        toleranceDegrees: snapConfig.angleToleranceDegrees,
      );
      didSnap = end.x != rawEnd.x || end.y != rawEnd.y;
    }

    return BeautifiedResult(
      type: AnnotationType.arrow,
      points: [start, end],
      didSnap: didSnap,
    );
  }

  static bool _isClosedLoop(List<Point2D> points) {
    if (points.length < 5) return false;
    final start = points.first;
    final end = points.last;
    final directDist = _dist(start, end);

    double totalPerimeter = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalPerimeter += _dist(points[i], points[i + 1]);
    }

    return directDist <= totalPerimeter * 0.15 || directDist < 0.035;
  }

  static BeautifiedResult? _tryClassifyRectangle(
    List<Point2D> smoothed,
    List<Point2D> raw,
    SnapConfig snapConfig,
  ) {
    double minX = smoothed[0].x, maxX = smoothed[0].x;
    double minY = smoothed[0].y, maxY = smoothed[0].y;

    for (final p in smoothed) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final width = maxX - minX;
    final height = maxY - minY;
    final diag = math.sqrt(width * width + height * height);

    if (width < 0.02 || height < 0.02 || diag < 0.03) return null;

    // Measure mean distance to the 4 bounding box edges
    double totalEdgeDist = 0.0;
    for (final p in smoothed) {
      final dLeft = (p.x - minX).abs();
      final dRight = (p.x - maxX).abs();
      final dTop = (p.y - minY).abs();
      final dBottom = (p.y - maxY).abs();
      final minEdge = math.min(math.min(dLeft, dRight), math.min(dTop, dBottom));
      totalEdgeDist += minEdge;
    }

    final meanEdgeDist = totalEdgeDist / smoothed.length;

    // True rectangle has points concentrated along the 4 edges (< 4.5% of diagonal)
    if (meanEdgeDist / diag <= 0.045) {
      return _fitRectangle(smoothed, raw, snapConfig);
    }

    return null;
  }

  static BeautifiedResult _fitRectangle(
    List<Point2D> smoothed,
    List<Point2D> raw,
    SnapConfig snapConfig,
  ) {
    double minX = raw[0].x, maxX = raw[0].x;
    double minY = raw[0].y, maxY = raw[0].y;

    for (final p in raw) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final isIsometric = snapConfig.axisSet == SnapAxisSet.isometric;

    List<Point2D> rectPoints;
    if (isIsometric && snapConfig.isEnabled) {
      final dy = (maxY - minY);
      final skewOffset = dy * math.tan(30 * math.pi / 180) * 0.5;

      rectPoints = [
        Point2D(minX + skewOffset, minY),
        Point2D(maxX + skewOffset, minY),
        Point2D(maxX - skewOffset, maxY),
        Point2D(minX - skewOffset, maxY),
      ];
    } else {
      rectPoints = [
        Point2D(minX, minY),
        Point2D(maxX, minY),
        Point2D(maxX, maxY),
        Point2D(minX, maxY),
      ];
    }

    return BeautifiedResult(
      type: AnnotationType.rectangle,
      points: rectPoints,
      didSnap: true,
    );
  }

  static BeautifiedResult? _tryClassifyCircle(
    List<Point2D> smoothed,
    List<Point2D> raw,
  ) {
    double cx = 0, cy = 0;
    for (final p in smoothed) {
      cx += p.x;
      cy += p.y;
    }
    cx /= smoothed.length;
    cy /= smoothed.length;

    final center = Point2D(cx, cy);
    final radii = smoothed.map((p) => _dist(p, center)).toList();
    final meanRadius = radii.reduce((a, b) => a + b) / radii.length;

    if (meanRadius < 0.015) return null;

    double variance = 0.0;
    for (final r in radii) {
      variance += math.pow(r - meanRadius, 2);
    }
    final stdDev = math.sqrt(variance / radii.length);

    if (stdDev / meanRadius <= 0.08) {
      return _fitCircle(smoothed, raw, center: center, radius: meanRadius);
    }
    return null;
  }

  static BeautifiedResult _fitCircle(
    List<Point2D> smoothed,
    List<Point2D> raw, {
    Point2D? center,
    double? radius,
  }) {
    Point2D c = center ?? Point2D(
      raw.map((p) => p.x).reduce((a, b) => a + b) / raw.length,
      raw.map((p) => p.y).reduce((a, b) => a + b) / raw.length,
    );
    double r = radius ?? raw.map((p) => _dist(p, c)).reduce((a, b) => a + b) / raw.length;

    return BeautifiedResult(
      type: AnnotationType.circle,
      points: [c, Point2D(c.x + r, c.y)],
      didSnap: true,
      metadata: {'radius': r},
    );
  }

  static BeautifiedResult _fitCloud(
    List<Point2D> smoothed,
    List<Point2D> raw,
    SnapConfig snapConfig,
  ) {
    const double arcRadius = 0.015;
    final cloudArcs = <Point2D>[];

    final n = smoothed.length;
    for (int i = 0; i < n; i += 3) {
      cloudArcs.add(smoothed[i]);
    }
    if (cloudArcs.isNotEmpty && _dist(cloudArcs.first, cloudArcs.last) > 0.02) {
      cloudArcs.add(cloudArcs.first);
    }

    return BeautifiedResult(
      type: AnnotationType.cloud,
      points: cloudArcs,
      didSnap: true,
      metadata: {'arcRadius': arcRadius},
    );
  }

  // --- Angle Snapping Math ---

  static Point2D snapAngle({
    required Point2D origin,
    required Point2D target,
    required SnapAxisSet axisSet,
    double toleranceDegrees = 8.0,
  }) {
    final dx = target.x - origin.x;
    final dy = target.y - origin.y;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length < 0.001) return target;

    final angleRad = math.atan2(dy, dx);
    double angleDeg = (angleRad * 180 / math.pi);
    if (angleDeg < 0) angleDeg += 360;

    double? bestSnapAngle;
    double minDiff = toleranceDegrees + 0.001;

    final allAllowedAngles = <int>[];
    for (final baseAngle in axisSet.allowedAngles) {
      allAllowedAngles.add(baseAngle);
      allAllowedAngles.add((baseAngle + 180) % 360);
    }

    for (final allowed in allAllowedAngles) {
      double diff = (angleDeg - allowed).abs();
      if (diff > 180) diff = 360 - diff;
      if (diff <= toleranceDegrees && diff < minDiff) {
        minDiff = diff;
        bestSnapAngle = allowed.toDouble();
      }
    }

    if (bestSnapAngle != null) {
      final snappedRad = bestSnapAngle * math.pi / 180;
      return Point2D(
        (origin.x + length * math.cos(snappedRad)).clamp(0.0, 1.0),
        (origin.y + length * math.sin(snappedRad)).clamp(0.0, 1.0),
      );
    }

    return target;
  }

  // --- Geometry Helpers ---

  static double _dist(Point2D a, Point2D b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double _perpDist(Point2D p, Point2D a, Point2D b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return _dist(p, a);

    final num = ((b.y - a.y) * p.x - (b.x - a.x) * p.y + b.x * a.y - b.y * a.x).abs();
    return num / math.sqrt(lenSq);
  }
}
