import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_image.dart';

class PhotoViewerScreen extends ConsumerStatefulWidget {
  final String? photoId;

  const PhotoViewerScreen({super.key, this.photoId});

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  int _selectedPhotoIndex = 0;

  final List<Map<String, dynamic>> _photos = [
    {
      'name': 'IMG_20260930_104523.jpg',
      'date': '30 Sep 2026 10:45',
      'drawing': 'Daleel Oil Field - P-102',
      'gps': '24.4532, 54.3771',
      'asset': 'assets/images/piping_photo_1.jpg',
    },
    {
      'name': 'IMG_20260930_104612.jpg',
      'date': '30 Sep 2026 10:46',
      'drawing': 'Daleel Oil Field - P-102',
      'gps': '24.4532, 54.3771',
      'asset': 'assets/images/piping_photo_2.jpg',
    },
    {
      'name': 'IMG_20260930_104745.jpg',
      'date': '30 Sep 2026 10:47',
      'drawing': 'Daleel Oil Field - P-102',
      'gps': '24.4535, 54.3775',
      'asset': 'assets/images/piping_photo_3.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final photo = _photos[_selectedPhotoIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/issues');
            }
          },
        ),
        title: Text(
          photo['name'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Annotate Photo',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo annotation editor activated')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete Photo',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo removed from field bundle')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Center Photo Canvas with Interactive Zoom & Pan
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: AppImage(
                imageSource: photo['asset'] as String,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Bottom Info & Thumbnails Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Overlay Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  photo['date'] as String,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              photo['drawing'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.cyanAccent),
                                const SizedBox(width: 4),
                                Text(
                                  photo['gps'] as String,
                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Open in Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('GPS Coordinates: ${photo['gps']}')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Thumbnails Carousel Strip
                Container(
                  height: 64,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      ..._photos.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final isSelected = _selectedPhotoIndex == idx;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedPhotoIndex = idx),
                          child: Container(
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: AppImage(
                                imageSource: entry.value['asset'] as String,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 20),
                          tooltip: 'Attach New Field Photo',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Camera capture initiated for tablet')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
