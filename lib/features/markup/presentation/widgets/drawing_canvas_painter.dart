import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/models/stroke.dart';
import '../../domain/models/text_label.dart';
import '../../domain/utils/stroke_smoother.dart';

class DrawingCanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<TextLabel> labels;
  final String? selectedLabelId;
  final List<Point2D> activeStrokePoints;
  final Color activeColor;
  final double activeStrokeWidth;
  final Size canvasSize;

  DrawingCanvasPainter({
    required this.strokes,
    this.labels = const [],
    this.selectedLabelId,
    required this.activeStrokePoints,
    required this.activeColor,
    required this.activeStrokeWidth,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Render all committed strokes
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = StrokeSmoother.createSmoothPath(stroke.points, size);
      canvas.drawPath(path, paint);
    }

    // 2. Render active in-progress stroke
    if (activeStrokePoints.isNotEmpty) {
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = activeStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final activePath = StrokeSmoother.createSmoothPath(activeStrokePoints, size);
      canvas.drawPath(activePath, activePaint);
    }

    // 3. Render all typed text labels with white background box and fixed engineering font
    for (final label in labels) {
      _paintTextLabel(canvas, size, label, isSelected: label.id == selectedLabelId);
    }
  }

  void _paintTextLabel(Canvas canvas, Size size, TextLabel label, {required bool isSelected}) {
    final textStyle = AppTypography.engineeringTextStyle(
      fontSize: label.fontSize,
      fontWeight: FontWeight.bold,
      color: label.color,
    );

    final textSpan = TextSpan(text: label.text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.8);

    final originX = label.x * size.width;
    final originY = label.y * size.height;
    const paddingH = 6.0;
    const paddingV = 3.0;

    final boxRect = Rect.fromLTWH(
      originX,
      originY,
      textPainter.width + (paddingH * 2),
      textPainter.height + (paddingV * 2),
    );

    // White background box (opaque so drawings underneath do not clash with text)
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(boxRect, const Radius.circular(4));
    canvas.drawRRect(rrect, bgPaint);

    // Colored border matching label color
    final borderPaint = Paint()
      ..color = label.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // Draw text inside box
    textPainter.paint(canvas, Offset(originX + paddingH, originY + paddingV));

    // If selected, draw selection bounding halo & indicator
    if (isSelected) {
      final selPaint = Paint()
        ..color = AppColors.safetyOrange
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final selRect = boxRect.inflate(3);
      final selRRect = RRect.fromRectAndRadius(selRect, const Radius.circular(6));
      canvas.drawRRect(selRRect, selPaint);

      // Corner handles
      final handlePaint = Paint()
        ..color = AppColors.safetyOrange
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selRect.topLeft, 3.5, handlePaint);
      canvas.drawCircle(selRect.topRight, 3.5, handlePaint);
      canvas.drawCircle(selRect.bottomLeft, 3.5, handlePaint);
      canvas.drawCircle(selRect.bottomRight, 3.5, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.labels != labels ||
        oldDelegate.selectedLabelId != selectedLabelId ||
        oldDelegate.activeStrokePoints != activeStrokePoints ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth;
  }
}
