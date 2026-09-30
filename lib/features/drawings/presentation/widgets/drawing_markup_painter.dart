import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/markup.dart';
import '../../domain/models/measurement.dart';
import '../../domain/utils/measurement_calculator.dart';
import '../controllers/markup_controller.dart';

class DrawingMarkupPainter extends CustomPainter {
  final DrawingViewerState viewerState;
  final Size canvasSize;

  DrawingMarkupPainter({
    required this.viewerState,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleLayers = viewerState.visibleLayers;
    final activeMarkups = viewerState.activePageMarkups;
    final activeMeasurements = viewerState.activePageMeasurements;

    // 1. Render all persistent markups on active page matching visible layers
    for (final markup in activeMarkups) {
      if (!visibleLayers.contains(markup.layer)) continue;
      final isSelected = markup.id == viewerState.selectedMarkupId;
      _drawMarkup(canvas, size, markup, isSelected);
    }

    // 2. Render all persistent measurements (Phase 3 Measurement Layer)
    if (visibleLayers.contains(DrawingLayer.measurement)) {
      for (final measurement in activeMeasurements) {
        final isSelected = measurement.id == viewerState.selectedMeasurementId;
        _drawMeasurement(canvas, size, measurement, isSelected);
      }
    }

    // 3. Render currently active in-progress drawing stroke/shape
    if (viewerState.isDrawingMode &&
        viewerState.selectedTool != null &&
        viewerState.inProgressPoints.isNotEmpty) {
      _drawInProgressMarkup(canvas, size);
    }

    // 4. Render currently active in-progress measurement
    if (viewerState.isDrawingMode &&
        viewerState.selectedMeasurementTool != null &&
        viewerState.inProgressPoints.isNotEmpty) {
      _drawInProgressMeasurement(canvas, size);
    }

    // 5. Render Calibration Guide & Target Crosshairs (Phase 3)
    if (viewerState.isCalibrating) {
      _drawCalibrationGuide(canvas, size);
    }

    // 6. Render selection transform handles
    if (viewerState.selectedMarkupId != null) {
      final selected = activeMarkups.where((m) => m.id == viewerState.selectedMarkupId).firstOrNull;
      if (selected != null) {
        _drawSelectionHandles(canvas, size, selected);
      }
    }
  }

  // --- Markups Rendering ---

  void _drawMarkup(Canvas canvas, Size size, Markup markup, bool isSelected) {
    final paint = Paint()
      ..color = markup.color.withOpacity(markup.opacity)
      ..strokeWidth = markup.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (markup.type) {
      case MarkupType.pen:
        _drawFreehandPath(canvas, size, markup.points, paint);
        break;
      case MarkupType.highlighter:
        final highPaint = Paint()
          ..color = markup.color.withOpacity(0.4)
          ..strokeWidth = markup.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square
          ..strokeJoin = StrokeJoin.miter
          ..blendMode = BlendMode.srcOver;
        _drawFreehandPath(canvas, size, markup.points, highPaint);
        break;
      case MarkupType.line:
        if (markup.points.length >= 2) {
          final p1 = markup.points.first.toOffset(size);
          final p2 = markup.points.last.toOffset(size);
          canvas.drawLine(p1, p2, paint);
        }
        break;
      case MarkupType.arrow:
        if (markup.points.length >= 2) {
          final p1 = markup.points.first.toOffset(size);
          final p2 = markup.points.last.toOffset(size);
          _drawArrowLine(canvas, p1, p2, paint);
        }
        break;
      case MarkupType.rectangle:
        if (markup.bounds != null) {
          final rect = _toScreenRect(markup.bounds!, size);
          if (markup.fillColor != null) {
            final fillPaint = Paint()
              ..color = markup.fillColor!
              ..style = PaintingStyle.fill;
            canvas.drawRect(rect, fillPaint);
          }
          canvas.drawRect(rect, paint);
        }
        break;
      case MarkupType.circle:
        if (markup.bounds != null) {
          final rect = _toScreenRect(markup.bounds!, size);
          if (markup.fillColor != null) {
            final fillPaint = Paint()
              ..color = markup.fillColor!
              ..style = PaintingStyle.fill;
            canvas.drawOval(rect, fillPaint);
          }
          canvas.drawOval(rect, paint);
        }
        break;
      case MarkupType.polygon:
        if (markup.points.length >= 2) {
          final path = Path();
          final start = markup.points.first.toOffset(size);
          path.moveTo(start.dx, start.dy);
          for (int i = 1; i < markup.points.length; i++) {
            final pt = markup.points[i].toOffset(size);
            path.lineTo(pt.dx, pt.dy);
          }
          if (markup.fillColor != null) {
            final fillPaint = Paint()
              ..color = markup.fillColor!
              ..style = PaintingStyle.fill;
            canvas.drawPath(path, fillPaint);
          }
          canvas.drawPath(path, paint);
        }
        break;
      case MarkupType.revisionCloud:
        _drawRevisionCloud(canvas, size, markup, paint);
        break;
      case MarkupType.text:
        _drawTextCallout(canvas, size, markup);
        break;
      case MarkupType.measurement:
        if (markup.points.length >= 2) {
          final p1 = markup.points.first.toOffset(size);
          final p2 = markup.points.last.toOffset(size);
          _drawDimensionLine(canvas, p1, p2, paint, text: markup.text);
        }
        break;
      case MarkupType.issuePin:
        _drawIssuePin(canvas, size, markup);
        break;
      case MarkupType.photoPin:
        _drawPhotoPin(canvas, size, markup);
        break;
      case MarkupType.stamp:
        _drawFieldStamp(canvas, size, markup);
        break;
      case MarkupType.eraser:
        break;
    }
  }

  // --- Phase 3: Measurements Rendering ---

  void _drawMeasurement(Canvas canvas, Size size, Measurement measurement, bool isSelected) {
    final baseColor = isSelected ? Colors.amberAccent : measurement.color;
    final paint = Paint()
      ..color = baseColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final displayLabel = measurement.formattedDisplay;

    switch (measurement.type) {
      case MeasurementType.distance:
        if (measurement.points.length >= 2) {
          final p1 = measurement.points[0].toOffset(size);
          final p2 = measurement.points[1].toOffset(size);
          _drawDimensionLine(canvas, p1, p2, paint, text: displayLabel);
        }
        break;

      case MeasurementType.polylineDistance:
        if (measurement.points.length >= 2) {
          final screenPts = measurement.points.map((p) => p.toOffset(size)).toList();
          _drawPolylineWithTicks(canvas, screenPts, paint, text: displayLabel);
        }
        break;

      case MeasurementType.area:
        if (measurement.points.length >= 3) {
          final screenPts = measurement.points.map((p) => p.toOffset(size)).toList();
          _drawAreaPolygon(canvas, screenPts, paint, text: displayLabel);
        }
        break;

      case MeasurementType.angle:
        if (measurement.points.length >= 3) {
          final p0 = measurement.points[0].toOffset(size);
          final p1 = measurement.points[1].toOffset(size);
          final p2 = measurement.points[2].toOffset(size);
          _drawAngleArc(canvas, p0, p1, p2, paint, text: displayLabel);
        }
        break;

      case MeasurementType.radius:
        if (measurement.points.length >= 2) {
          final p0 = measurement.points[0].toOffset(size);
          final p1 = measurement.points[1].toOffset(size);
          _drawRadiusMeasurement(canvas, p0, p1, paint, text: displayLabel);
        }
        break;

      case MeasurementType.diameter:
        if (measurement.points.length >= 2) {
          final p0 = measurement.points[0].toOffset(size);
          final p1 = measurement.points[1].toOffset(size);
          _drawDiameterMeasurement(canvas, p0, p1, paint, text: displayLabel);
        }
        break;

      case MeasurementType.count:
        if (measurement.points.isNotEmpty) {
          final pos = measurement.points[0].toOffset(size);
          final number = measurement.calculatedValue.toInt();
          final name = measurement.metadata?['componentName'] ?? 'Item';
          _drawCountMarker(canvas, pos, number, name, baseColor);
        }
        break;

      case MeasurementType.perimeter:
        if (measurement.points.length >= 2) {
          final screenPts = measurement.points.map((p) => p.toOffset(size)).toList();
          _drawPerimeterLoop(canvas, screenPts, paint, text: displayLabel);
        }
        break;
    }
  }

  void _drawInProgressMeasurement(Canvas canvas, Size size) {
    final mTool = viewerState.selectedMeasurementTool!;
    final points = viewerState.inProgressPoints;
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = viewerState.currentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final screenPts = points.map((p) => p.toOffset(size)).toList();
    final cal = viewerState.effectiveCalibration;
    final calcVal = MeasurementCalculator.calculateValue(type: mTool, points: points, calibration: cal);
    final unitSym = MeasurementCalculator.getUnitSymbol(mTool, cal);

    final previewLabel = '$calcVal $unitSym';

    switch (mTool) {
      case MeasurementType.distance:
      case MeasurementType.radius:
      case MeasurementType.diameter:
        if (screenPts.length >= 2) {
          _drawDimensionLine(canvas, screenPts[0], screenPts[1], paint, text: previewLabel);
        }
        break;
      case MeasurementType.polylineDistance:
      case MeasurementType.perimeter:
        if (screenPts.length >= 2) {
          _drawPolylineWithTicks(canvas, screenPts, paint, text: previewLabel);
        }
        break;
      case MeasurementType.area:
        if (screenPts.length >= 3) {
          _drawAreaPolygon(canvas, screenPts, paint, text: previewLabel);
        } else if (screenPts.length == 2) {
          canvas.drawLine(screenPts[0], screenPts[1], paint);
        }
        break;
      case MeasurementType.angle:
        if (screenPts.length >= 3) {
          _drawAngleArc(canvas, screenPts[0], screenPts[1], screenPts[2], paint, text: previewLabel);
        } else if (screenPts.length == 2) {
          canvas.drawLine(screenPts[0], screenPts[1], paint);
        }
        break;
      case MeasurementType.count:
        break;
    }
  }

  // --- Dimension & Geometry Drawing Primitives ---

  void _drawDimensionLine(Canvas canvas, Offset p1, Offset p2, Paint paint, {String? text}) {
    // Dimension line
    canvas.drawLine(p1, p2, paint);

    // Perpendicular witness ticks
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    const tickLen = 8.0;
    final normal = Offset(-math.sin(angle), math.cos(angle)) * tickLen;

    canvas.drawLine(p1 - normal, p1 + normal, paint);
    canvas.drawLine(p2 - normal, p2 + normal, paint);

    // Dimension Label Pill
    if (text != null && text.isNotEmpty) {
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      _drawLabelPill(canvas, mid, text, paint.color);
    }
  }

  void _drawPolylineWithTicks(Canvas canvas, List<Offset> points, Paint paint, {String? text}) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      // Vertex node circle
      canvas.drawCircle(points[i], 3.0, Paint()..color = paint.color..style = PaintingStyle.fill);
    }
    canvas.drawPath(path, paint);

