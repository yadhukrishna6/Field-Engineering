import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WipeLockOverlay extends StatelessWidget {
  final bool isAutoLocked;
  final bool isOutdoor;
  final bool isDark;
  final VoidCallback onUnlock;

  const WipeLockOverlay({
    super.key,
    required this.isAutoLocked,
    required this.isOutdoor,
    required this.isDark,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final surfaceColor = isOutdoor
        ? AppColors.outdoorSurface
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = isOutdoor
        ? AppColors.outdoorText
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final outlineColor = isOutdoor
        ? AppColors.outdoorOutline
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);

    return Container(
      color: Colors.black.withOpacity(0.25),
      alignment: Alignment.center,
      child: Card(
        elevation: 12,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outlineColor, width: isOutdoor ? 2.0 : 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2.0),
                ),
                child: Icon(Icons.lock_rounded, size: 30, color: primaryColor),
              ),
              const SizedBox(height: 12),
              Text(
                isAutoLocked ? 'Palm / Cloth Contact Detected' : 'Wipe Lock Active',
                style: TextStyle(
                  fontSize: isOutdoor ? 17 : 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Canvas and zoom/pan are frozen.\nWipe dust off the screen safely without stray strokes.',
                style: TextStyle(
                  fontSize: isOutdoor ? 13 : 12,
                  color: textColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open_rounded, size: 24),
                label: const Text(
                  'Tap to Unlock Canvas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onUnlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
