import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/markup.dart';
import '../../domain/models/measurement.dart';
import '../../domain/utils/stroke_smoother.dart';
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
          ..color = markup.color.withOpacity(0.38)
          ..strokeWidth = markup.strokeWidth > 0 ? markup.strokeWidth : 20.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
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
        if (markup.points.length >= 3) {
          final path = Path();
          final start = markup.points.first.toOffset(size);
          path.moveTo(start.dx, start.dy);
          for (int i = 1; i < markup.points.length; i++) {
            final p = markup.points[i].toOffset(size);
            path.lineTo(p.dx, p.dy);
          }
          path.close();
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
      case MarkupType.measurement:
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

    final smoothPath = StrokeSmoother.createSmoothPath(points, size);
    canvas.drawPath(smoothPath, paint);
  }

  void _drawArrowLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    canvas.drawLine(p1, p2, paint);

    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    const arrowLength = 16.0;
    const arrowAngle = math.pi / 6;

    final arrowPath = Path()
      ..moveTo(p2.dx, p2.dy)
      ..lineTo(
        p2.dx - arrowLength * math.cos(angle - arrowAngle),
        p2.dy - arrowLength * math.sin(angle - arrowAngle),
      )
      ..lineTo(
        p2.dx - arrowLength * math.cos(angle + arrowAngle),
        p2.dy - arrowLength * math.sin(angle + arrowAngle),
      )
      ..close();

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, fillPaint);
  }

  void _drawRevisionCloud(Canvas canvas, Size size, Markup markup, Paint paint) {
    if (markup.bounds != null) {
      final screenRect = _toScreenRect(markup.bounds!, size);
      _drawCloudRect(canvas, screenRect, paint);
    } else if (markup.points.length >= 3) {
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
      if (dist <= 0.001) continue;
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

  /// Uniform Engineering Font Text Callout with Halo & Leader Line
  void _drawTextCallout(Canvas canvas, Size size, Markup markup) {
    final pos = markup.points.isNotEmpty ? markup.points.first.toOffset(size) : Offset.zero;
    final text = markup.text ?? '';
    final fontSize = markup.fontSize ?? 13.0;
    final rotation = markup.rotation ?? 0.0;

    // Strict Uniform Technical Font (AppTypography)
    final textSpan = TextSpan(
      text: text,
      style: AppTypography.engineeringTextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: markup.color,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final boxWidth = textPainter.width + padding.horizontal;
    final boxHeight = textPainter.height + padding.vertical;
    final boxRect = Rect.fromLTWH(0, 0, boxWidth, boxHeight);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (rotation != 0.0) {
      canvas.rotate(rotation);
    }

    // 1. Draw Background Box / Halo for 100% legibility over CAD drawing lines
    if (markup.hasHalo) {
      final bgPaint = Paint()
        ..color = (markup.fillColor ?? const Color(0xFF0F172A)).withOpacity(0.88)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = markup.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(5));
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);
    }

    // 2. Paint uniform engineering text
    textPainter.paint(canvas, Offset(padding.left, padding.top));
    canvas.restore();

    // 3. Draw Leader Arrow Line if leader point is specified
    if (markup.leaderPoint != null) {
      final leaderScreen = markup.leaderPoint!.toOffset(size);
      final boxCenter = Offset(pos.dx + boxWidth / 2, pos.dy + boxHeight / 2);

      final leaderPaint = Paint()
        ..color = markup.color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      _drawArrowLine(canvas, boxCenter, leaderScreen, leaderPaint);
    }
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
      style: AppTypography.engineeringTextStyle(
        color: markup.color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
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

  void _drawInProgressMarkup(Canvas canvas, Size size) {
    final tool = viewerState.selectedTool!;
    final points = viewerState.inProgressPoints;
    final bounds = viewerState.inProgressBounds;

    final paint = Paint()
      ..color = viewerState.activeColor
      ..strokeWidth = tool == MarkupType.highlighter ? 20.0 : viewerState.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (tool == MarkupType.highlighter) {
      paint.color = viewerState.activeColor.withOpacity(0.38);
      paint.blendMode = BlendMode.srcOver;
    }

    if (tool == MarkupType.eraser) {
      if (points.isNotEmpty) {
        final lastPoint = points.last.toOffset(size);
        const radius = 18.0;
        final eraserPaint = Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..style = PaintingStyle.fill;
        final eraserBorder = Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(lastPoint, radius, eraserPaint);
        canvas.drawCircle(lastPoint, radius, eraserBorder);
      }
      return;
    }

    if (tool == MarkupType.pen || tool == MarkupType.highlighter) {
      _drawFreehandPath(canvas, size, points, paint);
    } else if (tool == MarkupType.line && points.length >= 2) {
      canvas.drawLine(points.first.toOffset(size), points.last.toOffset(size), paint);
    } else if (tool == MarkupType.arrow && points.length >= 2) {
      _drawArrowLine(canvas, points.first.toOffset(size), points.last.toOffset(size), paint);
    } else if (tool == MarkupType.rectangle && bounds != null) {
      canvas.drawRect(_toScreenRect(bounds, size), paint);
    } else if (tool == MarkupType.circle && bounds != null) {
      canvas.drawOval(_toScreenRect(bounds, size), paint);
    } else if (tool == MarkupType.revisionCloud && bounds != null) {
      _drawCloudRect(canvas, _toScreenRect(bounds, size), paint);
    }
  }

  void _drawMeasurement(Canvas canvas, Size size, Measurement measurement, bool isSelected) {
    final paint = Paint()
      ..color = isSelected ? Colors.amber : measurement.color
      ..strokeWidth = isSelected ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    final points = measurement.points.map((p) => p.toOffset(size)).toList();
    if (points.isEmpty) return;

    switch (measurement.type) {
      case MeasurementType.distance:
      case MeasurementType.polylineDistance:
      case MeasurementType.perimeter:
        if (points.length >= 2) {
          for (int i = 0; i < points.length - 1; i++) {
            _drawDimensionLine(canvas, points[i], points[i + 1], paint, measurement.formattedDisplay);
          }
        }
        break;
      case MeasurementType.area:
        if (points.length >= 3) {
          final path = Path()..moveTo(points.first.dx, points.first.dy);
          for (int i = 1; i < points.length; i++) {
            path.lineTo(points[i].dx, points[i].dy);
          }
          path.close();

          final fillPaint = Paint()
            ..color = measurement.color.withOpacity(0.18)
            ..style = PaintingStyle.fill;
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, paint);

          final center = points.reduce((a, b) => a + b) / points.length.toDouble();
          _drawLabelBadge(canvas, center, measurement.formattedDisplay, measurement.color);
        }
        break;
      case MeasurementType.angle:
      case MeasurementType.radius:
      case MeasurementType.diameter:
      case MeasurementType.count:
        if (points.isNotEmpty) {
          final p = points.first;
          _drawLabelBadge(canvas, p, measurement.formattedDisplay, measurement.color);
        }
        break;
    }
  }

  void _drawDimensionLine(Canvas canvas, Offset p1, Offset p2, Paint paint, String label) {
    canvas.drawLine(p1, p2, paint);

    const tickSize = 6.0;
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final normalAngle = angle + math.pi / 2;

    final nOffset = Offset(math.cos(normalAngle), math.sin(normalAngle)) * tickSize;
    canvas.drawLine(p1 - nOffset, p1 + nOffset, paint);
    canvas.drawLine(p2 - nOffset, p2 + nOffset, paint);

    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    _drawLabelBadge(canvas, mid, label, paint.color);
  }

  void _drawLabelBadge(Canvas canvas, Offset position, String label, Color color) {
    final textSpan = TextSpan(
      text: label,
      style: AppTypography.engineeringTextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    final bgRect = Rect.fromCenter(
      center: position,
      width: tp.width + 12,
      height: tp.height + 6,
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(4));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy - tp.height / 2));
  }

  void _drawInProgressMeasurement(Canvas canvas, Size size) {
    final points = viewerState.inProgressPoints.map((p) => p.toOffset(size)).toList();
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = viewerState.activeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (points.length >= 2) {
      canvas.drawLine(points.first, points.last, paint);
    }
  }

  void _drawCalibrationGuide(Canvas canvas, Size size) {
    final points = viewerState.calibrationPoints.map((p) => p.toOffset(size)).toList();
    final guidePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 6.0, guidePaint);
      canvas.drawLine(Offset(p.dx - 10, p.dy), Offset(p.dx + 10, p.dy), guidePaint);
      canvas.drawLine(Offset(p.dx, p.dy - 10), Offset(p.dx, p.dy + 10), guidePaint);
    }

    if (points.length == 2) {
      canvas.drawLine(points[0], points[1], guidePaint);
    }
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
