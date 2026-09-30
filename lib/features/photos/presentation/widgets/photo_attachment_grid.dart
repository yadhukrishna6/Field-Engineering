import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/services/field_gps_service.dart';
import '../../domain/models/photo_attachment.dart';
import 'photo_viewer_dialog.dart';

class PhotoAttachmentGrid extends StatefulWidget {
  final List<PhotoAttachment> photos;
  final Function(PhotoAttachment photo)? onPhotoAdded;
  final Function(String photoId)? onPhotoDeleted;
  final String? issueId;
  final String? inspectionId;
  final String? equipmentId;
  final String? drawingId;
  final int pageNumber;
  final bool readOnly;

  const PhotoAttachmentGrid({
    super.key,
    required this.photos,
    this.onPhotoAdded,
    this.onPhotoDeleted,
    this.issueId,
    this.inspectionId,
    this.equipmentId,
    this.drawingId,
    this.pageNumber = 1,
    this.readOnly = false,
  });

  @override
  State<PhotoAttachmentGrid> createState() => _PhotoAttachmentGridState();
}

class _PhotoAttachmentGridState extends State<PhotoAttachmentGrid> {
  final _uuid = const Uuid();
  bool _isAttaching = false;

  Future<void> _pickPhoto() async {
    setState(() => _isAttaching = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;

        // Capture current offline GPS coordinates
        final gps = await FieldGpsService.instance.getCurrentPosition();

        final attachment = PhotoAttachment(
          id: _uuid.v4(),
          filePath: filePath,
          title: fileName,
          caption: 'Field photo captured at ${DateFormat('HH:mm:ss').format(DateTime.now())}',
          latitude: gps.latitude,
          longitude: gps.longitude,
          gpsAccuracy: gps.accuracy,
          gpsTimestamp: gps.timestamp,
          issueId: widget.issueId,
          inspectionId: widget.inspectionId,
          equipmentId: widget.equipmentId,
          drawingId: widget.drawingId,
          pageNumber: widget.pageNumber,
          fileSize: fileSize,
          createdAt: DateTime.now(),
        );

        if (widget.onPhotoAdded != null) {
          widget.onPhotoAdded!(attachment);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAttaching = false);
    }
  }

  void _openViewer(PhotoAttachment photo) {
    showDialog(
      context: context,
      builder: (ctx) => PhotoViewerDialog(
        photo: photo,
        onDelete: widget.readOnly ? null : () {
          if (widget.onPhotoDeleted != null) {
            widget.onPhotoDeleted!(photo.id);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.safetyOrange),
            const SizedBox(width: 8),
            Text(
              'Photo Attachments (${widget.photos.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Spacer(),
            if (!widget.readOnly)
              TextButton.icon(
                onPressed: _isAttaching ? null : _pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: const Text('Add Photo', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.photos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.camera_alt_outlined, size: 32, color: isDark ? Colors.white38 : Colors.black38),
                  const SizedBox(height: 6),
                  Text(
                    'No photos attached. Attach site photos with offline GPS tags.',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length + (!widget.readOnly ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (!widget.readOnly && index == widget.photos.length) {
                  return InkWell(
                    onTap: _pickPhoto,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: AppColors.safetyOrange),
                          SizedBox(height: 4),
                          Text('Add More', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }

                final photo = widget.photos[index];
                return GestureDetector(
                  onTap: () => _openViewer(photo),
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildPhotoThumbnail(photo),
                      ),
                      // GPS Pill Overlay
                      if (photo.latitude != null)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_fixed, size: 9, color: Colors.greenAccent),
                                SizedBox(width: 3),
                                Text(
                                  'GPS TAGGED',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Delete button
                      if (!widget.readOnly)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              if (widget.onPhotoDeleted != null) {
                                widget.onPhotoDeleted!(photo.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(PhotoAttachment photo) {
    if (!kIsWeb && File(photo.filePath).existsSync()) {
      return Image.file(
        File(photo.filePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(photo),
      );
    }
    return _buildPlaceholder(photo);
  }

  Widget _buildPlaceholder(PhotoAttachment photo) {
    return Container(
      color: Colors.blueGrey.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo, color: Colors.white70, size: 28),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                photo.title ?? 'Photo',
                style: const TextStyle(color: Colors.white, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
