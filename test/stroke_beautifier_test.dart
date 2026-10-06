import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/markup/domain/models/annotation_item.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/domain/models/snap_config.dart';
import 'package:field_engineering/features/markup/domain/utils/stroke_beautifier.dart';

void main() {
  group('StrokeBeautifier - Mathematical Auto-Alignment & Classification', () {
    const configIso = SnapConfig(
      isEnabled: true,
      axisSet: SnapAxisSet.isometric,
      angleToleranceDegrees: 8.0,
    );

    const configOrtho = SnapConfig(
      isEnabled: true,
      axisSet: SnapAxisSet.orthogonal,
      angleToleranceDegrees: 8.0,
    );

    test('Wobbly horizontal-ish line snaps to straight line at nearest axis (0 deg)', () {
      // Line drawn horizontally with small wobbles (< 4% deviation)
      final rawPoints = <Point2D>[];
      for (int i = 0; i <= 20; i++) {
        final x = 0.1 + (i / 20) * 0.4;
        final y = 0.5 + (i % 2 == 0 ? 0.003 : -0.003); // slight wobble
        rawPoints.add(Point2D(x, y));
      }

      final result = StrokeBeautifier.beautify(
        rawPoints: rawPoints,
        color: const Color(0xFFD03A33),
        strokeWidth: 3.0,
        snapConfig: configOrtho,
      );

      expect(result.type, equals(AnnotationType.line));
      expect(result.points.length, equals(2));
      // Starts at first point
      expect(result.points.first.x, equals(0.1));
      // End point snapped horizontally (y equals origin y 0.503 approx)
      expect((result.points.last.y - result.points.first.y).abs(), lessThan(0.005));
    });

    test('Line at 12 degrees from axis exceeds 8 deg tolerance and stays unsnapped', () {
      // 12 degree angle from horizontal
      const angleRad = 12 * math.pi / 180;
      const start = Point2D(0.1, 0.5);
      final rawPoints = <Point2D>[];

      for (int i = 0; i <= 20; i++) {
        final len = (i / 20) * 0.3;
        final x = start.x + len * math.cos(angleRad);
        final y = start.y + len * math.sin(angleRad);
        rawPoints.add(Point2D(x, y));
      }

      final result = StrokeBeautifier.beautify(
        rawPoints: rawPoints,
        color: const Color(0xFF185FA5),
        strokeWidth: 3.0,
        snapConfig: configOrtho,
      );

      expect(result.type, equals(AnnotationType.line));
      expect(result.didSnap, isFalse);
      // Angle preserved as ~12 degrees
      final end = result.points.last;
      final actualAngleDeg = math.atan2(end.y - start.y, end.x - start.x) * 180 / math.pi;
      expect((actualAngleDeg - 12).abs(), lessThan(1.0));
    });

    test('Arrow with a sharp V return head detects as Arrow', () {
      final rawPoints = <Point2D>[];
      // Shaft from (0.1, 0.1) to (0.5, 0.5)
      for (int i = 0; i <= 20; i++) {
        rawPoints.add(Point2D(0.1 + (i / 20) * 0.4, 0.1 + (i / 20) * 0.4));
      }
      // V-barb at tip turning back towards (0.45, 0.48) (angle > 120 deg)
      rawPoints.add(const Point2D(0.48, 0.45));
      rawPoints.add(const Point2D(0.45, 0.42));

      final result = StrokeBeautifier.beautify(
        rawPoints: rawPoints,
        color: const Color(0xFFEF9F27),
        strokeWidth: 3.0,
        snapConfig: configIso,
      );

      expect(result.type, equals(AnnotationType.arrow));
      expect(result.points.length, equals(2));
    });

    test('Rough 4-corner box classifies and fits clean Rectangle', () {
      final rawPoints = <Point2D>[
        const Point2D(0.2, 0.2),
        const Point2D(0.6, 0.21),
        const Point2D(0.61, 0.59),
        const Point2D(0.19, 0.6),
        const Point2D(0.2, 0.2), // closed
      ];

      final result = StrokeBeautifier.beautify(
        rawPoints: rawPoints,
        color: const Color(0xFF2E8B3E),
        strokeWidth: 3.0,
        snapConfig: configOrtho,
      );

      expect(result.type, equals(AnnotationType.rectangle));
      expect(result.points.length, equals(4));
    });

    test('Closed freehand loop with irregular boundary classifies as Revision Cloud', () {
      final rawPoints = <Point2D>[];
      // Irregular oval/potato shape
      for (int i = 0; i <= 36; i++) {
        final angle = i * 10 * math.pi / 180;
        final r = 0.15 + (i % 3 == 0 ? 0.04 : -0.02);
        rawPoints.add(Point2D(0.5 + r * math.cos(angle), 0.5 + r * 0.6 * math.sin(angle)));
      }

      final result = StrokeBeautifier.beautify(
        rawPoints: rawPoints,
        color: const Color(0xFFD03A33),
        strokeWidth: 3.0,
        snapConfig: configIso,
      );

      expect(result.type, equals(AnnotationType.cloud));
      expect(result.metadata?['arcRadius'], isNotNull);
    });

    test('Jittery freehand stroke stays freehand (Pen stroke)', () {
      final rawPoints = <Point2D>[
        const Point2D(0.1, 0.1),
        const Point2D(0.15, 0.25),
        const Point2D(0.12, 0.4),
        const Point2D(0.3, 0.35),
        const Point2D(0.25, 0.6),
        const Point2D(0.4, 0.7),
      ];

      final result = StrokeBeautifier.beautify(
        rawPoints: rawPoints,
        color: const Color(0xFF2C2C2A),
        strokeWidth: 2.0,
        snapConfig: configIso,
      );

      expect(result.type, equals(AnnotationType.stroke));
      expect(result.didSnap, isFalse);
    });

    test('Beautification runs in under 16 milliseconds for 500 points', () {
      final rawPoints = List.generate(
        500,
        (i) => Point2D(0.1 + (i / 500) * 0.8, 0.2 + (math.sin(i) * 0.001)),
      );

      final stopwatch = Stopwatch()..start();
      final result = StrokeBeautifier.beautify(
        rawPoints: rawPoints,
        color: const Color(0xFFD03A33),
        strokeWidth: 3.0,
        snapConfig: configIso,
      );
      stopwatch.stop();

      expect(result, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(16));
    });
  });
}
