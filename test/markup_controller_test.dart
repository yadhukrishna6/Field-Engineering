import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/drawings/domain/models/markup.dart';
import 'package:field_engineering/features/drawings/domain/repositories/markups_repository.dart';
import 'package:field_engineering/features/drawings/presentation/controllers/markup_controller.dart';

class MockMarkupsRepository implements MarkupsRepository {
  final List<Markup> _storage = [];

  @override
  Future<List<Markup>> getMarkupsForDrawing(String drawingId, {int? pageNumber}) async {
    return _storage.where((m) {
      if (m.drawingId != drawingId) return false;
      if (pageNumber != null && m.pageNumber != pageNumber) return false;
      return true;
    }).toList();
  }

  @override
  Future<Markup> saveMarkup(Markup markup) async {
    _storage.removeWhere((m) => m.id == markup.id);
    _storage.add(markup);
    return markup;
  }

  @override
  Future<List<Markup>> saveMarkupsBatch(List<Markup> markups) async {
    for (final m in markups) {
      _storage.removeWhere((item) => item.id == m.id);
      _storage.add(m);
    }
    return markups;
  }

  @override
  Future<bool> deleteMarkup(String id) async {
    final before = _storage.length;
    _storage.removeWhere((m) => m.id == id);
    return _storage.length < before;
  }

  @override
  Future<bool> deleteMarkupsForDrawing(String drawingId, {int? pageNumber}) async {
    _storage.removeWhere((m) {
      if (m.drawingId != drawingId) return false;
      if (pageNumber != null && m.pageNumber != pageNumber) return false;
      return true;
    });
    return true;
  }

}

