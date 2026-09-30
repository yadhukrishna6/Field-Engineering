import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_engine.dart';
import 'sync_queue_item.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine();
  engine.initialize();
  ref.onDispose(() => engine.dispose());
  return engine;
});

final syncStatusStreamProvider = StreamProvider<SyncEngineStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.statusStream;
});

final syncQueueListProvider = FutureProvider<List<SyncQueueItem>>((ref) async {
  final engine = ref.watch(syncEngineProvider);
  // Re-fetch when status changes
  ref.watch(syncStatusStreamProvider);
  return engine.getPendingQueue();
});
