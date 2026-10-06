import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Professional Engineering Text Callout Dialog
/// Strictly applies uniform engineering font and CAD standard callout formatting.
class TextAnnotationDialog extends StatefulWidget {
  final String? initialText;
  final double initialFontSize;
  final double initialRotation;
  final Color initialColor;
  final bool initialWithLeader;
  final void Function(
    String text,
    double fontSize,
    double rotation,
    bool withLeader,
  ) onConfirm;

  const TextAnnotationDialog({
    super.key,
    this.initialText,
    this.initialFontSize = 13.0,
    this.initialRotation = 0.0,
    this.initialColor = AppColors.safetyOrange,
    this.initialWithLeader = false,
    required this.onConfirm,
  });

  @override
  State<TextAnnotationDialog> createState() => _TextAnnotationDialogState();
}

class _TextAnnotationDialogState extends State<TextAnnotationDialog> {
  late TextEditingController _textController;
  late double _fontSize;
  late double _rotationDegrees;
  late bool _withLeader;

  static const List<String> _engineeringPresets = [
    'VERIFY IN FIELD (VIF)',
    'HOLD FOR RFI',
    'AS-BUILT ROUTING',
    'TIE-IN POINT #',
    'VALVE TAG: ',
    'RELOCATE INSTRUMENT',
    'QA/QC INSPECT WELD',
    'ADD THERMAL INSULATION',
    'FIELD REVISION REV-',
  ];

  static const List<double> _presetRotations = [0.0, 30.0, 60.0, 90.0, 180.0, 270.0];
  static const List<double> _presetFontSizes = [11.0, 13.0, 16.0, 20.0, 24.0];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _fontSize = widget.initialFontSize;
    _rotationDegrees = widget.initialRotation * 180.0 / 3.141592653589793;
    _withLeader = widget.initialWithLeader;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.initialColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.text_fields_rounded, color: widget.initialColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Engineering Note / Callout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Standard Uniform CAD Font (DIN / ISOCPEUR Standard)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Preset Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _engineeringPresets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        preset,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      onPressed: () {
                        setState(() {
                          _textController.text = preset;
                          _textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length),
                          );
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Text Input Field
            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: 3,
              style: AppTypography.engineeringTextStyle(
                fontSize: _fontSize,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Enter technical note, tag number or revision note...',
                hintStyle: AppTypography.engineeringTextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.initialColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.initialColor, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Font Size & Rotation Controls Row
            Row(
              children: [
                // Font Size Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FONT SIZE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: _presetFontSizes.map((size) {
                          final isSelected = _fontSize == size;
                          return ChoiceChip(
                            label: Text('${size.toInt()}pt', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                            selected: isSelected,
                            selectedColor: widget.initialColor,
                            onSelected: (selected) {
                              if (selected) setState(() => _fontSize = size);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Rotation Angle Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROTATION SNAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: _presetRotations.map((deg) {
                          final isSelected = (_rotationDegrees - deg).abs() < 1.0;
                          return ChoiceChip(
                            label: Text('${deg.toInt()}°', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                            selected: isSelected,
                            selectedColor: widget.initialColor,
                            onSelected: (selected) {
                              if (selected) setState(() => _rotationDegrees = deg);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Leader Line Arrow Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Attach Leader Arrow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Adds a CAD pointing leader line from text to component', style: TextStyle(fontSize: 11, color: Colors.grey)),
              value: _withLeader,
              activeColor: widget.initialColor,
              onChanged: (val) => setState(() => _withLeader = val),
            ),
            const SizedBox(height: 16),

            // Live Preview Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('PREVIEW: ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: widget.initialColor, width: 1.2),
                      ),
                      child: Text(
                        _textController.text.isEmpty ? 'NOTE PREVIEW' : _textController.text,
                        style: AppTypography.engineeringTextStyle(
                          fontSize: _fontSize,
                          color: widget.initialColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Place Callout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.initialColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (_textController.text.trim().isEmpty) return;
                    final radians = _rotationDegrees * 3.141592653589793 / 180.0;
                    widget.onConfirm(
                      _textController.text.trim(),
                      _fontSize,
                      radians,
                      _withLeader,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
