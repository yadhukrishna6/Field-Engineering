import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glove_mode_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../controllers/sync_status_controller.dart';

class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);
    final themeState = ref.watch(themeControllerProvider);
    final isOutdoor = themeState.isOutdoorActive;
    final gloveState = ref.watch(gloveModeProvider);
    final minTouchTarget = gloveState.minTouchTarget(isOutdoor);

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    if (syncState.isSyncing) {
      badgeBg = Colors.blue.withOpacity(0.15);
      badgeText = isOutdoor ? const Color(0xFF185FA5) : Colors.blue.shade700;
      badgeIcon = Icons.sync_rounded;
      badgeLabel = 'Syncing...';
    } else if (!syncState.isOnline) {
      badgeBg = Colors.amber.withOpacity(0.18);
      badgeText = isOutdoor ? const Color(0xFFC25E00) : Colors.amber.shade900;
      badgeIcon = Icons.cloud_off_rounded;
      badgeLabel = syncState.pendingCount > 0
          ? 'Offline (${syncState.pendingCount})'
          : 'Offline';
    } else {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = isOutdoor ? const Color(0xFF1F6B2D) : const Color(0xFF2E7D32);
      badgeIcon = Icons.cloud_done_rounded;
      badgeLabel = 'Synced';
    }

    return InkWell(
      onTap: () => _showSyncDetailsModal(context, ref),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: BoxConstraints(minHeight: minTouchTarget * 0.7, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeText.withOpacity(0.4), width: isOutdoor ? 1.5 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncState.isSyncing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: badgeText,
                ),
              )
            else
              Icon(badgeIcon, size: 15, color: badgeText),
            const SizedBox(width: 6),
            Text(
              badgeLabel,
              style: TextStyle(
                fontSize: isOutdoor ? 12 : 11,
                fontWeight: FontWeight.bold,
                color: badgeText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDetailsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final syncState = ref.watch(syncStatusProvider);
            final syncNotifier = ref.read(syncStatusProvider.notifier);
            final themeState = ref.watch(themeControllerProvider);
            final isOutdoor = themeState.isOutdoorActive;
            final isDark = themeState.isDarkActive;

            final surfaceColor = isOutdoor
                ? AppColors.outdoorSurface
                : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
            final textColor = isOutdoor
                ? AppColors.outdoorText
                : (isDark ? AppColors.darkText : AppColors.lightText);
            final primaryColor = isOutdoor
                ? AppColors.outdoorPrimary
                : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
            final outlineColor = isOutdoor
                ? AppColors.outdoorOutline
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: outlineColor),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              syncState.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Offline & Sync Status',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        syncState.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        color: primaryColor,
                      ),
                      title: Text(
                        'Network Connection',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      subtitle: Text(
                        syncState.isOnline
                            ? 'Online - Changes sync immediately with server'
                            : 'Field Offline Mode - All markups queued locally',
                        style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
                      ),
                      trailing: Switch.adaptive(
                        value: syncState.isOnline,
                        activeColor: primaryColor,
                        onChanged: (val) {
                          syncNotifier.setOnline(val);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOutdoor ? AppColors.outdoorChip : AppColors.lightChip,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: outlineColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.queue_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Queued Mutations: ${syncState.pendingCount}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                ),
                                Text(
                                  'Per-annotation conflict resolution active (latest edit wins, loser preserved as conflict copy).',
                                  style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('Sync Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: syncState.isSyncing
                            ? null
                            : () async {
                                await syncNotifier.syncNow();
                                if (context.mounted) Navigator.pop(ctx);
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }
}
