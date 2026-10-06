import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/markup_layer.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/utils/stroke_smoother.dart';

class DrawingCanvasPainter extends CustomPainter {
  final List<AnnotationItem> annotations;
  final Map<MarkupLayer, bool> layerVisibility;
  final String? selectedAnnotationId;
  final List<Point2D> activeStrokePoints;
  final Color activeColor;
  final double activeStrokeWidth;
  final AnnotationType activeToolType;
  final List<Point2D>? snapGuideLine;
  final Size canvasSize;

  DrawingCanvasPainter({
    required this.annotations,
    this.layerVisibility = const {},
    this.selectedAnnotationId,
    required this.activeStrokePoints,
    required this.activeColor,
    required this.activeStrokeWidth,
    this.activeToolType = AnnotationType.stroke,
    this.snapGuideLine,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Render all committed annotations filtered by active layer visibility
    for (final ann in annotations) {
      if (layerVisibility[ann.layer] == false) continue;
      _paintAnnotation(canvas, size, ann, isSelected: ann.id == selectedAnnotationId);
    }

    // 2. Render dashed snap guide line if snapping is active during inking
    if (snapGuideLine != null && snapGuideLine!.length >= 2) {
      _paintDashedGuide(canvas, size, snapGuideLine!);
    }

    // 3. Render active in-progress stroke
    if (activeStrokePoints.isNotEmpty) {
      final isHighlighter = activeToolType == AnnotationType.highlighter;
      final activePaint = Paint()
        ..color = isHighlighter ? activeColor.withOpacity(0.35) : activeColor
        ..strokeWidth = isHighlighter ? activeStrokeWidth * 3.5 : activeStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = isHighlighter ? StrokeCap.square : StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (activeStrokePoints.length == 1) {
        final pt = activeStrokePoints.first.toOffset(size);
        canvas.drawCircle(pt, activeStrokeWidth / 2, activePaint..style = PaintingStyle.fill);
      } else {
        final activePath = StrokeSmoother.createSmoothPath(activeStrokePoints, size);
        canvas.drawPath(activePath, activePaint);
      }
    }
  }

  void _paintAnnotation(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    switch (ann.type) {
      case AnnotationType.stroke:
      case AnnotationType.marker:
      case AnnotationType.highlighter:
        _paintFreehandStroke(canvas, size, ann);
        break;
      case AnnotationType.line:
        _paintStraightLine(canvas, size, ann);
        break;
      case AnnotationType.arrow:
        _paintArrow(canvas, size, ann);
        break;
      case AnnotationType.rectangle:
        _paintRectangle(canvas, size, ann);
        break;
      case AnnotationType.cloud:
        _paintRevisionCloud(canvas, size, ann);
        break;
      case AnnotationType.circle:
        _paintCircle(canvas, size, ann);
        break;
      case AnnotationType.text:
        _paintText(canvas, size, ann, isSelected: isSelected);
        break;
      case AnnotationType.callout:
        _paintCallout(canvas, size, ann, isSelected: isSelected);
        break;
      case AnnotationType.dimension:
        _paintDimension(canvas, size, ann);
        break;
      case AnnotationType.photoPin:
      case AnnotationType.voicePin:
        _paintPin(canvas, size, ann, isSelected: isSelected);
        break;
    }

    if (isSelected && ann.type != AnnotationType.text && ann.points.isNotEmpty) {
      _paintSelectionHalo(canvas, size, ann);
    }
  }

  void _paintFreehandStroke(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.isEmpty) return;
    final isHighlighter = ann.type == AnnotationType.highlighter;
    final paint = Paint()
      ..color = isHighlighter ? ann.color.withOpacity(0.35) : ann.color
      ..strokeWidth = isHighlighter ? ann.strokeWidth * 3.5 : ann.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = isHighlighter ? StrokeCap.square : StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = StrokeSmoother.createSmoothPath(ann.points, size);
    canvas.drawPath(path, paint);
  }