void main() {
  late MockMarkupsRepository repository;
  late MarkupController controller;
  const drawingId = 'test-dwg-001';

  setUp(() {
    repository = MockMarkupsRepository();
    controller = MarkupController(repository, drawingId, totalPages: 3);
  });

  group('Drawing Tool & Geometry Interaction', () {
    test('Drawing a freehand stroke creates a markup with normalized points', () {
      controller.selectTool(MarkupType.pen);
      controller.setColor(const Color(0xFFD32F2F));
      controller.setStrokeWidth(4.0);

      controller.startDrawing(const Point2D(0.1, 0.1));
      controller.updateDrawing(const Point2D(0.15, 0.12));
      controller.updateDrawing(const Point2D(0.2, 0.15));
      controller.finishDrawing();

      final state = controller.state;
      expect(state.activePageMarkups.length, equals(1));
      final markup = state.activePageMarkups.first;
      expect(markup.type, equals(MarkupType.pen));
      expect(markup.points.length, equals(3));
      expect(markup.points.first.x, equals(0.1));
      expect(markup.points.last.x, equals(0.2));
      expect(markup.strokeWidth, equals(4.0));
      expect(markup.color.value, equals(const Color(0xFFD32F2F).value));
    });

    test('Drawing a rectangle records correct normalized bounding box', () {
      controller.selectTool(MarkupType.rectangle);
      controller.startDrawing(const Point2D(0.2, 0.3));
      controller.updateDrawing(const Point2D(0.5, 0.6));
      controller.finishDrawing();

      final markups = controller.state.activePageMarkups;
      expect(markups.length, equals(1));
      expect(markups.first.type, equals(MarkupType.rectangle));
      expect(markups.first.bounds?.left, equals(0.2));
      expect(markups.first.bounds?.top, equals(0.3));
      expect(markups.first.bounds?.right, equals(0.5));
      expect(markups.first.bounds?.bottom, equals(0.6));
    });

    test('Adding a text callout correctly positions on active page with content', () {
      controller.addTextCallout(
        const Point2D(0.4, 0.5),
        'NOTE: Flange Rating 300# ANSI',
        fontSize: 16.0,
      );

      final markups = controller.state.activePageMarkups;
      expect(markups.length, equals(1));
      final textMarkup = markups.first;
      expect(textMarkup.type, equals(MarkupType.text));
      expect(textMarkup.text, equals('NOTE: Flange Rating 300# ANSI'));
      expect(textMarkup.fontSize, equals(16.0));
      expect(textMarkup.points.first.x, equals(0.4));
      expect(textMarkup.points.first.y, equals(0.5));
    });

    test('Adding punchlist issue pins sets the issue layer and metadata', () {
      controller.addIssuePin(
        const Point2D(0.6, 0.7),
        issueTag: 'PNC-042',
        title: 'Missing torque witness mark',
      );

      final markups = controller.state.activePageMarkups;
      expect(markups.length, equals(1));
      final issueMarkup = markups.first;
      expect(issueMarkup.layer, equals(DrawingLayer.issue));
      expect(issueMarkup.type, equals(MarkupType.issuePin));
      expect(issueMarkup.text, equals('PNC-042'));
      expect(issueMarkup.metadata?['title'], equals('Missing torque witness mark'));
    });

    test('Adding photo pin sets photo layer and attachment metadata', () {
      controller.addPhotoPin(
        const Point2D(0.3, 0.8),
        photoPath: 'site_joint_w04.jpg',
        caption: 'Weld root pass inspection',
      );

      final markups = controller.state.activePageMarkups;
      expect(markups.length, equals(1));
      final photoMarkup = markups.first;
      expect(photoMarkup.layer, equals(DrawingLayer.photo));
      expect(photoMarkup.type, equals(MarkupType.photoPin));
      expect(photoMarkup.metadata?['photoPath'], equals('site_joint_w04.jpg'));
    });
  });

  group('Undo, Redo, Copy & Paste Operations', () {
    test('Undo removes last markup, redo restores it', () {
      controller.selectTool(MarkupType.line);
      controller.startDrawing(const Point2D(0.1, 0.1));
      controller.updateDrawing(const Point2D(0.2, 0.2));
      controller.finishDrawing();

      controller.selectTool(MarkupType.circle);
      controller.startDrawing(const Point2D(0.3, 0.3));
      controller.updateDrawing(const Point2D(0.4, 0.4));
      controller.finishDrawing();

      expect(controller.state.activePageMarkups.length, equals(2));

      // Undo circle
      controller.undo();
      expect(controller.state.activePageMarkups.length, equals(1));
      expect(controller.state.activePageMarkups.first.type, equals(MarkupType.line));

      // Undo line
      controller.undo();
      expect(controller.state.activePageMarkups.length, equals(0));

      // Redo line
      controller.redo();
      expect(controller.state.activePageMarkups.length, equals(1));
      expect(controller.state.activePageMarkups.first.type, equals(MarkupType.line));

      // Redo circle
      controller.redo();
      expect(controller.state.activePageMarkups.length, equals(2));
    });

    test('Copy and paste duplicates markup with offset', () {
      controller.addTextCallout(const Point2D(0.2, 0.2), 'Copy Me');
      final originalId = controller.state.activePageMarkups.first.id;

      controller.selectMarkup(originalId);
      controller.copySelectedMarkup();
      controller.pasteMarkup();

      final markups = controller.state.activePageMarkups;
      expect(markups.length, equals(2));
      expect(markups[1].id, isNot(equals(originalId)));
      expect(markups[1].text, equals('Copy Me'));
      // Pasted item is shifted by offset
      expect(markups[1].points.first.x, closeTo(0.22, 0.001));
      expect(markups[1].points.first.y, closeTo(0.22, 0.001));
    });

    test('Move selected markup shifts coordinates by normalized delta', () {
      controller.addTextCallout(const Point2D(0.3, 0.3), 'Move Target');
      final targetId = controller.state.activePageMarkups.first.id;

      controller.selectMarkup(targetId);
      controller.moveSelectedMarkup(const Offset(0.05, 0.10));

      final moved = controller.state.activePageMarkups.first;
      expect(moved.points.first.x, closeTo(0.35, 0.001));
      expect(moved.points.first.y, closeTo(0.40, 0.001));
    });

    test('Delete selected markup removes it from state and repository', () {
      controller.addTextCallout(const Point2D(0.1, 0.1), 'To Delete');
      final id = controller.state.activePageMarkups.first.id;

      controller.selectMarkup(id);
      controller.deleteSelectedMarkup();

      expect(controller.state.activePageMarkups.isEmpty, isTrue);
    });
  });

  group('Layer Panel Toggles & Multi-Page Navigation', () {
    test('Toggling layers modifies visibleLayers set and layer count stats', () {
      controller.addIssuePin(const Point2D(0.1, 0.1), issueTag: 'ISSUE-1', title: 'Issue 1');
      controller.addPhotoPin(const Point2D(0.2, 0.2), photoPath: 'p.jpg', caption: 'Photo 1');

      expect(controller.state.getLayerCount(DrawingLayer.issue), equals(1));
      expect(controller.state.getLayerCount(DrawingLayer.photo), equals(1));

      // Hide issues
      controller.toggleLayer(DrawingLayer.issue);
      expect(controller.state.visibleLayers.contains(DrawingLayer.issue), isFalse);

      // Re-enable issues
      controller.toggleLayer(DrawingLayer.issue);
      expect(controller.state.visibleLayers.contains(DrawingLayer.issue), isTrue);
    });

    test('Switching pages filters markups to the active page', () {
      // Page 1 markup
      controller.setPage(1);
      controller.addTextCallout(const Point2D(0.1, 0.1), 'Page 1 Note');

      // Switch to Page 2
      controller.setPage(2);
      expect(controller.state.activePageMarkups.isEmpty, isTrue);

      // Page 2 markup
      controller.addTextCallout(const Point2D(0.5, 0.5), 'Page 2 Note');
      expect(controller.state.activePageMarkups.length, equals(1));

      // Switch back to Page 1
      controller.setPage(1);
      expect(controller.state.activePageMarkups.length, equals(1));
      expect(controller.state.activePageMarkups.first.text, equals('Page 1 Note'));
    });
  });
}
