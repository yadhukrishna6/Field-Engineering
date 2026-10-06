import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:field_engineering/core/theme/app_typography.dart';
import 'package:field_engineering/features/drawings/domain/models/markup.dart';
import 'package:field_engineering/features/drawings/domain/utils/stroke_smoother.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Phase 1 - Uniform Engineering Typography', () {
    test('Strict standard engineering font family is defined', () {
      expect(AppTypography.engineeringFontFamily, equals('EngineeringFont'));
    });

    test('Engineering text style creates standard CAD typography', () {
      final style = AppTypography.engineeringTextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        color: Colors.yellow,
      );
      expect(style.fontSize, equals(14.0));
      expect(style.fontWeight, equals(FontWeight.bold));
      expect(style.color, equals(Colors.yellow));
      expect(style.fontFamily, equals(AppTypography.engineeringFontFamily));
    });
  });

  group('Phase 1 - Catmull-Rom Spline Smoothing', () {
    test('Smooths 4 control points into multi-point curve', () {
      final rawPoints = [
        const Point2D(0.1, 0.1),
        const Point2D(0.2, 0.4),
        const Point2D(0.5, 0.8),
        const Point2D(0.9, 0.9),
      ];

      final smoothed = StrokeSmoother.smoothPoints(rawPoints, subdivisions: 4);
      expect(smoothed.length, greaterThan(rawPoints.length));
      expect(smoothed.first.x, closeTo(0.1, 0.001));
      expect(smoothed.first.y, closeTo(0.1, 0.001));
      expect(smoothed.last.x, closeTo(0.9, 0.001));
      expect(smoothed.last.y, closeTo(0.9, 0.001));
    });

    test('createSmoothPath builds valid GPU cubic Bezier path', () {
      final rawPoints = [
        const Point2D(0.0, 0.0),
        const Point2D(0.3, 0.5),
        const Point2D(0.7, 0.5),
        const Point2D(1.0, 1.0),
      ];

      const canvasSize = Size(1000, 800);
      final path = StrokeSmoother.createSmoothPath(rawPoints, canvasSize);
      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    });
  });

  group('Phase 1 - Ramer-Douglas-Peucker Decimation', () {
    test('Simplifies straight redundant collinear points', () {
      final lineWithJitter = [
        const Point2D(0.0, 0.0),
        const Point2D(0.25, 0.0001),
        const Point2D(0.5, 0.0),
        const Point2D(0.75, -0.0001),
        const Point2D(1.0, 0.0),
      ];

      final simplified = StrokeSmoother.simplifyRDP(lineWithJitter, epsilon: 0.001);
      expect(simplified.length, equals(2));
      expect(simplified.first.x, equals(0.0));
      expect(simplified.last.x, equals(1.0));
    });

    test('Preserves prominent corners and bends in CAD markup', () {
      final lShape = [
        const Point2D(0.0, 0.0),
        const Point2D(0.5, 0.0),
        const Point2D(0.5, 0.5),
      ];

      final simplified = StrokeSmoother.simplifyRDP(lShape, epsilon: 0.01);
      expect(simplified.length, equals(3));
    });
  });

  group('Phase 1 - Stroke-Level Eraser Collision Detection', () {
    test('distanceToSegment calculates exact perpendicular and endpoint distance', () {
      const p1 = Point2D(0.0, 0.5);
      const p2 = Point2D(1.0, 0.5);

      // Point directly above middle of segment
      const testMid = Point2D(0.5, 0.52);
      final distMid = StrokeSmoother.distanceToSegment(testMid, p1, p2);
      expect(distMid, closeTo(0.02, 0.0001));

      // Point beyond segment endpoint
      const testPast = Point2D(1.1, 0.5);
      final distPast = StrokeSmoother.distanceToSegment(testPast, p1, p2);
      expect(distPast, closeTo(0.1, 0.0001));
    });

    test('isMarkupHit detects hit on pen stroke', () {
      final strokeMarkup = Markup(
        id: 'stroke-1',
        drawingId: 'dwg-101',
        type: MarkupType.pen,
        color: Colors.red,
        points: const [
          Point2D(0.1, 0.1),
          Point2D(0.5, 0.5),
          Point2D(0.9, 0.9),
        ],
        createdBy: 'Engineer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Hit directly near middle of first segment
      const hitPoint = Point2D(0.3, 0.31);
      final isHit = StrokeSmoother.isMarkupHit(strokeMarkup, hitPoint, 0.025);
      expect(isHit, isTrue);

      // Far away point
      const missPoint = Point2D(0.1, 0.9);
      final isMiss = StrokeSmoother.isMarkupHit(strokeMarkup, missPoint, 0.025);
      expect(isMiss, isFalse);
    });

    test('isMarkupHit detects hit on text callout bounds', () {
      final textMarkup = Markup(
        id: 'text-1',
        drawingId: 'dwg-101',
        type: MarkupType.text,
        color: Colors.orange,
        bounds: const Rect.fromLTWH(0.2, 0.2, 0.2, 0.08),
        points: const [Point2D(0.2, 0.2)],
        text: 'VIF - VERIFY IN FIELD',
        createdBy: 'Engineer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const hitInside = Point2D(0.25, 0.24);
      expect(StrokeSmoother.isMarkupHit(textMarkup, hitInside, 0.02), isTrue);

      const hitOutside = Point2D(0.5, 0.5);
      expect(StrokeSmoother.isMarkupHit(textMarkup, hitOutside, 0.02), isFalse);
    });
  });

  group('Phase 1 - Rotation Snapping', () {
    test('Snaps close angles to standard engineering angles (0, 30, 60, 90, 180)', () {
      expect(StrokeSmoother.snapRotationDegrees(32.0), equals(30.0));
      expect(StrokeSmoother.snapRotationDegrees(88.0), equals(90.0));
      expect(StrokeSmoother.snapRotationDegrees(183.0), equals(180.0));
      expect(StrokeSmoother.snapRotationDegrees(358.0), equals(0.0));
      expect(StrokeSmoother.snapRotationDegrees(14.0), equals(14.0)); // Outside tolerance
    });

    test('Snaps radians correctly', () {
      const radNear90 = 89.0 * math.pi / 180.0;
      final snapped = StrokeSmoother.snapRotationRadians(radNear90);
      expect(snapped, closeTo(math.pi / 2, 0.001));
    });
  });

  group('Phase 1 - Markup Serialization & Status', () {
    test('Serializes and deserializes markup with leader arrow, halo, and status', () {
      final original = Markup(
        id: 'm-test-01',
        drawingId: 'dwg-202',
        revisionId: 'rev-01',
        pageNumber: 2,
        layer: DrawingLayer.markup,
        type: MarkupType.text,
        color: const Color(0xFFFF5722),
        fillColor: const Color(0xFF1E293B),
        strokeWidth: 2.5,
        opacity: 0.95,
        points: const [Point2D(0.15, 0.25)],
        bounds: const Rect.fromLTWH(0.15, 0.25, 0.2, 0.06),
        text: 'HOLD FOR CLIENT RFI #104',
        fontSize: 13.0,
        rotation: math.pi / 6,
        leaderPoint: const Point2D(0.35, 0.45),
        hasHalo: true,
        status: 'Open',
        version: 1,
        createdBy: 'Senior Piping Engineer',
        createdAt: DateTime.parse('2026-10-06T12:00:00.000Z'),
        updatedAt: DateTime.parse('2026-10-06T12:00:00.000Z'),
      );

      final map = original.toMap();
      final restored = Markup.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.drawingId, equals(original.drawingId));
      expect(restored.revisionId, equals(original.revisionId));
      expect(restored.pageNumber, equals(original.pageNumber));
      expect(restored.type, equals(MarkupType.text));
      expect(restored.text, equals('HOLD FOR CLIENT RFI #104'));
      expect(restored.status, equals('Open'));
      expect(restored.hasHalo, isTrue);
      expect(restored.leaderPoint, isNotNull);
      expect(restored.leaderPoint!.x, closeTo(0.35, 0.001));
      expect(restored.leaderPoint!.y, closeTo(0.45, 0.001));
    });
  });
}
