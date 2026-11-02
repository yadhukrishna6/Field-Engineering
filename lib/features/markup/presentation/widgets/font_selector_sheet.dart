import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Sheet for selecting from downloaded engineering and handwriting fonts,
/// plus text alignment (left, center, right).
class FontSelectorSheet extends StatelessWidget {
  final String activeFontId;
  final String activeAlignment;
  final bool isDark;
  final bool isOutdoor;
  final ValueChanged<String> onSelectFont;
  final ValueChanged<String> onSelectAlignment;

  const FontSelectorSheet({
    super.key,
    required this.activeFontId,
    required this.activeAlignment,
    required this.isDark,
    required this.isOutdoor,
    required this.onSelectFont,
    required this.onSelectAlignment,
  });

  static Future<void> show(
    BuildContext context, {
    required String activeFontId,
    required String activeAlignment,
    required bool isDark,
    required bool isOutdoor,
    required ValueChanged<String> onSelectFont,
    required ValueChanged<String> onSelectAlignment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FontSelectorSheet(
        activeFontId: activeFontId,
        activeAlignment: activeAlignment,
        isDark: isDark,
        isOutdoor: isOutdoor,
        onSelectFont: onSelectFont,
        onSelectAlignment: onSelectAlignment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isOutdoor
        ? AppColors.outdoorSurface
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final outlineColor = isOutdoor
        ? AppColors.outdoorOutline
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final textColor = isOutdoor
        ? AppColors.outdoorText
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final secondaryTextColor = isOutdoor
        ? AppColors.outdoorSecondaryText
        : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  // Drag Handle
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
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.font_download_rounded, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Downloaded Engineering Fonts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Aligned handwriting & CAD typography for drawing lettering',
                              style: TextStyle(fontSize: 12, color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alignment Selector Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: outlineColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Text Alignment:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAlignButton(
                              icon: Icons.format_align_left_rounded,
                              label: 'Left',
                              value: 'left',
                              primaryColor: primaryColor,
                              textColor: textColor,
                            ),
                            const SizedBox(width: 6),
                            _buildAlignButton(
                              icon: Icons.format_align_center_rounded,
                              label: 'Center',
                              value: 'center',
                              primaryColor: primaryColor,
                              textColor: textColor,
                            ),
                            const SizedBox(width: 6),
                            _buildAlignButton(
                              icon: Icons.format_align_right_rounded,
                              label: 'Right',
                              value: 'right',
                              primaryColor: primaryColor,
                              textColor: textColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'SELECT FONT STYLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List of 6 Downloaded Engineering Fonts
                  ...EngineeringFont.values.map((font) {
                    final isSelected = activeFontId == font.id;
                    final previewStyle = AppTypography.getTextStyle(
                      font: font,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : textColor,
                    );

                    return InkWell(
                      onTap: () {
                        onSelectFont(font.id);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor.withOpacity(0.10) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? primaryColor : outlineColor,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Selection Indicator
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? primaryColor : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? primaryColor : outlineColor,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 14),

                            // Font Info & Live Preview
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        font.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: textColor,
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    font.subtitle,
                                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                                  ),
                                  const SizedBox(height: 6),

                                  // Live Rendered Sample with Blueprint Code (e.g. SL6)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF0F4F8),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: outlineColor.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_note_rounded, size: 14, color: primaryColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          font.samplePreview,
                                          style: previewStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlignButton({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    required Color textColor,
  }) {
    final isSelected = activeAlignment == value;
    return InkWell(
      onTap: () => onSelectAlignment(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? primaryColor : textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
