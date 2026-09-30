import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/drawings/domain/models/markup.dart';
import 'package:field_engineering/features/drawings/domain/repositories/markups_repository.dart';
import 'package:field_engineering/features/drawings/presentation/controllers/markup_controller.dart';

class LocalOfflineRepository implements MarkupsRepository {
  final Map<String, List<Markup>> _drawingDatabase = {};

  @override
  Future<List<Markup>> getMarkupsForDrawing(String drawingId, {int? pageNumber}) async {
    final list = _drawingDatabase[drawingId] ?? [];
    if (pageNumber != null) {
      return list.where((m) => m.pageNumber == pageNumber).toList();
    }
    return List.unmodifiable(list);
  }

  @override
  Future<Markup> saveMarkup(Markup markup) async {
    final list = _drawingDatabase.putIfAbsent(markup.drawingId, () => []);
    list.removeWhere((m) => m.id == markup.id);
    list.add(markup);
    return markup;
  }

  @override
  Future<List<Markup>> saveMarkupsBatch(List<Markup> markups) async {
    for (final m in markups) {
      final list = _drawingDatabase.putIfAbsent(m.drawingId, () => []);
      list.removeWhere((item) => item.id == m.id);
      list.add(m);
    }
    return markups;
  }

  @override
  Future<bool> deleteMarkup(String id) async {
    for (final list in _drawingDatabase.values) {
      final before = list.length;
      list.removeWhere((m) => m.id == id);
      if (list.length < before) return true;
    }
    return false;
  }

  @override
  Future<bool> deleteMarkupsForDrawing(String drawingId, {int? pageNumber}) async {
    if (pageNumber != null) {
      _drawingDatabase[drawingId]?.removeWhere((m) => m.pageNumber == pageNumber);
    } else {
      _drawingDatabase.remove(drawingId);
    }
    return true;
  }

}

void main() {
  test('Complete Phase 2 Blueprint Workflow: Open -> Draw -> Text -> Shapes -> Undo/Redo -> Close -> Reopen -> Verify Coordinates', () async {
    final offlineDb = LocalOfflineRepository();
    const drawingId = '084-PID-001';

    // Step 1: Open Drawing (Initialize MarkupController)
    var controller = MarkupController(offlineDb, drawingId, totalPages: 2);
    await controller.loadMarkups();
    expect(controller.state.activePageMarkups.isEmpty, isTrue);

    // Step 2: Draw a freehand redline
    controller.selectTool(MarkupType.pen);
    controller.setColor(const Color(0xFFD32F2F));
    controller.setStrokeWidth(3.0);
    controller.startDrawing(const Point2D(0.2450, 0.3120));
    controller.updateDrawing(const Point2D(0.2500, 0.3180));
    controller.updateDrawing(const Point2D(0.2600, 0.3250));
    controller.finishDrawing();

    // Step 3: Add a text callout
    controller.addTextCallout(
      const Point2D(0.4500, 0.6200),
      'HOLD: Tie-in nozzle 6"-HC-1001 requires site verification',
      fontSize: 16.0,
    );

    // Step 4: Add a Revision Cloud around equipment
    controller.selectTool(MarkupType.revisionCloud);
    controller.startDrawing(const Point2D(0.5000, 0.4000));
    controller.updateDrawing(const Point2D(0.7000, 0.5500));
    controller.finishDrawing();

    // Step 5: Add a Dimension Measurement Ruler
    controller.selectTool(MarkupType.measurement);
    controller.startDrawing(const Point2D(0.1000, 0.8000));
    controller.updateDrawing(const Point2D(0.3000, 0.8000));
    controller.finishDrawing();

    // Step 6: Add a punchlist issue pin
    controller.addIssuePin(
      const Point2D(0.8200, 0.1500),
      issueTag: 'PNC-084-01',
      title: 'Valve tag missing on drain line',
    );

    expect(controller.state.activePageMarkups.length, equals(5));

    // Step 7: Test Undo and Redo
    controller.undo(); // Undo issue pin
    expect(controller.state.activePageMarkups.length, equals(4));

    controller.redo(); // Restore issue pin
    expect(controller.state.activePageMarkups.length, equals(5));

    // Step 8: Trigger Save to local offline SQLite repository
    await offlineDb.saveMarkupsBatch(controller.state.markups);

    // Step 9: Close Drawing (simulate user exiting the viewer screen)
    controller.dispose();

    // Step 10: Reopen Drawing (New Controller instance simulating reopening offline)
    final reopenedController = MarkupController(offlineDb, drawingId, totalPages: 2);
    await reopenedController.loadMarkups();

    final reloadedMarkups = reopenedController.state.activePageMarkups;
    expect(reloadedMarkups.length, equals(5));

    // Step 11: Verify all 5 annotations remain in exact normalized coordinates

    // 1. Pen Stroke
    final pen = reloadedMarkups.firstWhere((m) => m.type == MarkupType.pen);
    expect(pen.points.length, equals(3));
    expect(pen.points[0].x, closeTo(0.2450, 0.0001));
    expect(pen.points[0].y, closeTo(0.3120, 0.0001));
    expect(pen.points[2].x, closeTo(0.2600, 0.0001));
    expect(pen.points[2].y, closeTo(0.3250, 0.0001));
    expect(pen.color.value, equals(const Color(0xFFD32F2F).value));

    // 2. Text Callout
    final textCallout = reloadedMarkups.firstWhere((m) => m.type == MarkupType.text);
    expect(textCallout.text, equals('HOLD: Tie-in nozzle 6"-HC-1001 requires site verification'));
    expect(textCallout.points.first.x, closeTo(0.4500, 0.0001));
    expect(textCallout.points.first.y, closeTo(0.6200, 0.0001));
    expect(textCallout.fontSize, equals(16.0));

    // 3. Revision Cloud
    final cloud = reloadedMarkups.firstWhere((m) => m.type == MarkupType.revisionCloud);
    expect(cloud.bounds?.left, closeTo(0.5000, 0.0001));
    expect(cloud.bounds?.top, closeTo(0.4000, 0.0001));
    expect(cloud.bounds?.right, closeTo(0.7000, 0.0001));
    expect(cloud.bounds?.bottom, closeTo(0.5500, 0.0001));

    // 4. Dimension Measurement Ruler
    final ruler = reloadedMarkups.firstWhere((m) => m.type == MarkupType.measurement);
    expect(ruler.layer, equals(DrawingLayer.measurement));
    expect(ruler.points.first.x, closeTo(0.1000, 0.0001));
    expect(ruler.points.last.x, closeTo(0.3000, 0.0001));

    // 5. Punchlist Issue Pin
    final issue = reloadedMarkups.firstWhere((m) => m.type == MarkupType.issuePin);
    expect(issue.layer, equals(DrawingLayer.issue));
    expect(issue.text, equals('PNC-084-01'));
    expect(issue.metadata?['title'], equals('Valve tag missing on drain line'));
    expect(issue.points.first.x, closeTo(0.8200, 0.0001));
    expect(issue.points.first.y, closeTo(0.1500, 0.0001));

    reopenedController.dispose();
  });
}
