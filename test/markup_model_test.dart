import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/drawings/domain/models/markup.dart';

void main() {
  group('Point2D Normalized Coordinates Tests', () {
    test('Converts correctly between normalized coordinates and screen offsets', () {
      const point = Point2D(0.25, 0.75);
      const canvasSize = Size(1000, 800);

      final offset = point.toOffset(canvasSize);
      expect(offset.dx, equals(250.0));
      expect(offset.dy, equals(600.0));

      final convertedBack = Point2D.fromOffset(offset, canvasSize);
      expect(convertedBack.x, closeTo(0.25, 0.0001));
      expect(convertedBack.y, closeTo(0.75, 0.0001));
    });

    test('Serialization to/from Map preserves exact precision', () {
      const point = Point2D(0.123456, 0.987654);
      final map = point.toMap();
      final reconstructed = Point2D.fromMap(map);

      expect(reconstructed.x, equals(0.123456));
      expect(reconstructed.y, equals(0.987654));
    });
  });

  group('Markup Model Serialization & Layer Tests', () {
    test('Full serialization and deserialization preserves all engineering properties', () {
      final now = DateTime.now();
      final markup = Markup(
        id: 'mk-001',
        drawingId: 'dwg-084-pid-001',
        pageNumber: 1,
        layer: DrawingLayer.markup,
        type: MarkupType.revisionCloud,
        color: const Color(0xFFD32F2F),
        fillColor: const Color(0x33D32F2F),
        strokeWidth: 3.5,
        opacity: 0.9,
        points: const [
          Point2D(0.1, 0.2),
          Point2D(0.3, 0.2),
          Point2D(0.3, 0.4),
          Point2D(0.1, 0.4),
        ],
        bounds: const Rect.fromLTRB(0.1, 0.2, 0.3, 0.4),
        text: 'REV-2 CLOUD: Verify tie-in point',
        fontSize: 14.0,
        rotation: 0.0,
        metadata: {'author': 'Senior Piping Engineer', 'status': 'APPROVED'},
        createdBy: 'Senior Piping Engineer',
        createdAt: now,
        updatedAt: now,
      );

      final map = markup.toMap();
      final deserialized = Markup.fromMap(map);

      expect(deserialized.id, equals('mk-001'));
      expect(deserialized.drawingId, equals('dwg-084-pid-001'));
      expect(deserialized.pageNumber, equals(1));
      expect(deserialized.layer, equals(DrawingLayer.markup));
      expect(deserialized.type, equals(MarkupType.revisionCloud));
      expect(deserialized.color.value, equals(const Color(0xFFD32F2F).value));
      expect(deserialized.fillColor?.value, equals(const Color(0x33D32F2F).value));
      expect(deserialized.strokeWidth, equals(3.5));
      expect(deserialized.opacity, equals(0.9));
      expect(deserialized.points.length, equals(4));
      expect(deserialized.bounds?.left, equals(0.1));
      expect(deserialized.bounds?.top, equals(0.2));
      expect(deserialized.bounds?.right, equals(0.3));
      expect(deserialized.bounds?.bottom, equals(0.4));
      expect(deserialized.text, equals('REV-2 CLOUD: Verify tie-in point'));
      expect(deserialized.fontSize, equals(14.0));
      expect(deserialized.metadata?['author'], equals('Senior Piping Engineer'));
    });

    test('All DrawingLayer enum values have valid display names and icons', () {
      for (final layer in DrawingLayer.values) {
        expect(layer.displayName.isNotEmpty, isTrue);
        expect(layer.icon, isNotNull);
      }
    });

    test('All MarkupType enum values have valid display names and icons', () {
      for (final type in MarkupType.values) {
        expect(type.displayName.isNotEmpty, isTrue);
        expect(type.icon, isNotNull);
      }
    });

    test('Markup copyWith updates properties correctly', () {
      final markup = Markup(
        id: 'mk-copy',
        drawingId: 'dwg-1',
        type: MarkupType.pen,
        color: Colors.red,
        createdBy: 'Engineer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = markup.copyWith(
        color: Colors.blue,
        strokeWidth: 5.0,
        opacity: 0.5,
      );

      expect(updated.id, equals('mk-copy'));
      expect(updated.color, equals(Colors.blue));
      expect(updated.strokeWidth, equals(5.0));
      expect(updated.opacity, equals(0.5));
      expect(markup.color, equals(Colors.red)); // Original is immutable
    });
  });
}
