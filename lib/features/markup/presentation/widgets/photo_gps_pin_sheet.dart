import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/utils/photo_compressor.dart';

class PhotoGpsPinResult {
  final String base64Image;
  final GpsCoord gps;
  final String caption;
  final String accuracy;
  final int compressedSize;

  const PhotoGpsPinResult({
    required this.base64Image,
    required this.gps,
    required this.caption,
    required this.accuracy,
    required this.compressedSize,
  });
}

class PhotoGpsPinSheet extends StatefulWidget {
  final bool isOutdoor;
  final bool isDark;

  const PhotoGpsPinSheet({
    super.key,
    required this.isOutdoor,
    required this.isDark,
  });

  static Future<PhotoGpsPinResult?> show(
    BuildContext context, {
    required bool isOutdoor,
    required bool isDark,
  }) {
    return showModalBottomSheet<PhotoGpsPinResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhotoGpsPinSheet(isOutdoor: isOutdoor, isDark: isDark),
    );
  }

  @override
  State<PhotoGpsPinSheet> createState() => _PhotoGpsPinSheetState();
}

class _PhotoGpsPinSheetState extends State<PhotoGpsPinSheet> {
  final TextEditingController _captionController = TextEditingController();
  Uint8List? _photoBytes;
  String? _compressedBase64;
  int _compressedBytesLength = 0;
  bool _isCompressing = false;

  // Desert GPS coordinates
  final GpsCoord _currentGps = const GpsCoord(lat: 24.713600, lng: 46.675300);
  final String _accuracy = '±2.8m';
  final String _elevation = '104.5m ASL';

  @override
  void initState() {
    super.initState();
    _captureMockPhoto();
  }

  Future<void> _captureMockPhoto() async {
    setState(() => _isCompressing = true);
    final mockBytes = PhotoCompressor.createMockFieldPhotoBytes();
    final res = await PhotoCompressor.compressPhoto(mockBytes, maxDimension: 1600, quality: 80);
    if (!mounted) return;
    setState(() {
      _photoBytes = res.bytes;
      _compressedBase64 = res.base64Data;
      _compressedBytesLength = res.compressedSize;
      _isCompressing = false;
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isOutdoor
        ? AppColors.outdoorSurface
        : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = widget.isOutdoor
        ? AppColors.outdoorText
        : (widget.isDark ? AppColors.darkText : AppColors.lightText);
    final outlineColor = widget.isOutdoor
        ? AppColors.outdoorOutline
        : (widget.isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final primaryColor = widget.isOutdoor
        ? AppColors.outdoorPrimary
        : (widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: outlineColor, width: widget.isOutdoor ? 1.5 : 1.0),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_camera_rounded, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Field Photo & GPS Pin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Photo Preview / Camera Capture Tile
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineColor, width: 1.0),
            ),
            child: _isCompressing
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Container(
                        width: 130,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                          image: _photoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_photoBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _photoBytes == null
                            ? const Center(child: Icon(Icons.camera_alt_rounded, color: Colors.white70, size: 36))
                            : null,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'JPEG max 1600px 80%',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Size: ${(_compressedBytesLength / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(fontSize: 11, color: textColor),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _captureMockPhoto,
                                child: Row(
                                  children: [
                                    Icon(Icons.refresh_rounded, size: 14, color: primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Retake Photo',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // GPS Coordinates Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LAT: ${_currentGps.lat.toStringAsFixed(6)}° N, LNG: ${_currentGps.lng.toStringAsFixed(6)}° E',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Accuracy: $_accuracy | Elev: $_elevation | Desert Field',
                        style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Caption Input
          TextField(
            controller: _captionController,
            style: TextStyle(color: textColor, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add note / weld inspection / flange condition...',
              hintStyle: TextStyle(color: textColor.withOpacity(0.4), fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final base64 = _compressedBase64 ?? base64Encode(PhotoCompressor.createMockFieldPhotoBytes());
              Navigator.of(context).pop(
                PhotoGpsPinResult(
                  base64Image: base64,
                  gps: _currentGps,
                  caption: _captionController.text.trim().isEmpty ? 'Field Inspection Photo' : _captionController.text.trim(),
                  accuracy: _accuracy,
                  compressedSize: _compressedBytesLength,
                ),
              );
            },
            child: const Text(
              'DROP PHOTO PIN (📍)',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
