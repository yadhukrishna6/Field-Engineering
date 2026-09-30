import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/offline/offline_sync_manager.dart';
import '../../core/offline/network_status_state.dart';

class OfflineStatusBadge extends ConsumerWidget {
  final bool showLabel;
  final bool compact;

  const OfflineStatusBadge({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(offlineSyncProvider);
    final status = syncState.status;

    return InkWell(
      onTap: () => _showStatusDialog(context, ref, syncState),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: status.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: status.color.withOpacity(0.4), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: status.color.withOpacity(0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 11 : 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
            if (syncState.pendingCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: status.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${syncState.pendingCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, WidgetRef ref, OfflineSyncState state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(state.status.icon, color: state.status.color, size: 28),
              const SizedBox(width: 12),
              Text('Network & Sync State: ${state.status.label}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.status.description, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('Pending offline changes:', '${state.pendingCount} items'),
                    const SizedBox(height: 6),
                    _buildDialogRow(
                      'Mode:',
                      state.isForcedOffline ? 'Forced Desert Field Offline' : 'Online / Auto-detect',
                    ),
                    const SizedBox(height: 6),
                    _buildDialogRow(
                      'Last Server Sync:',
                      state.lastSyncTime != null
                          ? '${state.lastSyncTime!.hour}:${state.lastSyncTime!.minute.toString().padLeft(2, '0')}'
                          : 'None',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(offlineSyncProvider.notifier).toggleConnectionMode();
                Navigator.pop(context);
              },
              child: Text(state.isForcedOffline ? 'Switch to ONLINE Mode' : 'Switch to OFFLINE Mode'),
            ),
            if (state.pendingCount > 0)
              ElevatedButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Sync Now'),
                onPressed: () {
                  ref.read(offlineSyncProvider.notifier).triggerSync();
                  Navigator.pop(context);
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