  void _paintStraightLine(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.length < 2) return;
    final p1 = ann.points[0].toOffset(size);
    final p2 = ann.points[1].toOffset(size);

    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = ann.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(p1, p2, paint);
  }

  void _paintArrow(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.length < 2) return;
    final p1 = ann.points[0].toOffset(size);
    final p2 = ann.points[1].toOffset(size);

    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = ann.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw main shaft
    canvas.drawLine(p1, p2, paint);

    // Calculate Arrowhead Barbs
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    const arrowHeadLen = 14.0;
    const arrowAngle = 26 * math.pi / 180;

    final barb1 = Offset(
      p2.dx - arrowHeadLen * math.cos(angle - arrowAngle),
      p2.dy - arrowHeadLen * math.sin(angle - arrowAngle),
    );
    final barb2 = Offset(
      p2.dx - arrowHeadLen * math.cos(angle + arrowAngle),
      p2.dy - arrowHeadLen * math.sin(angle + arrowAngle),
    );

    final headPath = Path()
      ..moveTo(barb1.dx, barb1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(barb2.dx, barb2.dy);

    canvas.drawPath(headPath, paint);
  }

  void _paintRectangle(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.length < 4) return;
    final path = Path()..moveTo(ann.points[0].x * size.width, ann.points[0].y * size.height);
    for (int i = 1; i < ann.points.length; i++) {
      path.lineTo(ann.points[i].x * size.width, ann.points[i].y * size.height);
    }
    path.close();

    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = ann.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(path, paint);
  }

  void _paintRevisionCloud(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.length < 3) return;
    final path = Path();
    final pts = ann.points.map((p) => p.toOffset(size)).toList();

    path.moveTo(pts[0].dx, pts[0].dy);

    for (int i = 0; i < pts.length; i++) {
      final curr = pts[i];
      final next = pts[(i + 1) % pts.length];

      final midX = (curr.dx + next.dx) / 2;
      final midY = (curr.dy + next.dy) / 2;
      final dx = next.dx - curr.dx;
      final dy = next.dy - curr.dy;
      final len = math.sqrt(dx * dx + dy * dy);

      if (len > 0) {
        // Normal vector pointing outwards
        final normX = -dy / len;
        final normY = dx / len;
        final bulge = len * 0.35;
        final ctrlX = midX + normX * bulge;
        final ctrlY = midY + normY * bulge;

        path.quadraticBezierTo(ctrlX, ctrlY, next.dx, next.dy);
      } else {
        path.lineTo(next.dx, next.dy);
      }
    }

    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = ann.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _paintCircle(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.isEmpty) return;
    final center = ann.points[0].toOffset(size);
    double radius = 24.0;

    if (ann.metadata?['radius'] != null) {
      radius = (ann.metadata!['radius'] as num).toDouble() * size.width;
    } else if (ann.points.length >= 2) {
      final p2 = ann.points[1].toOffset(size);
      radius = (p2 - center).distance;
    }

    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = ann.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paint);
  }

  void _paintText(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    if (ann.points.isEmpty || ann.text == null || ann.text!.isEmpty) return;

    final textStyle = AppTypography.engineeringTextStyle(
      fontSize: ann.fontSize,
      fontWeight: FontWeight.bold,
      color: ann.color,
    );

    final textSpan = TextSpan(text: ann.text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.8);

    final originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;
    const paddingH = 6.0;
    const paddingV = 3.0;

    final boxRect = Rect.fromLTWH(
      originX,
      originY,
      textPainter.width + (paddingH * 2),
      textPainter.height + (paddingV * 2),
    );

    // White background box
    final bgPaint = Paint()..color = Colors.white;
    final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(4));
    canvas.drawRRect(rrect, bgPaint);

    // Border matching label color
    final borderPaint = Paint()
      ..color = ann.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(canvas, Offset(originX + paddingH, originY + paddingV));

    if (isSelected) {
      _drawBoundingHalo(canvas, boxRect, ann.color);
    }
  }

  void _paintCallout(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    if (ann.points.length < 2) return;
    final targetPt = ann.points[0].toOffset(size);
    final boxOrigin = ann.points[1].toOffset(size);

    final textStyle = AppTypography.engineeringTextStyle(
      fontSize: ann.fontSize,
      fontWeight: FontWeight.bold,
      color: ann.color,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: ann.text ?? 'Callout', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.6);

    const padH = 8.0;
    const padV = 4.0;
    final boxRect = Rect.fromLTWH(
      boxOrigin.dx,
      boxOrigin.dy,
      textPainter.width + padH * 2,
      textPainter.height + padV * 2,
    );

    // Leader line from box anchor to target
    final leaderAnchor = Offset(boxOrigin.dx, boxOrigin.dy + (boxRect.height / 2));
    final leaderPaint = Paint()
      ..color = ann.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(leaderAnchor, targetPt, leaderPaint);
    canvas.drawCircle(targetPt, 3.5, Paint()..color = ann.color);

    // Rounded text box
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(6)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(6)),
      leaderPaint,
    );

    textPainter.paint(canvas, Offset(boxOrigin.dx + padH, boxOrigin.dy + padV));
  }

  void _paintDimension(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.length < 2) return;
    final p1 = ann.points[0].toOffset(size);
    final p2 = ann.points[1].toOffset(size);

    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(p1, p2, paint);

    // Perpendicular end ticks
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final normX = -math.sin(angle) * 6.0;
    final normY = math.cos(angle) * 6.0;

    canvas.drawLine(Offset(p1.dx - normX, p1.dy - normY), Offset(p1.dx + normX, p1.dy + normY), paint);
    canvas.drawLine(Offset(p2.dx - normX, p2.dy - normY), Offset(p2.dx + normX, p2.dy + normY), paint);

    // Dimension label at midpoint
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final labelText = ann.text ?? 'DIM';

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: AppTypography.engineeringTextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ann.color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelRect = Rect.fromCenter(center: mid, width: textPainter.width + 8, height: textPainter.height + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(3)), Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(3)), paint..strokeWidth = 1.0);
    textPainter.paint(canvas, Offset(labelRect.left + 4, labelRect.top + 2));
  }

  void _paintPin(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    if (ann.points.isEmpty) return;
    final center = ann.points.first.toOffset(size);
    final isPhoto = ann.type == AnnotationType.photoPin;

    final pinPaint = Paint()..color = isPhoto ? const Color(0xFF185FA5) : const Color(0xFF7A3FB5);
    canvas.drawCircle(center, 12, pinPaint);
    canvas.drawCircle(center, 12, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _paintDashedGuide(Canvas canvas, Size size, List<Point2D> guidePts) {
    final p1 = guidePts.first.toOffset(size);
    final p2 = guidePts.last.toOffset(size);

    final guidePaint = Paint()
      ..color = const Color(0xFF185FA5).withOpacity(0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final totalLen = math.sqrt(dx * dx + dy * dy);
    if (totalLen <= 0) return;

    const dashLen = 6.0;
    const spaceLen = 4.0;
    double dist = 0.0;

    while (dist < totalLen) {
      final t1 = dist / totalLen;
      final t2 = math.min((dist + dashLen) / totalLen, 1.0);
      final segStart = Offset(p1.dx + t1 * dx, p1.dy + t1 * dy);
      final segEnd = Offset(p1.dx + t2 * dx, p1.dy + t2 * dy);
      canvas.drawLine(segStart, segEnd, guidePaint);
      dist += dashLen + spaceLen;
    }
  }

  void _paintSelectionHalo(Canvas canvas, Size size, AnnotationItem ann) {
    double minX = ann.points[0].x, maxX = ann.points[0].x;
    double minY = ann.points[0].y, maxY = ann.points[0].y;

    for (final p in ann.points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final boxRect = Rect.fromLTRB(
      minX * size.width - 6,
      minY * size.height - 6,
      maxX * size.width + 6,
      maxY * size.height + 6,
    );

    _drawBoundingHalo(canvas, boxRect, ann.color);
  }

  void _drawBoundingHalo(Canvas canvas, Rect rect, Color color) {
    final selPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, selPaint);

    final handlePaint = Paint()..color = color;
    canvas.drawCircle(rect.topLeft, 3.5, handlePaint);
    canvas.drawCircle(rect.topRight, 3.5, handlePaint);
    canvas.drawCircle(rect.bottomLeft, 3.5, handlePaint);
    canvas.drawCircle(rect.bottomRight, 3.5, handlePaint);
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.layerVisibility != layerVisibility ||
        oldDelegate.selectedAnnotationId != selectedAnnotationId ||
        oldDelegate.activeStrokePoints != activeStrokePoints ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth ||
        oldDelegate.snapGuideLine != snapGuideLine;
  }
}
