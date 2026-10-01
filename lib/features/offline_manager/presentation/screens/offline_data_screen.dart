import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../controllers/offline_controller.dart';
import '../../../../core/storage/storage_models.dart';
import '../../../../core/offline/offline_sync_manager.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/loading_state_view.dart';
import '../../../../shared/widgets/app_header_bar.dart';
import '../../../../core/utils/formatters.dart';

class OfflineDataScreen extends ConsumerWidget {
  const OfflineDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageState = ref.watch(offlineStorageNotifierProvider);
    final syncState = ref.watch(offlineSyncProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const AppHeaderBar(
        title: 'Offline Storage & Local Cache Inspector',
        subtitle: 'SQLite Database & Cached Blueprints',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline Storage & Local Cache Inspector',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Text(
                      'Manage on-device SQLite databases, cached blueprints, inspection photos and exported reports.',
                      style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Recalculate Storage'),
                  onPressed: () {
                    ref.read(offlineStorageNotifierProvider.notifier).refreshUsage();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Storage Breakdown KPI Row (6 Categories)
            Row(
              children: [
                Expanded(
                  child: _buildStorageCard(
                    context,
                    ref,
                    category: StorageCategory.pdfs,
                    title: 'PDF Blueprints',
                    bytes: storageState.usage.pdfsBytes,
                    icon: Icons.picture_as_pdf_rounded,
                    color: AppColors.safetyOrange,
                    isSelected: storageState.selectedCategory == StorageCategory.pdfs,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStorageCard(
                    context,
                    ref,
                    category: StorageCategory.thumbnails,
                    title: 'Thumbnails',
                    bytes: storageState.usage.thumbnailsBytes,
                    icon: Icons.image_rounded,
                    color: Colors.tealAccent,
                    isSelected: storageState.selectedCategory == StorageCategory.thumbnails,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStorageCard(
                    context,
                    ref,
                    category: StorageCategory.photos,
                    title: 'Site Photos',
                    bytes: storageState.usage.photosBytes,
                    icon: Icons.camera_alt_rounded,
                    color: Colors.amberAccent,
                    isSelected: storageState.selectedCategory == StorageCategory.photos,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStorageCard(
                    context,
                    ref,
                    category: StorageCategory.attachments,
                    title: 'Attachments',
                    bytes: storageState.usage.attachmentsBytes,
                    icon: Icons.attach_file_rounded,
                    color: Colors.lightBlueAccent,
                    isSelected: storageState.selectedCategory == StorageCategory.attachments,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStorageCard(
                    context,
                    ref,
                    category: StorageCategory.reports,
                    title: 'Field Reports',
                    bytes: storageState.usage.reportsBytes,
                    icon: Icons.description_rounded,
                    color: Colors.purpleAccent,
                    isSelected: storageState.selectedCategory == StorageCategory.reports,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStorageCard(
                    context,
                    ref,
                    category: StorageCategory.database,
                    title: 'SQLite Database',
                    bytes: storageState.usage.databaseBytes,
                    icon: Icons.storage_rounded,
                    color: AppColors.primaryLight,
                    isSelected: storageState.selectedCategory == StorageCategory.database,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selected Category Files Inspector & Purge Tool
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(storageState.selectedCategory.icon, color: AppColors.safetyOrange, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Files in Directory: ${storageState.selectedCategory.displayName} (${storageState.activeCategoryFiles.length} files)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      if (storageState.selectedCategory != StorageCategory.database &&
                          storageState.activeCategoryFiles.isNotEmpty)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                          label: Text('Purge ${storageState.selectedCategory.displayName}'),
                          onPressed: () {
                            _confirmPurgeCategory(context, ref, storageState.selectedCategory);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (storageState.isLoading)
                    const LoadingStateView(message: 'Reading file system directory...')
                  else if (storageState.activeCategoryFiles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No files present in ${storageState.selectedCategory.displayName} directory.',
                          style: const TextStyle(color: AppColors.darkTextMuted),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: storageState.activeCategoryFiles.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entity = storageState.activeCategoryFiles[index];
                        final isFile = entity is File;
                        int length = 0;
                        if (isFile) {
                          try {
                            length = entity.lengthSync();
                          } catch (_) {}
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Icon(
                            isFile ? Icons.insert_drive_file_outlined : Icons.folder_outlined,
                            color: AppColors.primaryLight,
                          ),
                          title: Text(
                            p.basename(entity.path),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            entity.path,
                            style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                StorageUsage.formatBytes(length),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                tooltip: 'Delete file',
                                onPressed: () async {
                                  try {
                                    if (await entity.exists()) {
                                      await entity.delete();
                                      ref.read(offlineStorageNotifierProvider.notifier).refreshUsage();
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Could not delete file: $e')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sync Audit Changelog Table (Offline Transactions)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_edu_rounded, color: AppColors.safetyOrange, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Offline Mutation Changelog & Sync Queue',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      if (syncState.queue.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all_rounded, size: 16),
                          label: const Text('Clear Sync History'),
                          onPressed: () {
                            ref.read(offlineSyncProvider.notifier).clearQueue();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (syncState.queue.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No pending offline transactions. All local changes are registered.',
                          style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(2.5),
                        3: FlexColumnWidth(2),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 0.5,
                        ),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                          ),
                          children: const [
                            Padding(padding: EdgeInsets.all(8), child: Text('Entity Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Entity ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        ...syncState.queue.map((item) {
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(8), child: Text(item.entityType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  item.action.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.action == 'delete' ? Colors.redAccent : AppColors.online,
                                  ),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.all(8), child: Text(item.entityId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                              Padding(padding: const EdgeInsets.all(8), child: Text(AppFormatters.formatDateTime(item.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted))),
                            ],
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard(
    BuildContext context,
    WidgetRef ref, {
    required StorageCategory category,
    required String title,
    required int bytes,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        ref.read(offlineStorageNotifierProvider.notifier).selectCategory(category);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              StorageUsage.formatBytes(bytes),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPurgeCategory(BuildContext context, WidgetRef ref, StorageCategory category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Purge ${category.displayName}?'),
          content: Text('Are you sure you want to purge all local files stored in the ${category.displayName} directory?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(offlineStorageNotifierProvider.notifier).purgeCategory(category);
              },
              child: const Text('Purge All', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