    if (text != null && text.isNotEmpty) {
      final mid = points[points.length ~/ 2];
      _drawLabelPill(canvas, mid, 'POLY: $text', paint.color);
    }
  }

  void _drawAreaPolygon(Canvas canvas, List<Offset> points, Paint paint, {String? text}) {
    if (points.length < 3) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    double sumX = 0, sumY = 0;

    for (final p in points) {
      path.lineTo(p.dx, p.dy);
      sumX += p.dx;
      sumY += p.dy;
    }
    path.close();

    // Fill with semi-transparent tint
    final fillPaint = Paint()
      ..color = paint.color.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Centroid for Area Label Pill
    if (text != null && text.isNotEmpty) {
      final centroid = Offset(sumX / points.length, sumY / points.length);
      _drawLabelPill(canvas, centroid, 'AREA: $text', paint.color);
    }
  }

  void _drawPerimeterLoop(Canvas canvas, List<Offset> points, Paint paint, {String? text}) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (text != null && text.isNotEmpty) {
      final mid = points[0];
      _drawLabelPill(canvas, mid, 'PERI: $text', paint.color);
    }
  }

  void _drawAngleArc(Canvas canvas, Offset p0, Offset p1, Offset p2, Paint paint, {String? text}) {
    // Draw the two rays from vertex P1
    canvas.drawLine(p1, p0, paint);
    canvas.drawLine(p1, p2, paint);

    final angle1 = math.atan2(p0.dy - p1.dy, p0.dx - p1.dx);
    final angle2 = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    var sweep = angle2 - angle1;

    while (sweep < -math.pi) {
      sweep += 2 * math.pi;
    }
    while (sweep > math.pi) {
      sweep -= 2 * math.pi;
    }

    const arcRadius = 28.0;
    final rect = Rect.fromCircle(center: p1, radius: arcRadius);
    canvas.drawArc(rect, angle1, sweep, false, paint);

    // Draw vertex point
    canvas.drawCircle(p1, 4.0, Paint()..color = paint.color..style = PaintingStyle.fill);

    if (text != null && text.isNotEmpty) {
      final midAngle = angle1 + sweep / 2;
      final labelPos = p1 + Offset(math.cos(midAngle), math.sin(midAngle)) * (arcRadius + 16.0);
      _drawLabelPill(canvas, labelPos, text, paint.color);
    }
  }

  void _drawRadiusMeasurement(Canvas canvas, Offset center, Offset edge, Paint paint, {String? text}) {
    _drawArrowLine(canvas, center, edge, paint);
    canvas.drawCircle(center, 3.5, Paint()..color = paint.color..style = PaintingStyle.fill);

    final dist = (edge - center).distance;
    final dashedCircle = Paint()
      ..color = paint.color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, dist, dashedCircle);

    if (text != null && text.isNotEmpty) {
      final mid = Offset((center.dx + edge.dx) / 2, (center.dy + edge.dy) / 2);
      _drawLabelPill(canvas, mid, text, paint.color);
    }
  }

  void _drawDiameterMeasurement(Canvas canvas, Offset p1, Offset p2, Paint paint, {String? text}) {
    _drawDimensionLine(canvas, p1, p2, paint, text: text);
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final radius = (p2 - p1).distance / 2;

    final dashedCircle = Paint()
      ..color = paint.color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(mid, radius, dashedCircle);
  }

  void _drawCountMarker(Canvas canvas, Offset pos, int number, String componentName, Color color) {
    const radius = 15.0;

    // Outer glow / shadow circle
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, radius + 4, glowPaint);

    // Main badge
    final bgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pos, radius, bgPaint);
    canvas.drawCircle(pos, radius, borderPaint);

    // Number text
    final numSpan = TextSpan(
      text: '$number',
      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
    );
    final tp = TextPainter(text: numSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

    // Tag Pill below marker
    final tagSpan = TextSpan(
      text: componentName,
      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
    );
    final tagTp = TextPainter(text: tagSpan, textDirection: TextDirection.ltr)..layout();
    final tagBox = Rect.fromCenter(center: Offset(pos.dx, pos.dy + radius + 10), width: tagTp.width + 8, height: 16);
    canvas.drawRRect(RRect.fromRectAndRadius(tagBox, const Radius.circular(4)), Paint()..color = Colors.black87);
    tagTp.paint(canvas, Offset(tagBox.left + 4, tagBox.top + 2));
  }

  void _drawLabelPill(Canvas canvas, Offset center, String text, Color accentColor) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );

    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    const padding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final pillRect = Rect.fromCenter(
      center: center,
      width: tp.width + padding.horizontal,
      height: tp.height + padding.vertical,
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF1E2633).withOpacity(0.92)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(pillRect, const Radius.circular(6));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    tp.paint(canvas, Offset(pillRect.left + padding.left, pillRect.top + padding.top));
  }

  // --- Calibration Guide Rendering ---

  void _drawCalibrationGuide(Canvas canvas, Size size) {
    final points = viewerState.calibrationPoints;

    for (int i = 0; i < points.length; i++) {
      final pos = points[i].toOffset(size);
      _drawCalibrationCrosshair(canvas, pos, 'Point ${i + 1}');
    }

    if (points.length == 2) {
      final p1 = points[0].toOffset(size);
      final p2 = points[1].toOffset(size);

      final linePaint = Paint()
        ..color = const Color(0xFFFF9800)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1, p2, linePaint);
    }
  }

  void _drawCalibrationCrosshair(Canvas canvas, Offset pos, String label) {
    const size = 18.0;
    final crossPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(pos.dx - size, pos.dy), Offset(pos.dx + size, pos.dy), crossPaint);
    canvas.drawLine(Offset(pos.dx, pos.dy - size), Offset(pos.dx, pos.dy + size), crossPaint);
    canvas.drawCircle(pos, 6.0, crossPaint);
    canvas.drawCircle(pos, 2.0, Paint()..color = const Color(0xFFFF9800)..style = PaintingStyle.fill);

    _drawLabelPill(canvas, Offset(pos.dx, pos.dy - 22), label, const Color(0xFFFF9800));
  }

  // --- Standard In-Progress & Markup Helpers ---

  void _drawInProgressMarkup(Canvas canvas, Size size) {
    final tool = viewerState.selectedTool!;
    final points = viewerState.inProgressPoints;
    final bounds = viewerState.inProgressBounds;

    final paint = Paint()
      ..color = tool == MarkupType.highlighter
          ? viewerState.currentColor.withOpacity(0.4)
          : viewerState.currentColor.withOpacity(viewerState.opacity)
      ..strokeWidth = tool == MarkupType.highlighter ? 18.0 : viewerState.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (tool) {
      case MarkupType.pen:
        _drawFreehandPath(canvas, size, points, paint);
        break;
      case MarkupType.highlighter:
        paint.strokeCap = StrokeCap.square;
        _drawFreehandPath(canvas, size, points, paint);
        break;
      case MarkupType.line:
        if (points.length >= 2) {
          canvas.drawLine(points.first.toOffset(size), points.last.toOffset(size), paint);
        }
        break;
      case MarkupType.arrow:
        if (points.length >= 2) {
          _drawArrowLine(canvas, points.first.toOffset(size), points.last.toOffset(size), paint);
        }
        break;
      case MarkupType.rectangle:
        if (bounds != null) {
          final rect = _toScreenRect(bounds, size);
          canvas.drawRect(rect, paint);
        }
        break;
      case MarkupType.circle:
        if (bounds != null) {
          final rect = _toScreenRect(bounds, size);
          canvas.drawOval(rect, paint);
        }
        break;
      case MarkupType.polygon:
        if (points.length >= 2) {
          final path = Path();
          final start = points.first.toOffset(size);
          path.moveTo(start.dx, start.dy);
          for (int i = 1; i < points.length; i++) {
            final pt = points[i].toOffset(size);
            path.lineTo(pt.dx, pt.dy);
          }
          canvas.drawPath(path, paint);
        }
        break;
      case MarkupType.revisionCloud:
        if (bounds != null) {
          final rect = _toScreenRect(bounds, size);
          _drawCloudRect(canvas, rect, paint);
        }
        break;
      case MarkupType.measurement:
        if (points.length >= 2) {
          final p1 = points.first.toOffset(size);
          final p2 = points.last.toOffset(size);
          _drawDimensionLine(canvas, p1, p2, paint);
        }
        break;
      case MarkupType.text:
      case MarkupType.issuePin:
      case MarkupType.photoPin:
      case MarkupType.stamp:
      case MarkupType.eraser:
        break;
    }
  }

  void _drawFreehandPath(Canvas canvas, Size size, List<Point2D> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      final p = points.first.toOffset(size);
      canvas.drawCircle(p, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    final p0 = points[0].toOffset(size);
    path.moveTo(p0.dx, p0.dy);

    for (int i = 1; i < points.length; i++) {
      final p1 = points[i].toOffset(size);
      final pPrev = points[i - 1].toOffset(size);
      final midPoint = Offset((pPrev.dx + p1.dx) / 2, (pPrev.dy + p1.dy) / 2);
      path.quadraticBezierTo(pPrev.dx, pPrev.dy, midPoint.dx, midPoint.dy);
    }

    final pLast = points.last.toOffset(size);
    path.lineTo(pLast.dx, pLast.dy);
    canvas.drawPath(path, paint);
  }

  void _drawArrowLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    canvas.drawLine(p1, p2, paint);

    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    const arrowLength = 16.0;
    const arrowAngle = math.pi / 6;

    final arrowPath = Path();
    arrowPath.moveTo(p2.dx, p2.dy);
    arrowPath.lineTo(
      p2.dx - arrowLength * math.cos(angle - arrowAngle),
      p2.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    arrowPath.lineTo(
      p2.dx - arrowLength * math.cos(angle + arrowAngle),
      p2.dy - arrowLength * math.sin(angle + arrowAngle),
    );
    arrowPath.close();

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, fillPaint);
  }

  void _drawRevisionCloud(Canvas canvas, Size size, Markup markup, Paint paint) {
    if (markup.bounds != null) {
      final rect = _toScreenRect(markup.bounds!, size);
      _drawCloudRect(canvas, rect, paint);
    } else if (markup.points.length >= 2) {
      final screenPoints = markup.points.map((p) => p.toOffset(size)).toList();
      _drawCloudPolygon(canvas, screenPoints, paint);
    }
  }

  void _drawCloudRect(Canvas canvas, Rect rect, Paint paint) {
    final path = Path();
    const double arcRadius = 14.0;
    const double step = arcRadius * 1.5;

    for (double x = rect.left; x < rect.right; x += step) {
      final endX = math.min(x + step, rect.right);
      final midX = (x + endX) / 2;
      path.moveTo(x, rect.top);
      path.quadraticBezierTo(midX, rect.top - arcRadius, endX, rect.top);
    }
    for (double y = rect.top; y < rect.bottom; y += step) {
      final endY = math.min(y + step, rect.bottom);
      final midY = (y + endY) / 2;
      path.moveTo(rect.right, y);
      path.quadraticBezierTo(rect.right + arcRadius, midY, rect.right, endY);
    }
    for (double x = rect.right; x > rect.left; x -= step) {
      final endX = math.max(x - step, rect.left);
      final midX = (x + endX) / 2;
      path.moveTo(x, rect.bottom);
      path.quadraticBezierTo(midX, rect.bottom + arcRadius, endX, rect.bottom);
    }
    for (double y = rect.bottom; y > rect.top; y -= step) {
      final endY = math.max(y - step, rect.top);
      final midY = (y + endY) / 2;
      path.moveTo(rect.left, y);
      path.quadraticBezierTo(rect.left - arcRadius, midY, rect.left, endY);
    }

    canvas.drawPath(path, paint);
  }

  void _drawCloudPolygon(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path();
    const double arcRadius = 12.0;

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final dist = (p2 - p1).distance;
      final count = math.max(1, (dist / (arcRadius * 2)).floor());
      final normal = Offset(-(p2.dy - p1.dy) / dist, (p2.dx - p1.dx) / dist) * arcRadius;

      for (int step = 0; step < count; step++) {
        final t1 = step / count;
        final t2 = (step + 1) / count;
        final segStart = Offset.lerp(p1, p2, t1)!;
        final segEnd = Offset.lerp(p1, p2, t2)!;
        final segMid = Offset.lerp(p1, p2, (t1 + t2) / 2)! + normal;

        path.moveTo(segStart.dx, segStart.dy);
        path.quadraticBezierTo(segMid.dx, segMid.dy, segEnd.dx, segEnd.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawTextCallout(Canvas canvas, Size size, Markup markup) {
    final pos = markup.points.isNotEmpty ? markup.points.first.toOffset(size) : Offset.zero;
    final text = markup.text ?? '';
    final fontSize = markup.fontSize ?? 14.0;

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: markup.color,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final boxRect = Rect.fromLTWH(
      pos.dx,
      pos.dy,
      textPainter.width + padding.horizontal,
      textPainter.height + padding.vertical,
    );

    final bgPaint = Paint()
      ..color = (markup.fillColor ?? Colors.black).withOpacity(0.8)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = markup.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(6));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(canvas, Offset(pos.dx + padding.left, pos.dy + padding.top));
  }

  void _drawIssuePin(Canvas canvas, Size size, Markup markup) {
    final pos = markup.points.isNotEmpty ? markup.points.first.toOffset(size) : Offset.zero;
    const radius = 14.0;

    final pinPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pos, radius, pinPaint);
    canvas.drawCircle(pos, radius, borderPaint);

    final textSpan = TextSpan(
      text: markup.text ?? '!',
      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawPhotoPin(Canvas canvas, Size size, Markup markup) {
    final pos = markup.points.isNotEmpty ? markup.points.first.toOffset(size) : Offset.zero;
    const radius = 14.0;

    final pinPaint = Paint()
      ..color = Colors.amber.shade800
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pos, radius, pinPaint);
    canvas.drawCircle(pos, radius, borderPaint);

    const textSpan = TextSpan(
      text: '📷',
      style: TextStyle(fontSize: 11),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawFieldStamp(Canvas canvas, Size size, Markup markup) {
    final pos = markup.points.isNotEmpty ? markup.points.first.toOffset(size) : Offset.zero;
    final stampText = markup.text ?? '★ APPROVED FOR CONSTRUCTION ★';

    final textSpan = TextSpan(
      text: stampText,
      style: TextStyle(color: markup.color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    const padding = EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    final rect = Rect.fromLTWH(pos.dx, pos.dy, tp.width + padding.horizontal, tp.height + padding.vertical);

    final stampPaint = Paint()
      ..color = markup.color.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = markup.color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, stampPaint);
    canvas.drawRRect(rrect, borderPaint);
    tp.paint(canvas, Offset(pos.dx + padding.left, pos.dy + padding.top));
  }

  void _drawSelectionHandles(Canvas canvas, Size size, Markup selected) {
    Rect? screenBounds;
    if (selected.bounds != null) {
      screenBounds = _toScreenRect(selected.bounds!, size);
    } else if (selected.points.isNotEmpty) {
      double minX = selected.points.first.x;
      double maxX = selected.points.first.x;
      double minY = selected.points.first.y;
      double maxY = selected.points.first.y;

      for (final p in selected.points) {
        minX = math.min(minX, p.x);
        maxX = math.max(maxX, p.x);
        minY = math.min(minY, p.y);
        maxY = math.max(maxY, p.y);
      }
      screenBounds = Rect.fromLTRB(minX * size.width, minY * size.height, maxX * size.width, maxY * size.height).inflate(10);
    }

    if (screenBounds == null) return;

    final selectPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(screenBounds, selectPaint);

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const hRadius = 5.0;
    final corners = [
      screenBounds.topLeft,
      screenBounds.topRight,
      screenBounds.bottomLeft,
      screenBounds.bottomRight,
    ];

    for (final c in corners) {
      canvas.drawCircle(c, hRadius, handlePaint);
      canvas.drawCircle(c, hRadius, handleBorder);
    }
  }

  Rect _toScreenRect(Rect normalizedRect, Size size) {
    return Rect.fromLTRB(
      normalizedRect.left * size.width,
      normalizedRect.top * size.height,
      normalizedRect.right * size.width,
      normalizedRect.bottom * size.height,
    );
  }

  @override
  bool shouldRepaint(covariant DrawingMarkupPainter oldDelegate) {
    return true;
  }
}
