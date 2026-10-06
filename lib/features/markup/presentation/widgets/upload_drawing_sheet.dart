import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadDrawingSheet extends StatelessWidget {
  final Function(String path, String name, String fileType, int pageCount) onDrawingSelected;

  const UploadDrawingSheet({
    super.key,
    required this.onDrawingSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String path, String name, String fileType, int pageCount) onDrawingSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UploadDrawingSheet(onDrawingSelected: onDrawingSelected),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final path = file.path ?? '';
      final name = file.name;
      final isPdf = name.toLowerCase().endsWith('.pdf');
      if (context.mounted) {
        Navigator.pop(context);
        onDrawingSelected(path, name, isPdf ? 'PDF' : 'IMAGE', 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload Engineering Drawing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a PDF blueprint or site photo to annotate',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            _buildOption(
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.redAccent,
              title: 'PDF Blueprint Document',
              subtitle: 'Multi-page engineering layout or P&ID schematic',
              onTap: () => _pickFile(context),
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.photo_library_rounded,
              color: Colors.cyanAccent,
              title: 'Photo Library',
              subtitle: 'Pick high-resolution site photo from gallery',
              onTap: () => _pickFile(context),
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.camera_alt_rounded,
              color: Colors.amberAccent,
              title: 'Take Site Photo (Camera)',
              subtitle: 'Capture field piping or technical layout directly on site',
              onTap: () => _pickFile(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
