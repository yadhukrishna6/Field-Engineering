import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_status_state.dart';

class SyncQueueItem {
  final String id;
  final String entityType; // 'project', 'drawing', 'report', 'inspection'
  final String action; // 'create', 'update', 'delete'
  final String entityId;
  final DateTime queuedAt;
  final Map<String, dynamic>? payload;

  DateTime get timestamp => queuedAt;

  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.action,
    required this.entityId,
    required this.queuedAt,
    this.payload,
  });
}

class OfflineSyncState {
  final ConnectionStatus status;
  final bool isForcedOffline;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final List<SyncQueueItem> queue;
  final bool isSyncing;

  const OfflineSyncState({
    required this.status,
    required this.isForcedOffline,
    required this.pendingCount,
    this.lastSyncTime,
    this.queue = const [],
    this.isSyncing = false,
  });

  OfflineSyncState copyWith({
    ConnectionStatus? status,
    bool? isForcedOffline,
    int? pendingCount,
    DateTime? lastSyncTime,
    List<SyncQueueItem>? queue,
    bool? isSyncing,
  }) {
    return OfflineSyncState(
      status: status ?? this.status,
      isForcedOffline: isForcedOffline ?? this.isForcedOffline,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      queue: queue ?? this.queue,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class OfflineSyncNotifier extends StateNotifier<OfflineSyncState> {
  OfflineSyncNotifier()
      : super(OfflineSyncState(
          status: ConnectionStatus.offline, // Default field tablet mode
          isForcedOffline: true,
          pendingCount: 0,
          lastSyncTime: DateTime.now().subtract(const Duration(hours: 2)),
        ));

  void toggleConnectionMode() {
    if (state.isForcedOffline) {
      // Switch to online simulation
      final newStatus = state.pendingCount > 0 ? ConnectionStatus.syncPending : ConnectionStatus.online;
      state = state.copyWith(
        isForcedOffline: false,
        status: newStatus,
      );
    } else {
      // Switch to forced desert offline mode
      state = state.copyWith(
        isForcedOffline: true,
        status: ConnectionStatus.offline,
      );
    }
  }

  void setStatus(ConnectionStatus status) {
    state = state.copyWith(
      status: status,
      isForcedOffline: status == ConnectionStatus.offline,
    );
  }

  void enqueueChange({
    required String entityType,
    required String action,
    required String entityId,
    Map<String, dynamic>? payload,
  }) {
    final item = SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entityType: entityType,
      action: action,
      entityId: entityId,
      queuedAt: DateTime.now(),
      payload: payload,
    );

    final updatedQueue = [...state.queue, item];
    final newStatus = state.isForcedOffline
        ? ConnectionStatus.offline
        : ConnectionStatus.syncPending;

    state = state.copyWith(
      queue: updatedQueue,
      pendingCount: updatedQueue.length,
      status: newStatus,
    );
  }

  Future<void> triggerSync() async {
    if (state.queue.isEmpty) return;
    state = state.copyWith(isSyncing: true);

    // Simulate batch sync processing
    await Future.delayed(const Duration(milliseconds: 1500));

    state = state.copyWith(
      isSyncing: false,
      queue: const [],
      pendingCount: 0,
      lastSyncTime: DateTime.now(),
      status: state.isForcedOffline ? ConnectionStatus.offline : ConnectionStatus.online,
    );
  }

  void clearQueue() {
    state = state.copyWith(
      queue: const [],
      pendingCount: 0,
      status: state.isForcedOffline ? ConnectionStatus.offline : ConnectionStatus.online,
    );
  }
}

final offlineSyncProvider = StateNotifierProvider<OfflineSyncNotifier, OfflineSyncState>((ref) {
  return OfflineSyncNotifier();
});
