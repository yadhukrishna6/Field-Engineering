import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';

class ThemeSelectorModal extends ConsumerWidget {
  const ThemeSelectorModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ThemeSelectorModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    final isOutdoor = themeState.isOutdoorActive;
    final isDark = themeState.isDarkActive;

    final surfaceColor = isOutdoor
        ? AppColors.outdoorSurface
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = isOutdoor
        ? AppColors.outdoorText
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final secondaryTextColor = isOutdoor
        ? AppColors.outdoorSecondaryText
        : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final outlineColor = isOutdoor
        ? AppColors.outdoorOutline
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);

    final options = [
      {
        'mode': AppThemeMode.auto,
        'title': 'Auto (Ambient Light)',
        'subtitle': 'Switches to Outdoor in direct sunlight (>25,000 lux)',
        'icon': Icons.brightness_auto_rounded,
        'tag': 'Smart',
      },
      {
        'mode': AppThemeMode.standard,
        'title': 'Standard (Desert Light)',
        'subtitle': 'Warm terracotta theme for office and shade',
        'icon': Icons.light_mode_rounded,
        'tag': 'Standard',
      },
      {
        'mode': AppThemeMode.outdoor,
        'title': 'Outdoor (Direct Sunlight)',
        'subtitle': 'High contrast WCAG AAA (18.6:1), 48dp touch targets',
        'icon': Icons.wb_sunny_rounded,
        'tag': 'WCAG AAA',
      },
      {
        'mode': AppThemeMode.dark,
        'title': 'Dark (Desert Dark)',
        'subtitle': 'Low glare warm dark mode for evening and low light',
        'icon': Icons.dark_mode_rounded,
        'tag': 'Dark',
      },
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: outlineColor, width: isOutdoor ? 1.5 : 1.0),
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
                        color: secondaryTextColor.withOpacity(0.4),
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
                          Icon(Icons.palette_outlined, color: primaryColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Display Theme',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isOutdoor ? 18 : 16,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOutdoor ? AppColors.outdoorChip : AppColors.lightChip,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: outlineColor),
                        ),
                        child: Text(
                          themeState.activeTheme.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Options list
                  ...options.map((opt) {
                    final mode = opt['mode'] as AppThemeMode;
                    final isSelected = themeState.themeMode == mode;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          controller.setThemeMode(mode);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryColor : outlineColor,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : outlineColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  opt['icon'] as IconData,
                                  color: isSelected ? Colors.white : textColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          opt['title'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isOutdoor ? 15 : 13,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isSelected ? primaryColor.withOpacity(0.2) : outlineColor.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            opt['tag'] as String,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? primaryColor : secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt['subtitle'] as String,
                                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: primaryColor, size: 22)
                              else
                                Icon(Icons.circle_outlined, color: outlineColor, size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Ambient Sensor Sunlight Simulation (When Auto mode is selected)
                  if (themeState.themeMode == AppThemeMode.auto) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOutdoor ? AppColors.outdoorChip : AppColors.lightChip,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: outlineColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sensors_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ambient Light Sensor (Auto)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                                ),
                                Text(
                                  themeState.isDirectSunlightDetected || themeState.manualOutdoorOverride
                                      ? 'Sunlight detected (> 25,000 lux) & Outdoor active'
                                      : 'Indoor ambient lighting & Standard active',
                                  style: TextStyle(fontSize: 10, color: secondaryTextColor),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: themeState.isDirectSunlightDetected || themeState.manualOutdoorOverride,
                            activeColor: primaryColor,
                            onChanged: (val) {
                              controller.setManualOutdoorOverride(val);
                            },
                          ),
                        ],
                      ),
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
}
