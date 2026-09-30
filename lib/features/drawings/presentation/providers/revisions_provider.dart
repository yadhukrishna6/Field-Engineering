import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_queue_item.dart';
import '../../data/datasources/revisions_local_datasource.dart';
import '../../domain/models/drawing_revision.dart';

final revisionsLocalDataSourceProvider = Provider<RevisionsLocalDataSource>((ref) {
  return RevisionsLocalDataSource(AppDatabase.instance);
});

final drawingRevisionsProvider = FutureProvider.family<List<DrawingRevision>, String>((ref, drawingId) async {
  final ds = ref.watch(revisionsLocalDataSourceProvider);
  final revisions = await ds.getRevisionsForDrawing(drawingId);
  if (revisions.isEmpty) {
    // Seed initial Rev 00 and Rev 01 for demonstration if none exist
    final rev0 = DrawingRevision(
      id: 'rev-00-$drawingId',
      drawingId: drawingId,
      revisionNumber: 'Rev 00',
      revisionDescription: 'Issued for Review (IFR) - Initial Piping & Instrumentation',
      uploadedBy: 'John Doe, Lead Piping Engineer',
      uploadedAt: DateTime.now().subtract(const Duration(days: 30)),
      filePath: 'assets/sample_drawings/pid_drawing_sample.pdf',
      status: RevisionStatus.superseded,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    final rev1 = DrawingRevision(
      id: 'rev-01-$drawingId',
      drawingId: drawingId,
      revisionNumber: 'Rev 01',
      revisionDescription: 'Issued for Construction (IFC) - Added pressure relief valves and bypass line',
      uploadedBy: 'Alex Morgan, Lead Engineer',
      uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
      filePath: 'assets/sample_drawings/pid_drawing_sample.pdf',
      status: RevisionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    );
    await ds.insertRevision(rev0);
    await ds.insertRevision(rev1);
    return [rev1, rev0];
  }
  return revisions;
});

class RevisionsNotifier extends StateNotifier<AsyncValue<List<DrawingRevision>>> {
  final RevisionsLocalDataSource _dataSource;
  final String _drawingId;

  RevisionsNotifier(this._dataSource, this._drawingId) : super(const AsyncValue.loading()) {
    loadRevisions();
  }

  Future<void> loadRevisions() async {
    try {
      final list = await _dataSource.getRevisionsForDrawing(_drawingId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRevision({
    required String revisionNumber,
    required String description,
    required String uploadedBy,
    required String filePath,
    RevisionStatus status = RevisionStatus.approved,
  }) async {
    final rev = DrawingRevision.create(
      drawingId: _drawingId,
      revisionNumber: revisionNumber,
      revisionDescription: description,
      uploadedBy: uploadedBy,
      filePath: filePath,
      status: status,
    );
    await _dataSource.insertRevision(rev);

    // Enqueue in sync engine
    await SyncEngine().enqueueOperation(
      entityType: 'revision',
      entityId: rev.id,
      operation: SyncOperation.create,
      payload: rev.toMap(),
    );

    await loadRevisions();
  }
}

final revisionsNotifierProvider =
    StateNotifierProvider.family<RevisionsNotifier, AsyncValue<List<DrawingRevision>>, String>(
        (ref, drawingId) {
  final ds = ref.watch(revisionsLocalDataSourceProvider);
  return RevisionsNotifier(ds, drawingId);
});
