import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../domain/models/drawing_file.dart';
import '../controllers/drawings_list_controller.dart';
import '../widgets/dune_wave_painter.dart';
import '../widgets/theme_selector_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drawingsListControllerProvider);
    final themeState = ref.watch(themeControllerProvider);

    final isOutdoor = themeState.isOutdoorActive;
    final isDark = themeState.isDarkActive;

    final backgroundColor = isOutdoor
        ? AppColors.outdoorBackground
        : (isDark ? AppColors.darkBackground : AppColors.lightBackground);
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

    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Drawing markup'),
        actions: [
          IconButton(
            icon: Icon(
              themeState.themeMode == AppThemeMode.auto
                  ? Icons.brightness_auto_rounded
                  : (isOutdoor
                      ? Icons.wb_sunny_rounded
                      : (isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded)),
            ),
            tooltip: 'Theme: ${themeState.themeMode.label}',
            onPressed: () => ThemeSelectorModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh drawings',
            onPressed: () => ref.read(drawingsListControllerProvider.notifier).loadDrawings(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle Date
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: isOutdoor ? 14 : 13,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Large "Drawings" Hero Card
                  _buildHeroCard(context, state, isOutdoor, isDark, primaryColor),
                  const SizedBox(height: 28),

                  // "Recent" Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent',
                        style: TextStyle(
                          fontSize: isOutdoor ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (state.drawings.isNotEmpty)
                        TextButton(
                          onPressed: () => context.push('/drawings'),
                          child: Text(
                            'View all',
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: isOutdoor ? 14 : 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Recent 2 items list
                  if (state.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.drawings.isEmpty)
                    _buildEmptyRecent(context, surfaceColor, outlineColor, textColor, secondaryTextColor, primaryColor)
                  else
                    ...state.recentDrawings.map((drawing) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildRecentCard(context, drawing, surfaceColor, outlineColor, textColor, secondaryTextColor, isOutdoor, isDark),
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

  Widget _buildHeroCard(
    BuildContext context,
    DrawingsListState state,
    bool isOutdoor,
    bool isDark,
    Color primaryColor,
  ) {
    final totalFiles = state.totalFilesCount;
    final withMarkup = state.filesWithMarkupCount;
    final countSubtitle = '$totalFiles ${totalFiles == 1 ? "file" : "files"}, $withMarkup with markup';

    final heroColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? const Color(0xFF9E4B28) : AppColors.lightPrimary);

    return Container(
      decoration: BoxDecoration(
        color: heroColor,
        borderRadius: BorderRadius.circular(16),
        border: isOutdoor ? Border.all(color: AppColors.outdoorOutline, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black38 : heroColor.withOpacity(0.2)),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/drawings'),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Subtle Dune-Wave Shapes in Background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const CustomPaint(
                    painter: DuneWavePainter(waveColor: Color(0x33FFFFFF)),
                  ),
                ),
              ),

              // Hero Card Content
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.architecture_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Drawings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            countSubtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecent(
    BuildContext context,
    Color surfaceColor,
    Color outlineColor,
    Color textColor,
    Color secondaryTextColor,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor, width: 1.0),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, size: 36, color: secondaryTextColor),
            const SizedBox(height: 10),
            Text(
              'No drawings uploaded yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap Drawings above to add your first technical sheet',
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(
    BuildContext context,
    DrawingFile drawing,
    Color surfaceColor,
    Color outlineColor,
    Color textColor,
    Color secondaryTextColor,
    bool isOutdoor,
    bool isDark,
  ) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(drawing.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor, width: isOutdoor ? 1.5 : 1.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () => context.push('/drawings/${drawing.id}', extra: drawing),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: drawing.isPdf
                ? Colors.redAccent.withOpacity(0.12)
                : Colors.blueAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            drawing.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
            color: drawing.isPdf ? (isOutdoor ? AppColors.outdoorInkRed : Colors.redAccent) : Colors.blueAccent,
            size: 22,
          ),
        ),
        title: Text(
          drawing.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isOutdoor ? 15 : 14, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${drawing.fileType.toUpperCase()} • $formattedDate',
          style: TextStyle(fontSize: isOutdoor ? 13 : 12, color: secondaryTextColor),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
