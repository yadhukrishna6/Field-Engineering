import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/markup_editor_controller.dart';

class AddLabelSheet extends StatefulWidget {
  final Color initialColor;
  final String initialSize;
  final Function(String text, String size, Color color) onConfirm;

  const AddLabelSheet({
    super.key,
    required this.initialColor,
    this.initialSize = 'M',
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required Color initialColor,
    String initialSize = 'M',
    required Function(String text, String size, Color color) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddLabelSheet(
        initialColor: initialColor,
        initialSize: initialSize,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AddLabelSheet> createState() => _AddLabelSheetState();
}

class _AddLabelSheetState extends State<AddLabelSheet> {
  late TextEditingController _textController;
  late String _selectedSize;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _selectedSize = widget.initialSize;
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardPadding),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
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

                  const Row(
                    children: [
                      Icon(Icons.text_fields_rounded, color: AppColors.safetyOrange),
                      SizedBox(width: 8),
                      Text(
                        'Add Engineering Label',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Text Input Field
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    maxLines: 2,
                    style: AppTypography.engineeringTextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. 4"-HC-1002 Tie-in location',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Size Selector S / M / L
                  Row(
                    children: [
                      const Text('Size: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 12),
                      _buildSizeChip('S', 'Small (11pt)'),
                      const SizedBox(width: 8),
                      _buildSizeChip('M', 'Medium (14pt)'),
                      const SizedBox(width: 8),
                      _buildSizeChip('L', 'Large (18pt)'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Color Selector Dots
                  Row(
                    children: [
                      const Text('Color: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 12),
                      ...kMarkupColorPresets.map((color) {
                        final isSelected = _selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.black26,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fixed Font Uniformity Note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Drawing font is fixed to Engineering standard for review consistency.',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Done / Place Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safetyOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(context);
                        widget.onConfirm(text, _selectedSize, _selectedColor);
                      }
                    },
                    child: const Text('Place Text Label', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeChip(String sizeCode, String label) {
    final isSelected = _selectedSize == sizeCode;
    return ChoiceChip(
      label: Text(sizeCode, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.safetyOrange.withOpacity(0.2),
      onSelected: (selected) {
        if (selected) setState(() => _selectedSize = sizeCode);
      },
    );
  }
}
