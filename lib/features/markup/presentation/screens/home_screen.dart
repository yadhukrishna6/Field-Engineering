import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../domain/models/drawing_file.dart';
import '../controllers/drawings_list_controller.dart';
import '../widgets/dune_wave_painter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(drawingsListControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing markup'),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : (themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.brightness_auto_rounded),
            ),
            tooltip: 'Toggle theme mode (${themeMode.name})',
            onPressed: () => ref.read(themeControllerProvider.notifier).toggleTheme(context),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ONE Large "Drawings" Hero Card with subtle dune-wave shapes
                  _buildHeroCard(context, state, isDark, primaryColor),

                  const SizedBox(height: 28),

                  // "Recent" Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (state.drawings.isNotEmpty)
                        TextButton(
                          onPressed: () => context.push('/drawings'),
                          child: Text(
                            'View all',
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
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
                        child: _buildRecentCard(context, drawing, surfaceColor, outlineColor, textColor, secondaryTextColor, isDark),
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

  Widget _buildHeroCard(BuildContext context, DrawingsListState state, bool isDark, Color primaryColor) {
    final totalFiles = state.totalFilesCount;
    final withMarkup = state.filesWithMarkupCount;
    final countSubtitle = '$totalFiles ${totalFiles == 1 ? "file" : "files"}, $withMarkup with markup';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF9E4B28) : AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black38 : AppColors.lightPrimary.withOpacity(0.2)),
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
    bool isDark,
  ) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(drawing.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor, width: 1.0),
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
            color: drawing.isPdf ? Colors.redAccent : Colors.blueAccent,
            size: 22,
          ),
        ),
        title: Text(
          drawing.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${drawing.fileType.toUpperCase()} • $formattedDate',
          style: TextStyle(fontSize: 12, color: secondaryTextColor),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}
