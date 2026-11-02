import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/drawing_text_token.dart';
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
  final DrawingTextToken? searchHighlightToken;
  final bool Function(String?)? isAuthorVisible;

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
    this.searchHighlightToken,
    this.isAuthorVisible,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Render all committed annotations filtered by active layer & author visibility
    for (final ann in annotations) {
      if (ann.isConflictCopy) continue; // Hide conflict copies
      if (layerVisibility[ann.layer] == false) continue;
      if (isAuthorVisible != null && !isAuthorVisible!(ann.author)) continue;

      _paintAnnotation(canvas, size, ann, isSelected: ann.id == selectedAnnotationId);
    }

    // 2. Render dashed snap guide line if snapping is active during inking
    if (snapGuideLine != null && snapGuideLine!.length >= 2) {
      _paintDashedGuide(canvas, size, snapGuideLine!);
    }

    // 3. Render search match highlight box (Phase C)
    if (searchHighlightToken != null) {
      _paintSearchHighlight(canvas, size, searchHighlightToken!);
    }

    // 4. Render the active stroke in progress
    if (activeStrokePoints.isNotEmpty) {
      _paintActiveStroke(canvas, size);
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
      case AnnotationType.arrow:
        _paintLineOrArrow(canvas, size, ann);
        break;
      case AnnotationType.strikeOut:
        _paintStrikeOut(canvas, size, ann, isSelected: isSelected);
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
      case AnnotationType.noteBox:
        _paintNoteBox(canvas, size, ann, isSelected: isSelected);
        break;
      case AnnotationType.stamp:
        _paintStamp(canvas, size, ann, isSelected: isSelected);
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
  }

  void _paintSearchHighlight(Canvas canvas, Size size, DrawingTextToken token) {
    final left = token.x * size.width;
    final top = token.y * size.height;
    final width = token.width * size.width;
    final height = token.height * size.height;

    final rect = Rect.fromLTWH(left - 3, top - 2, width + 6, height + 4);

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), glowPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFF57F17)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);
  }

  void _paintActiveStroke(Canvas canvas, Size size) {
    final path = StrokeSmoother.createSmoothPath(activeStrokePoints, size);

    final paint = Paint()
      ..color = activeToolType == AnnotationType.highlighter
          ? activeColor.withOpacity(0.35)
          : activeColor
      ..strokeWidth = activeStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  void _paintFreehandStroke(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.isEmpty) return;

    final path = StrokeSmoother.createSmoothPath(ann.points, size);

    final paint = Paint()
      ..color = ann.type == AnnotationType.highlighter
          ? ann.color.withOpacity(0.35)
          : ann.color
      ..strokeWidth = ann.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  void _paintLineOrArrow(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.length < 2) return;
    final p1 = ann.points.first.toOffset(size);
    final p2 = ann.points.last.toOffset(size);

    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = ann.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(p1, p2, paint);

    if (ann.type == AnnotationType.arrow) {
      _drawArrowHead(canvas, p1, p2, ann.color, ann.strokeWidth);
    }
  }

  void _paintStrikeOut(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    if (ann.points.length < 2) return;
    final p1 = ann.points.first.toOffset(size);
    final p2 = ann.points.last.toOffset(size);

    final strikePaint = Paint()
      ..color = ann.color
      ..strokeWidth = math.max(ann.strokeWidth, 2.5)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1, p2, strikePaint);

    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final tagPainter = TextPainter(
      text: TextSpan(
        text: '✖ DELETE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          backgroundColor: ann.color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromCenter(center: mid, width: tagPainter.width + 6, height: tagPainter.height + 2);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(3)), Paint()..color = ann.color);
    tagPainter.paint(canvas, Offset(bgRect.left + 3, bgRect.top + 1));

    if (isSelected) {
      _drawBoundingHalo(canvas, Rect.fromPoints(p1, p2), ann.color);
    }
  }

  void _paintNoteBox(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    if (ann.points.isEmpty || ann.text == null || ann.text!.isEmpty) return;

    final originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;

    final textStyle = AppTypography.engineeringTextStyle(
      fontSize: ann.fontSize,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF111111),
    );

    final headerPainter = TextPainter(
      text: TextSpan(
        text: 'FIELD NOTE:',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: ann.color,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bodyPainter = TextPainter(
      text: TextSpan(text: ann.text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.45);

    const padH = 10.0;
    const padV = 8.0;
    final totalWidth = math.max(headerPainter.width, bodyPainter.width) + (padH * 2);
    final totalHeight = headerPainter.height + bodyPainter.height + (padV * 2) + 4;

    final boxRect = Rect.fromLTWH(originX, originY, totalWidth, totalHeight);
    final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(6));

    final bgPaint = Paint()..color = const Color(0xFFFFFDE7);
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = ann.color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    headerPainter.paint(canvas, Offset(originX + padH, originY + padV));
    bodyPainter.paint(canvas, Offset(originX + padH, originY + padV + headerPainter.height + 4));

    if (isSelected) {
      _drawBoundingHalo(canvas, boxRect, ann.color);
    }
  }

  void _paintStamp(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    if (ann.points.isEmpty || ann.text == null) return;

    final sealType = ann.metadata?['sealType'];
    if (sealType == 'qaQcSeal') {
      _paintQaQcSeal(canvas, size, ann, isSelected: isSelected);
      return;
    } else if (sealType == 'safetySeal') {
      _paintSafetySeal(canvas, size, ann, isSelected: isSelected);
      return;
    } else if (sealType == 'peSeal') {
      _paintPeSeal(canvas, size, ann, isSelected: isSelected);
      return;
    } else if (sealType == 'signature') {
      _paintSignature(canvas, size, ann, isSelected: isSelected);
      return;
    } else if (sealType == 'jobNumber') {
      _paintJobNumberBadge(canvas, size, ann, isSelected: isSelected);
      return;
    }

    // Default engineering status stamp (APPROVED FOR CONSTRUCTION, etc.)
    final originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;

    final titlePainter = TextPainter(
      text: TextSpan(
        text: ann.text!.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: ann.color,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final date = ann.metadata?['date'] ?? '';
    final user = ann.metadata?['user'] ?? '';
    final subPainter = TextPainter(
      text: TextSpan(
        text: '$date | $user',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: ann.color.withOpacity(0.85),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final stampWidth = math.max(titlePainter.width, subPainter.width) + 24.0;
    const stampHeight = 44.0;

    final boxRect = Rect.fromLTWH(originX, originY, stampWidth, stampHeight);
    final rrectOuter = RRect.fromRectAndRadius(boxRect, const Radius.circular(4));
    final rrectInner = RRect.fromRectAndRadius(boxRect.deflate(3.0), const Radius.circular(2));

    final bgPaint = Paint()..color = Colors.white.withOpacity(0.92);
    canvas.drawRRect(rrectOuter, bgPaint);

    final stampBorder = Paint()
      ..color = ann.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrectOuter, stampBorder);
    canvas.drawRRect(rrectInner, stampBorder..strokeWidth = 1.0);

    titlePainter.paint(canvas, Offset(originX + 12, originY + 8));
    subPainter.paint(canvas, Offset(originX + 12, originY + 26));

    if (isSelected) {
      _drawBoundingHalo(canvas, boxRect, ann.color);
    }
  }

  void _paintQaQcSeal(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    final originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;
    const radius = 40.0;
    final center = Offset(originX + radius, originY + radius);

    // Subtle paper backing
    canvas.drawCircle(center, radius, Paint()..color = Colors.white.withOpacity(0.90));

    // Outer double ring
    final outerRing = Paint()
      ..color = ann.color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 1, outerRing);
    canvas.drawCircle(center, radius - 6, outerRing..strokeWidth = 1.2);

    // Inner texts
    final t1 = TextPainter(
      text: TextSpan(text: '★ QA / QC ★', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: ann.color, letterSpacing: 1.0)),
      textDirection: TextDirection.ltr,
    )..layout();
    t1.paint(canvas, Offset(center.dx - (t1.width / 2), center.dy - 22));

    final t2 = TextPainter(
      text: TextSpan(text: 'APPROVED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ann.color, letterSpacing: 1.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    t2.paint(canvas, Offset(center.dx - (t2.width / 2), center.dy - 8));

    final dateStr = (ann.metadata?['date'] as String?)?.split(' ').first ?? '';
    final t3 = TextPainter(
      text: TextSpan(text: 'FIELD PASS • $dateStr', style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: ann.color.withOpacity(0.9))),
      textDirection: TextDirection.ltr,
    )..layout();
    t3.paint(canvas, Offset(center.dx - (t3.width / 2), center.dy + 8));

    if (isSelected) {
      _drawBoundingHalo(canvas, Rect.fromCircle(center: center, radius: radius + 2), ann.color);
    }
  }

  void _paintSafetySeal(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    final originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;
    const width = 120.0;
    const height = 54.0;
    final boxRect = Rect.fromLTWH(originX, originY, width, height);

    // Subtle paper backing
    final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(5));
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withOpacity(0.90));

    // Outer & inner safety border
    final borderPaint = Paint()
      ..color = ann.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);
    canvas.drawRRect(rrect.deflate(3.0), borderPaint..strokeWidth = 1.0);

    final header = TextPainter(
      text: TextSpan(text: '🛡️ SAFETY COMPLIANCE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: ann.color, letterSpacing: 0.8)),
      textDirection: TextDirection.ltr,
    )..layout();
    header.paint(canvas, Offset(originX + 8, originY + 7));

    final main = TextPainter(
      text: TextSpan(text: 'STRUCTURAL INTEGRITY', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: ann.color, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    main.paint(canvas, Offset(originX + 8, originY + 21));

    final dateStr = (ann.metadata?['date'] as String?)?.split(' ').first ?? '';
    final footer = TextPainter(
      text: TextSpan(text: 'ASME / OSHA CERTIFIED • $dateStr', style: TextStyle(fontSize: 6.8, fontWeight: FontWeight.w700, color: ann.color.withOpacity(0.85))),
      textDirection: TextDirection.ltr,
    )..layout();
    footer.paint(canvas, Offset(originX + 8, originY + 36));

    if (isSelected) {
      _drawBoundingHalo(canvas, boxRect, ann.color);
    }
  }

  void _paintPeSeal(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    final originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;
    const radius = 42.0;
    final center = Offset(originX + radius, originY + radius);

    // Subtle paper backing
    canvas.drawCircle(center, radius, Paint()..color = Colors.white.withOpacity(0.90));

    // Notary / PE gear rim ticks
    final tickPaint = Paint()
      ..color = ann.color.withOpacity(0.8)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final p1 = Offset(center.dx + (radius - 4) * math.cos(angle), center.dy + (radius - 4) * math.sin(angle));
      final p2 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Outer & inner ring
    final ringPaint = Paint()
      ..color = ann.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 4, ringPaint);
    canvas.drawCircle(center, radius - 10, ringPaint..strokeWidth = 1.0);

    final t1 = TextPainter(
      text: TextSpan(text: 'LICENSED P.E.', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: ann.color, letterSpacing: 0.8)),
      textDirection: TextDirection.ltr,
    )..layout();
    t1.paint(canvas, Offset(center.dx - (t1.width / 2), center.dy - 22));

    final t2 = TextPainter(
      text: TextSpan(text: 'PE-784920', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: ann.color, letterSpacing: 1.0)),
      textDirection: TextDirection.ltr,
    )..layout();
    t2.paint(canvas, Offset(center.dx - (t2.width / 2), center.dy - 8));

    final t3 = TextPainter(
      text: TextSpan(text: 'FIELD EXECUTION', style: TextStyle(fontSize: 6.8, fontWeight: FontWeight.w800, color: ann.color.withOpacity(0.9))),
      textDirection: TextDirection.ltr,
    )..layout();
    t3.paint(canvas, Offset(center.dx - (t3.width / 2), center.dy + 8));

    if (isSelected) {
      _drawBoundingHalo(canvas, Rect.fromCircle(center: center, radius: radius + 2), ann.color);
    }
  }

  void _paintSignature(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    final originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;
    const width = 130.0;
    const height = 48.0;
    final boxRect = Rect.fromLTWH(originX, originY, width, height);

    // Subtle paper backing
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
      Paint()..color = Colors.white.withOpacity(0.90),
    );

    // Fluid vector signature curve
    final sigPath = Path();
    sigPath.moveTo(originX + 14, originY + 22);
    sigPath.cubicTo(originX + 22, originY + 6, originX + 28, originY + 6, originX + 34, originY + 20);
    sigPath.cubicTo(originX + 40, originY + 28, originX + 46, originY + 12, originX + 54, originY + 14);
    sigPath.cubicTo(originX + 62, originY + 16, originX + 68, originY + 24, originX + 76, originY + 18);
    sigPath.cubicTo(originX + 86, originY + 10, originX + 96, originY + 8, originX + 106, originY + 16);
    // Flourish underline
    sigPath.moveTo(originX + 18, originY + 26);
    sigPath.quadraticBezierTo(originX + 65, originY + 30, originX + 116, originY + 24);

    final sigPaint = Paint()
      ..color = ann.color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(sigPath, sigPaint);

    // Signer name and role
    final signerPainter = TextPainter(
      text: TextSpan(
        text: 'Yadhukrishna, PE • Lead Field Eng',
        style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: ann.color.withOpacity(0.9)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    signerPainter.paint(canvas, Offset(originX + 14, originY + 32));

    if (isSelected) {
      _drawBoundingHalo(canvas, boxRect, ann.color);
    }
  }

  void _paintJobNumberBadge(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    final originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;
    const width = 115.0;
    const height = 38.0;
    final boxRect = Rect.fromLTWH(originX, originY, width, height);

    // Subtle paper backing
    final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(4));
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withOpacity(0.92));

    final border = Paint()
      ..color = ann.color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, border);

    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'PROJECT / JOB NUMBER',
        style: TextStyle(fontSize: 7.0, fontWeight: FontWeight.w800, color: ann.color.withOpacity(0.85), letterSpacing: 0.8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(originX + 8, originY + 5));

    final valPainter = TextPainter(
      text: TextSpan(
        text: ann.text ?? 'JOB-2026-001',
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, fontFamily: 'JetBrainsMono', color: ann.color, letterSpacing: 1.0),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    valPainter.paint(canvas, Offset(originX + 8, originY + 17));

    if (isSelected) {
      _drawBoundingHalo(canvas, boxRect, ann.color);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset p1, Offset p2, Color color, double strokeWidth) {
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    const arrowLen = 14.0;
    const arrowAngle = 0.45;

    final a1 = Offset(
      p2.dx - arrowLen * math.cos(angle - arrowAngle),
      p2.dy - arrowLen * math.sin(angle - arrowAngle),
    );
    final a2 = Offset(
      p2.dx - arrowLen * math.cos(angle + arrowAngle),
      p2.dy - arrowLen * math.sin(angle + arrowAngle),
    );

    final path = Path()
      ..moveTo(p2.dx, p2.dy)
      ..lineTo(a1.dx, a1.dy)
      ..lineTo(a2.dx, a2.dy)
      ..close();

    final paint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _paintRectangle(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.length < 2) return;
    final p1 = ann.points.first.toOffset(size);
    final p2 = ann.points.last.toOffset(size);

    final rect = Rect.fromPoints(p1, p2);
    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = ann.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);
  }

  void _paintRevisionCloud(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.length < 2) return;
    final p1 = ann.points.first.toOffset(size);
    final p2 = ann.points.last.toOffset(size);

    final rect = Rect.fromPoints(p1, p2);
    final cloudPath = Path();

    const arcRadius = 14.0;
    final left = rect.left;
    final right = rect.right;
    final top = rect.top;
    final bottom = rect.bottom;

    cloudPath.moveTo(left, top);

    for (double x = left; x < right; x += arcRadius * 1.5) {
      final nextX = math.min(x + arcRadius * 1.5, right);
      cloudPath.arcToPoint(Offset(nextX, top), radius: const Radius.circular(arcRadius), clockwise: false);
    }
    for (double y = top; y < bottom; y += arcRadius * 1.5) {
      final nextY = math.min(y + arcRadius * 1.5, bottom);
      cloudPath.arcToPoint(Offset(right, nextY), radius: const Radius.circular(arcRadius), clockwise: false);
    }
    for (double x = right; x > left; x -= arcRadius * 1.5) {
      final nextX = math.max(x - arcRadius * 1.5, left);
      cloudPath.arcToPoint(Offset(nextX, bottom), radius: const Radius.circular(arcRadius), clockwise: false);
    }
    for (double y = bottom; y > top; y -= arcRadius * 1.5) {
      final nextY = math.max(y - arcRadius * 1.5, top);
      cloudPath.arcToPoint(Offset(left, nextY), radius: const Radius.circular(arcRadius), clockwise: false);
    }

    cloudPath.close();

    final paint = Paint()
      ..color = ann.color
      ..strokeWidth = ann.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(cloudPath, paint);
  }

  void _paintCircle(Canvas canvas, Size size, AnnotationItem ann) {
    if (ann.points.isEmpty) return;
    final center = ann.points.first.toOffset(size);
    double radius = 20.0;

    if (ann.metadata != null && ann.metadata!['radius'] != null) {
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

    final fontId = ann.metadata?['fontFamily'] as String?;
    final font = EngineeringFont.fromId(fontId);
    final alignment = (ann.metadata?['alignment'] as String?) ?? 'left';

    final textStyle = AppTypography.getTextStyle(
      font: font,
      fontSize: ann.fontSize,
      fontWeight: FontWeight.bold,
      color: ann.color,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: ann.text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: alignment == 'center'
          ? TextAlign.center
          : (alignment == 'right' ? TextAlign.right : TextAlign.left),
    )..layout(maxWidth: size.width * 0.8);

    double originX = ann.points.first.x * size.width;
    final originY = ann.points.first.y * size.height;

    // Proper baseline & horizontal alignment
    if (alignment == 'center') {
      originX -= (textPainter.width / 2);
    } else if (alignment == 'right') {
      originX -= textPainter.width;
    }

    final boxRect = Rect.fromLTWH(
      originX,
      originY,
      textPainter.width,
      textPainter.height,
    );

    // Transparent blueprint text - rendered aligned in the chosen downloaded font
    textPainter.paint(canvas, Offset(originX, originY));

    if (ann.attachedTag != null) {
      final tagPainter = TextPainter(
        text: TextSpan(
          text: '🔗 TAG: ${ann.attachedTag!.text}',
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00695C),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tagPainter.paint(canvas, Offset(originX, originY + boxRect.height + 2));
    }

    if (isSelected) {
      _drawBoundingHalo(canvas, boxRect.inflate(4.0), ann.color);

      // Drafting alignment guide baseline
      final guidePaint = Paint()
        ..color = ann.color.withOpacity(0.45)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(originX - 12, originY + textPainter.height + 1),
        Offset(originX + textPainter.width + 12, originY + textPainter.height + 1),
        guidePaint,
      );
    }
  }

  void _paintCallout(Canvas canvas, Size size, AnnotationItem ann, {required bool isSelected}) {
    if (ann.points.length < 2) return;
    final targetPt = ann.points[0].toOffset(size);
    final boxOrigin = ann.points[1].toOffset(size);

    final fontId = ann.metadata?['fontFamily'] as String?;
    final font = EngineeringFont.fromId(fontId);
    final textStyle = AppTypography.getTextStyle(
      font: font,
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

    final leaderAnchor = Offset(boxOrigin.dx, boxOrigin.dy + (boxRect.height / 2));
    final leaderPaint = Paint()
      ..color = ann.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(leaderAnchor, targetPt, leaderPaint);
    canvas.drawCircle(targetPt, 3.5, Paint()..color = ann.color);

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

    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final normX = -math.sin(angle) * 6.0;
    final normY = math.cos(angle) * 6.0;

    canvas.drawLine(Offset(p1.dx - normX, p1.dy - normY), Offset(p1.dx + normX, p1.dy + normY), paint);
    canvas.drawLine(Offset(p2.dx - normX, p2.dy - normY), Offset(p2.dx + normX, p2.dy + normY), paint);

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

    final pinColor = isPhoto ? const Color(0xFF185FA5) : const Color(0xFF7A3FB5);

    // Outer circle
    final pinPaint = Paint()..color = pinColor;
    canvas.drawCircle(center, 13, pinPaint);
    canvas.drawCircle(center, 13, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // Inner icon text
    final iconPainter = TextPainter(
      text: TextSpan(
        text: isPhoto ? '📷' : '🎙️',
        style: const TextStyle(fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2));

    // GPS Tag chip if GPS coordinate is attached
    if (ann.gps != null) {
      final gpsPainter = TextPainter(
        text: const TextSpan(
          text: '📍 GPS',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            backgroundColor: Color(0xFF08605B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final gpsRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + 18),
        width: gpsPainter.width + 6,
        height: gpsPainter.height + 2,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(gpsRect, const Radius.circular(3)), Paint()..color = const Color(0xFF08605B));
      gpsPainter.paint(canvas, Offset(gpsRect.left + 3, gpsRect.top + 1));
    }

    if (isSelected) {
      _drawBoundingHalo(canvas, Rect.fromCircle(center: center, radius: 18), pinColor);
    }
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
    if (totalLen == 0) return;

    const dashLen = 6.0;
    const gapLen = 4.0;
    double current = 0;

    while (current < totalLen) {
      final startT = current / totalLen;
      final endT = math.min((current + dashLen) / totalLen, 1.0);

      final startPt = Offset(p1.dx + dx * startT, p1.dy + dy * startT);
      final endPt = Offset(p1.dx + dx * endT, p1.dy + dy * endT);

      canvas.drawLine(startPt, endPt, guidePaint);
      current += dashLen + gapLen;
    }
  }

  void _drawBoundingHalo(Canvas canvas, Rect bounds, Color color) {
    final haloPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final inflated = bounds.inflate(6.0);
    final rrect = RRect.fromRectAndRadius(inflated, const Radius.circular(6));

    canvas.drawRRect(rrect, haloPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    return true;
  }
}
