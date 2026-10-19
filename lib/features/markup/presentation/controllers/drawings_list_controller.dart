import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/drawing_text_token.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/repositories/markup_repository.dart';
import '../../data/repositories/markup_repository_impl.dart';

final markupRepositoryProvider = Provider<MarkupRepository>((ref) {
  return MarkupRepositoryImpl();
});

class DrawingsListState {
  final bool isLoading;
  final List<DrawingFile> drawings;
  final Map<String, int> markupCountByDrawing;
  final String? errorMessage;

  const DrawingsListState({
    this.isLoading = false,
    this.drawings = const [],
    this.markupCountByDrawing = const {},
    this.errorMessage,
  });

  int get totalFilesCount => drawings.length;
  int get filesWithMarkupCount =>
      drawings.where((d) => (markupCountByDrawing[d.id] ?? 0) > 0).length;

  List<DrawingFile> get recentDrawings => drawings.take(2).toList();

  DrawingsListState copyWith({
    bool? isLoading,
    List<DrawingFile>? drawings,
    Map<String, int>? markupCountByDrawing,
    String? errorMessage,
  }) {
    return DrawingsListState(
      isLoading: isLoading ?? this.isLoading,
      drawings: drawings ?? this.drawings,
      markupCountByDrawing: markupCountByDrawing ?? this.markupCountByDrawing,
      errorMessage: errorMessage,
    );
  }
}

class DrawingsListController extends StateNotifier<DrawingsListState> {
  final MarkupRepository _repository;
  final ApiClient? _apiClient;
  final _uuid = const Uuid();

  DrawingsListController(this._repository, [this._apiClient]) : super(const DrawingsListState(isLoading: true)) {
    loadDrawings();
  }

  Future<void> loadDrawings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Sync remote drawings from backend if online
      if (_apiClient != null) {
        try {
          final remoteList = await _apiClient.getDrawings();
          final remoteIds = remoteList.map((e) => e['id']?.toString()).whereType<String>().toSet();

          // Remove local drawings that have a remote fileUrl but were deleted on server
          final currentLocal = await _repository.getDrawings();
          for (final local in currentLocal) {
            if (local.fileUrl != null && local.fileUrl!.isNotEmpty && !remoteIds.contains(local.id)) {
              await _repository.deleteDrawing(local.id);
            }
          }

          for (final item in remoteList) {
            final id = item['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              final existing = await _repository.getDrawing(id);
              if (existing == null) {
                final remoteDrawing = DrawingFile(
                  id: id,
                  name: item['name']?.toString() ?? 'Untitled',
                  fileType: item['fileType']?.toString() ?? 'IMAGE',
                  pageCount: (item['pageCount'] as num?)?.toInt() ?? 1,
                  localPath: '',
                  fileUrl: item['fileUrl']?.toString(),
                  createdAt: item['createdAt'] != null
                      ? DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now()
                      : DateTime.now(),
                );
                await _repository.saveDrawing(remoteDrawing);
              }
            }
          }
        } catch (e) {
          debugPrint('[DrawingsListController] Remote sync check: $e');
        }
      }

      final list = await _repository.getDrawings();
      final markupCounts = <String, int>{};

      for (final drawing in list) {
        int totalItems = 0;
        for (int p = 1; p <= drawing.pageCount; p++) {
          final markup = await _repository.getPageMarkup(drawing.id, p);
          totalItems += markup.strokes.length + markup.labels.length;
        }
        markupCounts[drawing.id] = totalItems;
      }

      state = state.copyWith(
        isLoading: false,
        drawings: list,
        markupCountByDrawing: markupCounts,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<PageMarkup> getPageMarkup(String drawingId, int pageNumber) async {
    return await _repository.getPageMarkup(drawingId, pageNumber);
  }

  Future<DrawingFile> addDrawing({
    required String name,
    required String fileType,
    required String localPath,
    Uint8List? fileBytes,
    int pageCount = 1,
    String? jobNumber,
    String? drawingNumber,
    String? revision,
    String? projectName,
    String? title,
    List<DrawingTextToken>? extractedTokens,
  }) async {
    String? remoteFileUrl;
    String id = 'dwg-${_uuid.v4().substring(0, 8)}';

    // 1. Attempt upload to backend REST API if ApiClient is configured
    if (_apiClient != null) {
      try {
        final uploadResult = await _apiClient.uploadDrawing(
          fileName: name,
          filePath: localPath,
          fileBytes: fileBytes,
        );
        if (uploadResult != null) {
          if (uploadResult['id'] != null) {
            id = uploadResult['id'].toString();
          }
          if (uploadResult['fileUrl'] != null) {
            remoteFileUrl = uploadResult['fileUrl'].toString();
          }
          if (uploadResult['pageCount'] != null && uploadResult['pageCount'] is int) {
            pageCount = uploadResult['pageCount'] as int;
          }
        }
      } catch (e) {
        debugPrint('[DrawingsListController] Remote drawing upload error: $e');
      }
    }

    // 2. Persist locally to SQLite (Offline-First guarantee)
    final drawing = DrawingFile(
      id: id,
      name: name,
      fileType: fileType,
      pageCount: pageCount,
      localPath: localPath,
      fileUrl: remoteFileUrl,
      createdAt: DateTime.now(),
      jobNumber: jobNumber,
      drawingNumber: drawingNumber,
      revision: revision,
      projectName: projectName,
      title: title,
      extractedTokens: extractedTokens ?? const [],
    );

    await _repository.saveDrawing(drawing);
    await loadDrawings();
    return drawing;
  }

  Future<void> deleteDrawing(String id) async {
    if (_apiClient != null) {
      try {
        await _apiClient.deleteDrawing(id);
      } catch (e) {
        debugPrint('[DrawingsListController] Remote delete error: $e');
      }
    }
    await _repository.deleteDrawing(id);
    await loadDrawings();
  }
}

final drawingsListControllerProvider =
    StateNotifierProvider<DrawingsListController, DrawingsListState>((ref) {
  final repo = ref.watch(markupRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  return DrawingsListController(repo, apiClient);
});
