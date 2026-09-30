import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/drawing_type.dart';
import '../controllers/drawings_controller.dart';
import '../widgets/drawing_card.dart';
import '../widgets/drawing_import_modal.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/loading_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../core/theme/color_palette.dart';

class DrawingListScreen extends ConsumerWidget {
  const DrawingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(allDrawingsNotifierProvider);
    final filter = ref.watch(drawingsFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Controls Bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppSearchField(
                    hintText: 'Search drawings by tag, drawing number, title, or system...',
                    onChanged: (query) {
                      ref.read(drawingsFilterProvider.notifier).state = filter.copyWith(searchQuery: query);
                      ref.read(allDrawingsNotifierProvider.notifier).loadDrawings();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Offline Only Toggle Chip
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin_rounded, size: 14, color: AppColors.online),
                      SizedBox(width: 6),
                      Text('Downloaded Only'),
                    ],
                  ),
                  selected: filter.downloadedOnly == true,
                  onSelected: (selected) {
                    ref.read(drawingsFilterProvider.notifier).state = filter.copyWith(
                      downloadedOnly: selected ? true : null,
                    );
                    ref.read(allDrawingsNotifierProvider.notifier).loadDrawings();
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyOrange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_to_photos_rounded, size: 18),
                  label: const Text('Import PDF'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const DrawingImportModal(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Discipline Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDisciplineChip(
                    ref: ref,
                    label: 'All Disciplines',
                    isSelected: filter.typeFilter == null,
                    onSelected: () {
                      ref.read(drawingsFilterProvider.notifier).state = filter.copyWith(clearType: true);
                      ref.read(allDrawingsNotifierProvider.notifier).loadDrawings();
                    },
                  ),
                  ...DrawingType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildDisciplineChip(
                        ref: ref,
                        label: type.displayName,
                        isSelected: filter.typeFilter == type,
                        icon: type.icon,
                        color: type.color,
                        onSelected: () {
                          ref.read(drawingsFilterProvider.notifier).state = filter.copyWith(typeFilter: type);
                          ref.read(allDrawingsNotifierProvider.notifier).loadDrawings();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Main Drawings Grid / Content Area
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading && state.drawings.isEmpty) {
                    return const LoadingStateView(message: 'Loading offline drawing registry...');
                  }

                  if (state.errorMessage != null && state.drawings.isEmpty) {
                    return ErrorStateView(
                      message: state.errorMessage!,
                      onRetry: () => ref.read(allDrawingsNotifierProvider.notifier).loadDrawings(),
                    );
                  }

                  if (state.drawings.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.layers_clear_rounded,
                      title: 'No Drawings Found',
                      message: filter.searchQuery.isNotEmpty || filter.typeFilter != null
                          ? 'No engineering drawings match the current filter criteria.'
                          : 'No drawings have been imported to this tablet yet.',
                      actionLabel: 'Import Drawing PDF',
                      onAction: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => const DrawingImportModal(),
                        );
                      },
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;

                      return GridView.builder(
                        itemCount: state.drawings.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.6,
                        ),
                        itemBuilder: (context, index) {
                          final drawing = state.drawings[index];
                          return DrawingCard(
                            drawing: drawing,
                            onTap: () {
                              context.go('/drawings/${drawing.id}/view');
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplineChip({
    required WidgetRef ref,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
    Color? color,
  }) {
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null && color != null) ...[
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) => onSelected(),
      selectedColor: color ?? AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.darkTextSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }
}
