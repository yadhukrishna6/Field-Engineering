import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/drawing_text_token.dart';
import '../../domain/utils/title_block_extractor.dart';

class UploadDrawingSheet extends StatefulWidget {
  final Function(
    String path,
    String name,
    String fileType,
    int pageCount,
    String? jobNumber,
    String? drawingNumber,
    String? revision,
    String? projectName,
    String? title,
    List<DrawingTextToken> tokens,
    Uint8List? fileBytes,
  ) onDrawingSelected;

  const UploadDrawingSheet({
    super.key,
    required this.onDrawingSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(
      String path,
      String name,
      String fileType,
      int pageCount,
      String? jobNumber,
      String? drawingNumber,
      String? revision,
      String? projectName,
      String? title,
      List<DrawingTextToken> tokens,
      Uint8List? fileBytes,
    ) onDrawingSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UploadDrawingSheet(onDrawingSelected: onDrawingSelected),
    );
  }

  @override
  State<UploadDrawingSheet> createState() => _UploadDrawingSheetState();
}

class _UploadDrawingSheetState extends State<UploadDrawingSheet> {
    String? _selectedPath;
  String? _selectedName;
  Uint8List? _selectedBytes;
  String _fileType = 'PDF';
  bool _isAnalyzing = false;
  final int _pageCount = 1;

  final TextEditingController _jobCtrl = TextEditingController();
  final TextEditingController _dwgCtrl = TextEditingController();
  final TextEditingController _revCtrl = TextEditingController();
  final TextEditingController _projectCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();
  List<DrawingTextToken> _extractedTokens = [];

  @override
  void dispose() {
    _jobCtrl.dispose();
    _dwgCtrl.dispose();
    _revCtrl.dispose();
    _projectCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
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

      setState(() {
        _isAnalyzing = true;
        _selectedPath = path;
        _selectedName = name;
        _selectedBytes = file.bytes;
        _fileType = isPdf ? 'PDF' : 'IMAGE';
      });

      // Title-Block reading (Never blocks upload on error)
      final tb = await TitleBlockExtractor.extractTitleBlock(
        filePath: path,
        fileName: name,
        isPdf: isPdf,
        bytes: file.bytes,
      );

      setState(() {
        _isAnalyzing = false;
        _jobCtrl.text = tb.jobNumber;
        _dwgCtrl.text = tb.drawingNumber;
        _revCtrl.text = tb.revision;
        _projectCtrl.text = tb.projectName;
        _titleCtrl.text = tb.title;
        _extractedTokens = tb.tokens;
      });
    }
  }

  void _confirmSave() {
    if (_selectedPath != null && _selectedName != null) {
      widget.onDrawingSelected(
        _selectedPath!,
        _selectedName!,
        _fileType,
        _pageCount,
        _jobCtrl.text.trim(),
        _dwgCtrl.text.trim(),
        _revCtrl.text.trim(),
        _projectCtrl.text.trim(),
        _titleCtrl.text.trim(),
        _extractedTokens,
        _selectedBytes,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: outlineColor),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.upload_file_rounded, color: primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Upload Drawing & Title-Block',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isAnalyzing) const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),

                  if (_selectedPath == null) ...[
                    Text(
                      'Select an isometric piping PDF or site layout to automatically extract title-block metadata.',
                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 16),
                    _buildOption(
                      icon: Icons.picture_as_pdf_rounded,
                      color: Colors.redAccent,
                      title: 'PDF Blueprint Document',
                      subtitle: 'Multi-page engineering layout or P&ID schematic',
                      onTap: () => _pickFile(context),
                    ),
                    const SizedBox(height: 10),
                    _buildOption(
                      icon: Icons.photo_library_rounded,
                      color: Colors.cyanAccent,
                      title: 'Photo Library',
                      subtitle: 'Pick high-resolution site photo from gallery',
                      onTap: () => _pickFile(context),
                    ),
                    const SizedBox(height: 10),
                    _buildOption(
                      icon: Icons.camera_alt_rounded,
                      color: Colors.amberAccent,
                      title: 'Take Site Photo (Camera)',
                      subtitle: 'Capture field piping or technical layout directly on site',
                      onTap: () => _pickFile(context),
                    ),
                  ] else ...[
                    // Title-block prefill card (Phase C)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkChip : AppColors.lightChip,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: outlineColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: Colors.green, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'TITLE-BLOCK EXTRACTED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: primaryColor,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _pickFile(context),
                                child: const Text('Change File', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildField('Drawing No.', _dwgCtrl),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildField('Rev.', _revCtrl),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildField('Job / Project No.', _jobCtrl),
                          const SizedBox(height: 8),
                          _buildField('Project Name', _projectCtrl),
                          const SizedBox(height: 8),
                          _buildField('Drawing Title', _titleCtrl),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save & Open in Markup Editor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _confirmSave,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
