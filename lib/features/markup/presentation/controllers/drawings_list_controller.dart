import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/repositories/markup_repository.dart';
import '../../data/repositories/markup_repository_impl.dart';

final markupRepositoryProvider = Provider<MarkupRepository>((ref) {
  return MarkupRepositoryImpl();
});

class DrawingsListState {
  final bool isLoading;
  final List<DrawingFile> drawings;
  final Map<String, int> markupCountByDrawing; // total strokes + labels per drawing
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
  final _uuid = const Uuid();

  DrawingsListController(this._repository) : super(const DrawingsListState(isLoading: true)) {
    loadDrawings();
  }

  Future<void> loadDrawings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
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
    int pageCount = 1,
  }) async {
    final drawing = DrawingFile(
      id: 'dwg-${_uuid.v4().substring(0, 8)}',
      name: name,
      fileType: fileType,
      pageCount: pageCount,
      localPath: localPath,
      createdAt: DateTime.now(),
    );

    await _repository.saveDrawing(drawing);
    await loadDrawings();
    return drawing;
  }

  Future<void> deleteDrawing(String id) async {
    await _repository.deleteDrawing(id);
    await loadDrawings();
  }
}

final drawingsListControllerProvider =
    StateNotifierProvider<DrawingsListController, DrawingsListState>((ref) {
  final repo = ref.watch(markupRepositoryProvider);
  return DrawingsListController(repo);
});
