import 'package:flutter/material.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/models/stroke.dart';
import '../../domain/utils/stroke_smoother.dart';

class DrawingCanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Point2D> activeStrokePoints;
  final Color activeColor;
  final double activeStrokeWidth;
  final Size canvasSize;

  DrawingCanvasPainter({
    required this.strokes,
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
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activeStrokePoints != activeStrokePoints ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth;
  }
}
