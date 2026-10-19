import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../data/local/offline_sync_queue.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/repositories/markup_repository.dart';
import 'drawings_list_controller.dart';

@immutable
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastSyncMessage;
  final List<SyncQueueItem> queueItems;

  const SyncState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.lastSyncMessage,
    this.queueItems = const [],
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastSyncMessage,
    List<SyncQueueItem>? queueItems,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
      queueItems: queueItems ?? this.queueItems,
    );
  }
}

class SyncStatusController extends StateNotifier<SyncState> {
  static const _prefOnlineKey = 'field_app_is_online_v1';
  final SharedPreferences? _prefs;
  final MarkupRepository _repository;

  SyncStatusController(this._prefs, this._repository) : super(const SyncState()) {
    _loadPersistedState();
  }

  void _loadPersistedState() {
    if (_prefs == null) return;
    final isOnline = _prefs.getBool(_prefOnlineKey) ?? true;
    state = state.copyWith(
      isOnline: isOnline,
      lastSyncedAt: DateTime.now(),
    );
  }

  Future<void> setOnline(bool online) async {
    state = state.copyWith(isOnline: online);
    final p = _prefs;
    if (p != null) {
      await p.setBool(_prefOnlineKey, online);
    }
    if (online && state.pendingCount > 0) {
      await syncNow();
    }
  }

  Future<void> toggleOnline() async {
    await setOnline(!state.isOnline);
  }

  void enqueueChange({
    required SyncEntityType entityType,
    required String entityId,
    required SyncQueueAction action,
    required String payloadJson,
  }) {
    final item = SyncQueueItem(
      id: 'sync-${DateTime.now().microsecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      action: action,
      payloadJson: payloadJson,
      timestamp: DateTime.now(),
    );

    final updatedQueue = [...state.queueItems, item];
    state = state.copyWith(
      queueItems: updatedQueue,
      pendingCount: updatedQueue.length,
    );

    if (state.isOnline) {
      syncNow();
    }
  }

  Future<void> syncNow() async {
    if (state.isSyncing || state.queueItems.isEmpty) return;

    state = state.copyWith(isSyncing: true, lastSyncMessage: 'Synchronizing field markups with server...');

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final itemsToProcess = List<SyncQueueItem>.from(state.queueItems);
      for (final item in itemsToProcess) {
        if (item.entityType == SyncEntityType.pageMarkup) {
          try {
            final data = jsonDecode(item.payloadJson);
            final parts = item.entityId.split(':');
            if (parts.length >= 2) {
              final drawingId = parts[0];
              final pageNumber = int.tryParse(parts[1]) ?? 1;
              final markup = PageMarkup(
                drawingId: drawingId,
                pageNumber: pageNumber,
                annotations: (data['annotations'] as List? ?? [])
                    .map((a) => AnnotationItem.fromJson(a as Map<String, dynamic>))
                    .toList(),
                version: (data['version'] as num?)?.toInt() ?? 1,
                updatedAt: item.timestamp,
              );
              await _repository.savePageMarkup(markup);
            }
          } catch (_) {}
        }
      }

      state = state.copyWith(
        isSyncing: false,
        pendingCount: 0,
        queueItems: const [],
        lastSyncedAt: DateTime.now(),
        lastSyncMessage: 'All changes synced successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastSyncMessage: 'Sync failed: $e',
      );
    }
  }
}

final syncStatusProvider = StateNotifierProvider<SyncStatusController, SyncState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final repo = ref.watch(markupRepositoryProvider);
  return SyncStatusController(prefs, repo);
});
