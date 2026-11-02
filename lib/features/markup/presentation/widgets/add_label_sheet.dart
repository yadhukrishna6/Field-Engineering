import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AddLabelSheet extends StatefulWidget {
  final Color initialColor;
  final String initialSize;
  final String initialFontFamily;
  final String initialAlignment;
  final String? initialText;
  final Function(String text, String size, Color color, String fontFamily, String alignment) onConfirm;

  const AddLabelSheet({
    super.key,
    required this.initialColor,
    this.initialSize = 'M',
    this.initialFontFamily = 'architectural',
    this.initialAlignment = 'left',
    this.initialText,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required Color initialColor,
    String initialSize = 'M',
    String initialFontFamily = 'architectural',
    String initialAlignment = 'left',
    String? initialText,
    required Function(String text, String size, Color color, String fontFamily, String alignment) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddLabelSheet(
        initialColor: initialColor,
        initialSize: initialSize,
        initialFontFamily: initialFontFamily,
        initialAlignment: initialAlignment,
        initialText: initialText,
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
  late String _selectedFontFamily;
  late String _selectedAlignment;

  // Common quick symbols & engineering codes
  static const List<String> _quickSymbols = [
    'SL6',
    'Ø',
    '±',
    'CL',
    'EL',
    'TYP',
    'NTS',
    'HOLD',
    '4"-HC-1002',
    'REV-A',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _selectedSize = widget.initialSize;
    _selectedColor = widget.initialColor;
    _selectedFontFamily = widget.initialFontFamily;
    _selectedAlignment = widget.initialAlignment;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  double _getFontSize(String sizeCode) {
    switch (sizeCode) {
      case 'S':
        return AppTypography.fontSizeSmall;
      case 'L':
        return AppTypography.fontSizeLarge;
      case 'M':
      default:
        return AppTypography.fontSizeMedium + 1.0;
    }
  }

  void _insertSymbol(String symbol) {
    final current = _textController.text;
    final selection = _textController.selection;
    if (selection.isValid && selection.start >= 0) {
      final newText = current.replaceRange(selection.start, selection.end, symbol);
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + symbol.length),
      );
    } else {
      _textController.text = current.isEmpty ? symbol : '$current $symbol';
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final currentFont = EngineeringFont.fromId(_selectedFontFamily);
    final previewStyle = AppTypography.getTextStyle(
      font: currentFont,
      fontSize: _getFontSize(_selectedSize),
      fontWeight: FontWeight.bold,
      color: _selectedColor,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + keyboardPadding),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: secondaryTextColor.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.draw_rounded, color: primaryColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Engineering Pen & Text Lettering',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: secondaryTextColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Text Input Field
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    maxLines: 2,
                    style: previewStyle.copyWith(color: textColor),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'e.g. SL6 • 4"-HC-1002 Tie-in location',
                      hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: outlineColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Symbols Chips (SL6, Ø, ±, etc.)
                  Row(
                    children: [
                      Text(
                        'Quick Codes:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryTextColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _quickSymbols.map((sym) {
                              final isSL6 = sym == 'SL6';
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text(
                                    sym,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSL6 ? FontWeight.w900 : FontWeight.bold,
                                      color: isSL6 ? primaryColor : textColor,
                                    ),
                                  ),
                                  backgroundColor: isSL6
                                      ? primaryColor.withOpacity(0.15)
                                      : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
                                  side: BorderSide(
                                    color: isSL6 ? primaryColor : outlineColor,
                                    width: isSL6 ? 1.5 : 1.0,
                                  ),
                                  onPressed: () => _insertSymbol(sym),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Downloaded Font Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Font Style (Downloaded):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                      ),
                      Text(
                        currentFont.displayName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: EngineeringFont.values.map((font) {
                        final isSelected = _selectedFontFamily == font.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              font.displayName,
                              style: AppTypography.getTextStyle(
                                font: font,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : textColor,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                            side: BorderSide(color: isSelected ? primaryColor : outlineColor),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedFontFamily = font.id);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alignment & Size Controls in a Row
                  Row(
                    children: [
                      // Alignment
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alignment:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildAlignChip('left', Icons.format_align_left_rounded, primaryColor, outlineColor),
                                const SizedBox(width: 4),
                                _buildAlignChip('center', Icons.format_align_center_rounded, primaryColor, outlineColor),
                                const SizedBox(width: 4),
                                _buildAlignChip('right', Icons.format_align_right_rounded, primaryColor, outlineColor),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Size Selector (S, M, L)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Text Size:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildSizeChip('S', '11pt', primaryColor),
                              const SizedBox(width: 4),
                              _buildSizeChip('M', '14pt', primaryColor),
                              const SizedBox(width: 4),
                              _buildSizeChip('L', '18pt', primaryColor),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Color Dots
                  Row(
                    children: [
                      Text('Color: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
                      const SizedBox(width: 8),
                      ...kMarkupColorPresets.map((color) {
                        final isSelected = _selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : outlineColor,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)]
                                  : null,
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

                  // Live Blueprint Preview (Transparent Background with Drafting Guide)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: outlineColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Blueprint Canvas Preview (Transparent BG):',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryTextColor),
                            ),
                            Text(
                              'Aligned: ${_selectedAlignment.toUpperCase()}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Stack(
                            children: [
                              // Drafting Baseline Guide
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 2,
                                child: Container(
                                  height: 1,
                                  color: _selectedColor.withOpacity(0.4),
                                ),
                              ),
                              // Rendered Text
                              Align(
                                alignment: _selectedAlignment == 'center'
                                    ? Alignment.center
                                    : (_selectedAlignment == 'right' ? Alignment.centerRight : Alignment.centerLeft),
                                child: Text(
                                  _textController.text.trim().isEmpty ? 'SL6 • Sample Lettering' : _textController.text,
                                  style: previewStyle,
                                  textAlign: _selectedAlignment == 'center'
                                      ? TextAlign.center
                                      : (_selectedAlignment == 'right' ? TextAlign.right : TextAlign.left),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Place Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(context);
                        widget.onConfirm(
                          text,
                          _selectedSize,
                          _selectedColor,
                          _selectedFontFamily,
                          _selectedAlignment,
                        );
                      }
                    },
                    child: Text(
                      'Place Aligned Lettering (${currentFont.displayName})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlignChip(String alignValue, IconData icon, Color primaryColor, Color outlineColor) {
    final isSelected = _selectedAlignment == alignValue;
    return InkWell(
      onTap: () => setState(() => _selectedAlignment = alignValue),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? primaryColor : outlineColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Icon(icon, size: 18, color: isSelected ? primaryColor : outlineColor),
      ),
    );
  }

  Widget _buildSizeChip(String sizeCode, String sublabel, Color primaryColor) {
    final isSelected = _selectedSize == sizeCode;
    return ChoiceChip(
      label: Text(sizeCode, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: primaryColor.withOpacity(0.2),
      onSelected: (selected) {
        if (selected) setState(() => _selectedSize = sizeCode);
      },
    );
  }
}
