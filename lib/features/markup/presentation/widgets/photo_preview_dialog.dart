import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';

class PhotoPreviewDialog extends StatelessWidget {
  final AnnotationItem annotation;
  final bool isOutdoor;
  final bool isDark;
  final bool canDelete;
  final VoidCallback? onDelete;

  const PhotoPreviewDialog({
    super.key,
    required this.annotation,
    required this.isOutdoor,
    required this.isDark,
    this.canDelete = true,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required AnnotationItem annotation,
    required bool isOutdoor,
    required bool isDark,
    bool canDelete = true,
    VoidCallback? onDelete,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PhotoPreviewDialog(
        annotation: annotation,
        isOutdoor: isOutdoor,
        isDark: isDark,
        canDelete: canDelete,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isOutdoor
        ? AppColors.outdoorSurface
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = isOutdoor
        ? AppColors.outdoorText
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final outlineColor = isOutdoor
        ? AppColors.outdoorOutline
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    Uint8List? imageBytes;
    if (annotation.photoIds != null && annotation.photoIds!.isNotEmpty) {
      try {
        final raw = annotation.photoIds!.first;
        if (raw.startsWith('data:image')) {
          final b64 = raw.split(',').last;
          imageBytes = base64Decode(b64);
        } else {
          imageBytes = base64Decode(raw);
        }
      } catch (_) {}
    }

    final gps = annotation.gps;
    final caption = annotation.text ?? annotation.metadata?['caption'] ?? 'Field Photo Pin';
    final author = annotation.author ?? 'Field Engineer';
    final accuracy = annotation.metadata?['accuracy'] ?? '±3.0m';
    final dateStr = annotation.createdAt.toLocal().toString().substring(0, 16);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outlineColor, width: isOutdoor ? 1.5 : 1.0),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_camera_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Photo Inspection Pin',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Image Container
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: outlineColor),
                image: imageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(imageBytes),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: imageBytes == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
                          SizedBox(height: 6),
                          Text('Field Photo (JPEG Compressed)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Caption
            Text(
              caption,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),

            // GPS Info Card
            if (gps != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${gps.lat.toStringAsFixed(6)}° N, ${gps.lng.toStringAsFixed(6)}° E ($accuracy)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy GPS',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '${gps.lat}, ${gps.lng}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GPS coordinates copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // Audit metadata
            Text(
              'Author: $author | Date: $dateStr',
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canDelete && onDelete != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Pin'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete?.call();
                    },
                  ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}
