import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/sync/conflict_resolver.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_queue_item.dart';
import '../../../../core/sync/sync_status_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/conflict_dialog.dart';

class SyncCenterScreen extends ConsumerStatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  ConsumerState<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends ConsumerState<SyncCenterScreen> {

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(syncEngineProvider);
    final statusAsync = ref.watch(syncStatusStreamProvider);
    final queueAsync = ref.watch(syncQueueListProvider);

    final status = statusAsync.value ??
        SyncEngineStatus(
          state: SyncEngineState.synced,
          pendingCount: 0,
          failedCount: 0,
          conflictCount: 0,
          isOnline: true,
        );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sync_alt, color: AppColors.accent),
            const SizedBox(width: 12),
            Text(
              'Offline Sync Center & Cloud Bridge',
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Simulated Desert Offline / Online Switch
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(
                  engine.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: engine.isOnline ? Colors.greenAccent : Colors.amberAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  engine.isOnline ? 'Online (Connected)' : 'Desert Field (Offline)',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: engine.isOnline,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) {
                    engine.setConnectivity(val);
                  },
                ),
              ],
            ),
          ),
          // Manual Sync Now Button
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: status.state == SyncEngineState.syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: status.state == SyncEngineState.syncing
                  ? null
                  : () async {
                      final success = await engine.triggerSync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Synchronization completed successfully.' : 'Sync failed. Local data preserved.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Metrics Row
            _buildMetricsRow(status),
            const SizedBox(height: 24),

            // Sync Queue Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending & Processed Sync Queue', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                    const Text(
                      'Local database operations queued for cloud replication. Local changes are never lost.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cleaning_services, size: 16),
                  label: const Text('Clear Synced'),
                  onPressed: () async {
                    await engine.clearCompletedSyncedItems();
                    ref.invalidate(syncQueueListProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Queue List
            queueAsync.when(
              data: (queue) {
                if (queue.isEmpty) {
                  return _buildEmptyQueueCard();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = queue[index];
                    return _buildQueueItemCard(item, engine);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading queue: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(SyncEngineStatus status) {
    return Row(
      children: [
        _buildMetricCard(
          title: 'Sync State',
          value: status.displayBadge,
          icon: Icons.cloud_sync,
          color: status.state == SyncEngineState.synced
              ? Colors.greenAccent
              : (status.state == SyncEngineState.offline ? Colors.grey : Colors.amberAccent),
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          title: 'Pending Queue',
          value: '${status.pendingCount}',
          icon: Icons.pending_actions,
          color: status.pendingCount > 0 ? Colors.amberAccent : Colors.white70,
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          title: 'Conflicts',
          value: '${status.conflictCount}',
          icon: Icons.warning_amber_rounded,
          color: status.conflictCount > 0 ? Colors.redAccent : Colors.white70,
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          title: 'Failed Ops',
          value: '${status.failedCount}',
          icon: Icons.error_outline,
          color: status.failedCount > 0 ? Colors.redAccent : Colors.white70,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_done_outlined, size: 48, color: Colors.greenAccent),
          const SizedBox(height: 12),
          const Text('All Field Data Synchronized', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'No pending operations in local queue. All markups, inspections, and drawings are up to date with cloud server.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItemCard(SyncQueueItem item, SyncEngine engine) {
    Color statusColor;
    switch (item.status) {
      case SyncStatus.pending:
        statusColor = Colors.amberAccent;
        break;
      case SyncStatus.syncing:
        statusColor = Colors.lightBlueAccent;
        break;
      case SyncStatus.synced:
        statusColor = Colors.greenAccent;
        break;
      case SyncStatus.failed:
        statusColor = Colors.redAccent;
        break;
      case SyncStatus.conflict:
        statusColor = Colors.orangeAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.status == SyncStatus.conflict ? Colors.orangeAccent : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          // Operation Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.accent.withOpacity(0.5)),
            ),
            child: Text(
              item.operation.name.toUpperCase(),
              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // Entity Type & ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.entityType.toUpperCase()} — ID: ${item.entityId.substring(0, item.entityId.length > 12 ? 12 : item.entityId.length)}...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enqueued: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(item.createdAt)} ${item.retryCount > 0 ? "• Retries: ${item.retryCount}" : ""}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.status.name.toUpperCase(),
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          if (item.status == SyncStatus.conflict) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () {
                final conflict = SyncConflictRecord.create(
                  entityType: item.entityType,
                  entityId: item.entityId,
                  localPayload: {'id': item.entityId, 'status': 'Modified locally in field'},
                  serverPayload: {'id': item.entityId, 'status': 'Updated on Cloud Portal'},
                  localVersion: 2,
                  serverVersion: 3,
                );
                showDialog(
                  context: context,
                  builder: (ctx) => ConflictResolutionDialog(
                    conflict: conflict,
                    onResolve: (strategy, merged) async {
                      await engine.resolveConflict(
                        queueId: item.id,
                        strategy: strategy,
                        mergedPayload: merged,
                      );
                      ref.invalidate(syncQueueListProvider);
                    },
                  ),
                );
              },
              child: const Text('Resolve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }
}
