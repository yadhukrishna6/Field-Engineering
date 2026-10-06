import 'package:flutter/material.dart';

/// Decorative vector painter rendering organic desert dune wave curves
class DuneWavePainter extends CustomPainter {
  final Color waveColor;

  const DuneWavePainter({
    this.waveColor = const Color(0x26FFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // First gentle dune curve
    final path1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.95,
        size.width * 0.65,
        size.height * 0.45,
        size.width,
        size.height * 0.65,
      );
    canvas.drawPath(path1, paint);

    // Second overlapping dune curve
    final paint2 = Paint()
      ..color = waveColor.withOpacity(waveColor.opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path2 = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.25,
        size.width * 0.70,
        size.height * 0.75,
        size.width,
        size.height * 0.30,
      );
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant DuneWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}
