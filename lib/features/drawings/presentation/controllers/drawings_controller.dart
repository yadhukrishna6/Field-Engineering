import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/drawing.dart';
import '../../domain/models/drawing_type.dart';
import '../../domain/repositories/drawings_repository.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/offline/offline_sync_manager.dart';

class DrawingsFilterState {
  final String searchQuery;
  final DrawingType? typeFilter;
  final String? revisionFilter;
  final bool? downloadedOnly;

  const DrawingsFilterState({
    this.searchQuery = '',
    this.typeFilter,
    this.revisionFilter,
    this.downloadedOnly,
  });

  DrawingsFilterState copyWith({
    String? searchQuery,
    DrawingType? typeFilter,
    String? revisionFilter,
    bool? downloadedOnly,
    bool clearType = false,
    bool clearRevision = false,
  }) {
    return DrawingsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      revisionFilter: clearRevision ? null : (revisionFilter ?? this.revisionFilter),
      downloadedOnly: downloadedOnly ?? this.downloadedOnly,
    );
  }
}

final drawingsFilterProvider = StateProvider<DrawingsFilterState>((ref) {
  return const DrawingsFilterState();
});

class DrawingsListState {
  final bool isLoading;
  final List<Drawing> drawings;
  final String? errorMessage;
  final Set<String> downloadingDrawingIds;

  const DrawingsListState({
    this.isLoading = false,
    this.drawings = const [],
    this.errorMessage,
    this.downloadingDrawingIds = const {},
  });

  DrawingsListState copyWith({
    bool? isLoading,
    List<Drawing>? drawings,
    String? errorMessage,
    Set<String>? downloadingDrawingIds,
  }) {
    return DrawingsListState(
      isLoading: isLoading ?? this.isLoading,
      drawings: drawings ?? this.drawings,
      errorMessage: errorMessage,
      downloadingDrawingIds: downloadingDrawingIds ?? this.downloadingDrawingIds,
    );
  }
}

