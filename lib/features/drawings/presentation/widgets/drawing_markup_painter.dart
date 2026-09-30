import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/markup.dart';
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

    // 1. Render all persistent markups on active page matching visible layers
    for (final markup in activeMarkups) {
      if (!visibleLayers.contains(markup.layer)) continue;
      final isSelected = markup.id == viewerState.selectedMarkupId;
      _drawMarkup(canvas, size, markup, isSelected);
    }

    // 2. Render currently active in-progress drawing stroke/shape
    if (viewerState.isDrawingMode &&
        viewerState.selectedTool != null &&
        viewerState.inProgressPoints.isNotEmpty) {
      _drawInProgressMarkup(canvas, size);
    }

    // 3. Render selection transform handles
    if (viewerState.selectedMarkupId != null) {
      final selected = activeMarkups.where((m) => m.id == viewerState.selectedMarkupId).firstOrNull;
      if (selected != null) {
        _drawSelectionHandles(canvas, size, selected);
      }
    }
  }

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
        _drawMeasurementRuler(canvas, size, markup, paint);
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
          _drawMeasurementPreview(canvas, p1, p2, paint);
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

    // Draw arrowhead
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    const arrowLength = 16.0;
    const arrowAngle = math.pi / 6; // 30 degrees

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
      // Trace scallops along polygon path
      final screenPoints = markup.points.map((p) => p.toOffset(size)).toList();
      _drawCloudPolygon(canvas, screenPoints, paint);
    }
  }

  void _drawCloudRect(Canvas canvas, Rect rect, Paint paint) {
    final path = Path();
    const double arcRadius = 14.0;
    const double step = arcRadius * 1.5;

    // Top edge
    for (double x = rect.left; x < rect.right; x += step) {
      final endX = math.min(x + step, rect.right);
      final midX = (x + endX) / 2;
      path.moveTo(x, rect.top);
      path.quadraticBezierTo(midX, rect.top - arcRadius, endX, rect.top);
    }
    // Right edge
    for (double y = rect.top; y < rect.bottom; y += step) {
      final endY = math.min(y + step, rect.bottom);
      final midY = (y + endY) / 2;
      path.moveTo(rect.right, y);
      path.quadraticBezierTo(rect.right + arcRadius, midY, rect.right, endY);
    }
    // Bottom edge
    for (double x = rect.right; x > rect.left; x -= step) {
      final endX = math.max(x - step, rect.left);
      final midX = (x + endX) / 2;
      path.moveTo(x, rect.bottom);
      path.quadraticBezierTo(midX, rect.bottom + arcRadius, endX, rect.bottom);
    }
    // Left edge
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

    final padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final boxRect = Rect.fromLTWH(
      pos.dx,
      pos.dy,
      textPainter.width + padding.horizontal,
      textPainter.height + padding.vertical,
    );

    // Background pill/box
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

  void _drawMeasurementRuler(Canvas canvas, Size size, Markup markup, Paint paint) {
    if (markup.points.length < 2) return;
    final p1 = markup.points.first.toOffset(size);
    final p2 = markup.points.last.toOffset(size);
    _drawMeasurementPreview(canvas, p1, p2, paint, customText: markup.text);
  }

  void _drawMeasurementPreview(Canvas canvas, Offset p1, Offset p2, Paint paint, {String? customText}) {
    // Dimension line
    canvas.drawLine(p1, p2, paint);

    // Witness marks / ticks perpendicular to line
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    const tickLen = 8.0;
    final normal = Offset(-math.sin(angle), math.cos(angle)) * tickLen;

    canvas.drawLine(p1 - normal, p1 + normal, paint);
    canvas.drawLine(p2 - normal, p2 + normal, paint);

    // Distance calculation (e.g. in mm based on 1:50 scale)
    final distancePx = (p2 - p1).distance;
    final distanceMm = (distancePx * 5.0).round();
    final label = customText ?? '$distanceMm mm';

    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: paint.color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
    );

    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2 - 12));
  }

  void _drawIssuePin(Canvas canvas, Size size, Markup markup) {
    final pos = markup.points.isNotEmpty ? markup.points.first.toOffset(size) : Offset.zero;
    const radius = 14.0;

    // Pin circle
    final pinPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pos, radius, pinPaint);
    canvas.drawCircle(pos, radius, borderPaint);

    // Pin Tag Text
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

    final textSpan = const TextSpan(
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

    final padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
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

    // Draw 4 corner handles
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
    return true; // Fast redraw on pan, zoom or stroke movement
  }
}
