import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_status_provider.dart';

class SyncStatusBadge extends ConsumerWidget {
  final VoidCallback? onTap;

  const SyncStatusBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusStreamProvider);

    final status = statusAsync.value ??
        const SyncEngineStatus(
          state: SyncEngineState.synced,
          pendingCount: 0,
          failedCount: 0,
          conflictCount: 0,
          isOnline: true,
        );

    Color bg;
    Color fg;
    IconData icon;

    switch (status.state) {
      case SyncEngineState.offline:
        bg = Colors.grey.shade800;
        fg = Colors.grey.shade400;
        icon = Icons.cloud_off;
        break;
      case SyncEngineState.syncing:
        bg = Colors.blue.shade900.withOpacity(0.5);
        fg = Colors.lightBlueAccent;
        icon = Icons.sync;
        break;
      case SyncEngineState.synced:
        bg = Colors.green.shade900.withOpacity(0.4);
        fg = Colors.greenAccent;
        icon = Icons.cloud_done;
        break;
      case SyncEngineState.syncPending:
        bg = Colors.amber.shade900.withOpacity(0.4);
        fg = Colors.amberAccent;
        icon = Icons.cloud_upload;
        break;
      case SyncEngineState.syncFailed:
        bg = Colors.red.shade900.withOpacity(0.4);
        fg = Colors.redAccent;
        icon = Icons.sync_problem;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: fg.withOpacity(0.6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.state == SyncEngineState.syncing)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            else
              Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              status.displayBadge,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
