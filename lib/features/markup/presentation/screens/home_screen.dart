import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../domain/models/drawing_file.dart';
import '../controllers/drawings_list_controller.dart';
import '../widgets/dune_wave_painter.dart';
import '../widgets/sync_status_chip.dart';
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

    final todayStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final totalFiles = state.drawings.length;
    final recentDrawings = state.drawings.take(2).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Drawing markup'),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Center(child: SyncStatusChip()),
          ),
          IconButton(
            icon: Icon(Icons.palette_outlined, color: primaryColor),
            tooltip: 'Theme & Sun mode',
            onPressed: () => ThemeSelectorModal.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(drawingsListControllerProvider.notifier).loadDrawings(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Date subtitle
            Text(
              todayStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 14),

            // Hero Card: Drawings
            _buildHeroCard(context, totalFiles, isOutdoor, isDark),
            const SizedBox(height: 24),

            // Recent Section Header
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
                if (totalFiles > 0)
                  TextButton(
                    onPressed: () => context.push('/drawings'),
                    child: Text('View all', style: TextStyle(color: primaryColor)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent Items List
            if (recentDrawings.isEmpty)
              Card(
                elevation: 0,
                color: surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: outlineColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No recent drawings.\nTap above to view or upload drawings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ),
                ),
              )
            else
              ...recentDrawings.map((drawing) => _buildRecentItem(context, drawing, surfaceColor, outlineColor, textColor, secondaryTextColor, isOutdoor)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, int totalFiles, bool isOutdoor, bool isDark) {
    final heroColor = isOutdoor ? AppColors.outdoorPrimary : AppColors.lightPrimary;
    final cardBorder = isOutdoor ? Border.all(color: AppColors.outdoorOutline, width: 2.0) : null;

    return InkWell(
      onTap: () => context.push('/drawings'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: heroColor,
          borderRadius: BorderRadius.circular(16),
          border: cardBorder,
          boxShadow: isOutdoor
              ? null
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: DuneWavePainter(
                    waveColor: Colors.white.withOpacity(isOutdoor ? 0.08 : 0.12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.architecture_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drawings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalFiles files • Open library & markups',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
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

  Widget _buildRecentItem(
    BuildContext context,
    DrawingFile drawing,
    Color surfaceColor,
    Color outlineColor,
    Color textColor,
    Color secondaryTextColor,
    bool isOutdoor,
  ) {
    final dateStr = DateFormat('MMM d, yyyy').format(drawing.createdAt);
    final pageStr = '${drawing.pageCount} ${drawing.pageCount == 1 ? 'page' : 'pages'}';

    return Card(
      elevation: 0,
      color: surfaceColor,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outlineColor, width: isOutdoor ? 1.5 : 1.0),
      ),
      child: InkWell(
        onTap: () => context.push('/drawings/${drawing.id}', extra: drawing),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOutdoor ? AppColors.outdoorChip : AppColors.lightChip,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  drawing.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                  color: isOutdoor ? AppColors.outdoorPrimary : AppColors.lightPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drawing.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pageStr • $dateStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