final List<Drawing> _defaultInitialDrawings = [
  Drawing(
    id: 'dwg-p-402',
    projectId: 'prj-001',
    drawingNumber: 'P-102 - Hook-up Isometric',
    title: 'Crude Separation Train Hook-Up Isometric',
    drawingType: DrawingType.isometric,
    revision: 'Rev 02',
    filePath: 'assets/sample_drawings/isometric_sample.pdf',
    pageCount: 3,
    fileSize: 9017753, // ~8.6 MB
    downloaded: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Drawing(
    id: 'dwg-p-101',
    projectId: 'prj-001',
    drawingNumber: 'P-101 - Piping Plan',
    title: 'General Area Piping Layout & Elevation',
    drawingType: DrawingType.piping,
    revision: 'Rev 03',
    filePath: 'assets/sample_drawings/piping_sample.pdf',
    pageCount: 4,
    fileSize: 13002342, // ~12.4 MB
    downloaded: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Drawing(
    id: 'dwg-p-103',
    projectId: 'prj-001',
    drawingNumber: 'P-103 - P&ID',
    title: 'Process & Instrumentation Diagram - Flare Header',
    drawingType: DrawingType.pid,
    revision: 'Rev 05',
    filePath: 'assets/sample_drawings/pid_drawing_sample.pdf',
    pageCount: 2,
    fileSize: 6501171, // ~6.2 MB
    downloaded: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Drawing(
    id: 'dwg-s-101',
    projectId: 'prj-001',
    drawingNumber: 'S-101 - Structural Plan',
    title: 'Pipe Rack Support Structural Foundation',
    drawingType: DrawingType.structural,
    revision: 'Rev 01',
    filePath: 'assets/sample_drawings/structural_sample.pdf',
    pageCount: 5,
    fileSize: 10590617, // ~10.1 MB
    downloaded: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

class DrawingsListNotifier extends StateNotifier<DrawingsListState> {
  final DrawingsRepository _repository;
  final Ref _ref;
  final String? _projectId;

  DrawingsListNotifier(this._repository, this._ref, [this._projectId])
      : super(DrawingsListState(drawings: _defaultInitialDrawings)) {
    loadDrawings();
  }

  Future<void> loadDrawings() async {
    try {
      final filter = _ref.read(drawingsFilterProvider);
      List<Drawing> results;

      final projectId = _projectId;
      if (projectId != null && projectId.isNotEmpty) {
        results = await _repository.getDrawingsForProject(
          projectId,
          searchQuery: filter.searchQuery,
          typeFilter: filter.typeFilter,
          revisionFilter: filter.revisionFilter,
        );
      } else {
        results = await _repository.getAllDrawings(
          searchQuery: filter.searchQuery,
          typeFilter: filter.typeFilter,
          downloadedOnly: filter.downloadedOnly,
        );
      }

      if (results.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          drawings: results,
        );
      }
    } catch (e) {
      // Retain cached state
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Drawing?> addDrawing(Drawing drawing) async {
    try {
      final created = await _repository.addDrawing(drawing);
      _ref.read(offlineSyncProvider.notifier).enqueueChange(
        entityType: 'drawing',
        action: 'create',
        entityId: created.id,
        payload: created.toMap(),
      );
      await loadDrawings();
      return created;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add drawing: $e');
      return null;
    }
  }

  Future<Drawing?> importPdfDrawing({
    required String projectId,
    required String sourceFilePath,
    required String drawingNumber,
    required String title,
    required DrawingType drawingType,
    required String revision,
  }) async {
    try {
      final imported = await _repository.importPdfDrawing(
        projectId: projectId,
        sourceFilePath: sourceFilePath,
        drawingNumber: drawingNumber,
        title: title,
        drawingType: drawingType,
        revision: revision,
      );
      _ref.read(offlineSyncProvider.notifier).enqueueChange(
        entityType: 'drawing',
        action: 'import_pdf',
        entityId: imported.id,
      );
      await loadDrawings();
      return imported;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to import PDF: $e');
      return null;
    }
  }

  Future<bool> deleteDrawing(String id) async {
    try {
      final success = await _repository.deleteDrawing(id);
      if (success) {
        _ref.read(offlineSyncProvider.notifier).enqueueChange(
          entityType: 'drawing',
          action: 'delete',
          entityId: id,
        );
        await loadDrawings();
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete drawing: $e');
      return false;
    }
  }

  Future<void> toggleDownloadStatus(String drawingId, bool currentStatus) async {
    final nextStatus = !currentStatus;
    final activeSet = Set<String>.from(state.downloadingDrawingIds)..add(drawingId);
    state = state.copyWith(downloadingDrawingIds: activeSet);

    // Simulate fast local caching / package preparation
    await Future.delayed(const Duration(milliseconds: 350));

    await _repository.markDrawingDownloaded(drawingId, nextStatus);

    final updatedSet = Set<String>.from(state.downloadingDrawingIds)..remove(drawingId);
    state = state.copyWith(downloadingDrawingIds: updatedSet);

    await loadDrawings();
  }
}

final projectDrawingsNotifierProvider =
    StateNotifierProvider.family<DrawingsListNotifier, DrawingsListState, String>((ref, projectId) {
  final repo = ref.watch(drawingsRepositoryProvider);
  return DrawingsListNotifier(repo, ref, projectId);
});

final allDrawingsNotifierProvider =
    StateNotifierProvider<DrawingsListNotifier, DrawingsListState>((ref) {
  final repo = ref.watch(drawingsRepositoryProvider);
  return DrawingsListNotifier(repo, ref, null);
});

final singleDrawingProvider = FutureProvider.family<Drawing?, String>((ref, drawingId) async {
  final repo = ref.watch(drawingsRepositoryProvider);
  return repo.getDrawingById(drawingId);
});
