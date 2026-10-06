import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DashedUploadCard extends StatelessWidget {
  final VoidCallback onTap;

  const DashedUploadCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedRectPainter(color: outlineColor),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_outlined, color: primaryColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload drawing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                'PDF, PNG or JPG',
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onTap,
                child: const Text('Choose file', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;

  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.2;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = 12.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length) ? dashWidth : metric.length - distance;
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
