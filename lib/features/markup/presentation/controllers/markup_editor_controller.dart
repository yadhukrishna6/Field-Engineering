import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/models/stroke.dart';
import '../../domain/utils/stroke_smoother.dart';
import '../../domain/repositories/markup_repository.dart';
import 'drawings_list_controller.dart';

const List<Color> kMarkupColorPresets = [
  Color(0xFFFF3B30), // Safety Red
  Color(0xFF34C759), // Field Green
  Color(0xFF007AFF), // P&ID Blue
  Color(0xFFFF9500), // Hazard Orange
];

const List<double> kStrokeWidthPresets = [
  2.0, // Thin
  4.0, // Medium
  8.0, // Thick
];

enum MarkupTool { pen, none }

class MarkupEditorState {
  final DrawingFile drawing;
  final int currentPage;
  final MarkupTool selectedTool;
  final Color activeColor;
  final double activeStrokeWidth;
  final List<Stroke> strokes;
  final List<Point2D> activeStrokePoints;
  final List<List<Stroke>> undoStack;
  final List<List<Stroke>> redoStack;
  final bool allowFingerDrawing;
  final bool isAutosaving;
  final bool hasUnsavedChanges;
  final int version;

  const MarkupEditorState({
    required this.drawing,
    this.currentPage = 1,
    this.selectedTool = MarkupTool.pen,
    this.activeColor = const Color(0xFFFF3B30),
    this.activeStrokeWidth = 4.0,
    this.strokes = const [],
    this.activeStrokePoints = const [],
    this.undoStack = const [],
    this.redoStack = const [],
    this.allowFingerDrawing = true,
    this.isAutosaving = false,
    this.hasUnsavedChanges = false,
    this.version = 1,
  });

  bool get canUndo => undoStack.length > 1;
  bool get canRedo => redoStack.isNotEmpty;

  MarkupEditorState copyWith({
    DrawingFile? drawing,
    int? currentPage,
    MarkupTool? selectedTool,
    Color? activeColor,
    double? activeStrokeWidth,
    List<Stroke>? strokes,
    List<Point2D>? activeStrokePoints,
    List<List<Stroke>>? undoStack,
    List<List<Stroke>>? redoStack,
    bool? allowFingerDrawing,
    bool? isAutosaving,
    bool? hasUnsavedChanges,
    int? version,
  }) {
    return MarkupEditorState(
      drawing: drawing ?? this.drawing,
      currentPage: currentPage ?? this.currentPage,
      selectedTool: selectedTool ?? this.selectedTool,
      activeColor: activeColor ?? this.activeColor,
      activeStrokeWidth: activeStrokeWidth ?? this.activeStrokeWidth,
      strokes: strokes ?? this.strokes,
      activeStrokePoints: activeStrokePoints ?? this.activeStrokePoints,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      allowFingerDrawing: allowFingerDrawing ?? this.allowFingerDrawing,
      isAutosaving: isAutosaving ?? this.isAutosaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      version: version ?? this.version,
    );
  }
}

class MarkupEditorController extends StateNotifier<MarkupEditorState> {
  final MarkupRepository _repository;
  Timer? _autosaveDebounce;

  MarkupEditorController(this._repository, DrawingFile drawing)
      : super(MarkupEditorState(drawing: drawing)) {
    loadPageMarkup(1);
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadPageMarkup(int pageNumber) async {
    _scheduleAutosaveNow();
    final markup = await _repository.getPageMarkup(state.drawing.id, pageNumber);
    state = state.copyWith(
      currentPage: pageNumber,
      strokes: markup.strokes,
      activeStrokePoints: const [],
      undoStack: [markup.strokes],
      redoStack: const [],
      version: markup.version,
      hasUnsavedChanges: false,
    );
  }

  void setPage(int page) {
    if (page == state.currentPage || page < 1 || page > state.drawing.pageCount) return;
    loadPageMarkup(page);
  }

  void selectTool(MarkupTool tool) {
    state = state.copyWith(selectedTool: tool);
  }

  void setColor(Color color) {
    state = state.copyWith(activeColor: color);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(activeStrokeWidth: width);
  }

  void toggleFingerDrawing() {
    state = state.copyWith(allowFingerDrawing: !state.allowFingerDrawing);
  }

  // --- Inking Actions ---

  void startStroke(Point2D point) {
    if (state.selectedTool != MarkupTool.pen) return;
    state = state.copyWith(activeStrokePoints: [point]);
  }

  void appendStrokePoint(Point2D point) {
    if (state.selectedTool != MarkupTool.pen || state.activeStrokePoints.isEmpty) return;
    final updated = List<Point2D>.from(state.activeStrokePoints)..add(point);
    state = state.copyWith(activeStrokePoints: updated);
  }

  void finishStroke() {
    if (state.selectedTool != MarkupTool.pen || state.activeStrokePoints.isEmpty) {
      state = state.copyWith(activeStrokePoints: const []);
      return;
    }

    // Simplify points using Ramer-Douglas-Peucker algorithm
    final simplifiedPoints = StrokeSmoother.simplifyRDP(state.activeStrokePoints, epsilon: 0.0008);
    final newStroke = Stroke(
      points: simplifiedPoints,
      color: state.activeColor,
      strokeWidth: state.activeStrokeWidth,
    );

    final updatedStrokes = List<Stroke>.from(state.strokes)..add(newStroke);
    final undoList = List<List<Stroke>>.from(state.undoStack)..add(updatedStrokes);
    if (undoList.length > 30) undoList.removeAt(0);

    state = state.copyWith(
      strokes: updatedStrokes,
      activeStrokePoints: const [],
      undoStack: undoList,
      redoStack: const [],
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  // --- Undo & Redo ---


  void undo() {
    if (state.undoStack.length <= 1) return;
    final currentStrokes = state.undoStack.last;
    final newUndo = List<List<Stroke>>.from(state.undoStack)..removeLast();
    final prevStrokes = newUndo.last;
    final newRedo = List<List<Stroke>>.from(state.redoStack)..add(currentStrokes);

    state = state.copyWith(
      strokes: prevStrokes,
      undoStack: newUndo,
      redoStack: newRedo,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final nextStrokes = state.redoStack.last;
    final newRedo = List<List<Stroke>>.from(state.redoStack)..removeLast();
    final newUndo = List<List<Stroke>>.from(state.undoStack)..add(nextStrokes);

    state = state.copyWith(
      strokes: nextStrokes,
      undoStack: newUndo,
      redoStack: newRedo,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  // --- Autosave ---

  void _scheduleAutosave() {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 600), () {
      saveNow();
    });
  }

  void _scheduleAutosaveNow() {
    _autosaveDebounce?.cancel();
    saveNow();
  }

  Future<void> saveNow() async {
    if (!state.hasUnsavedChanges) return;
    state = state.copyWith(isAutosaving: true);
    try {
      final markup = PageMarkup(
        drawingId: state.drawing.id,
        pageNumber: state.currentPage,
        strokes: state.strokes,
        version: state.version,
        updatedAt: DateTime.now(),
      );
      await _repository.savePageMarkup(markup);
      state = state.copyWith(
        isAutosaving: false,
        hasUnsavedChanges: false,
        version: state.version + 1,
      );
    } catch (e) {
      debugPrint('Autosave error: $e');
      state = state.copyWith(isAutosaving: false);
    }
  }
}

final markupEditorControllerProvider =
    StateNotifierProvider.family<MarkupEditorController, MarkupEditorState, DrawingFile>((ref, drawing) {
  final repo = ref.watch(markupRepositoryProvider);
  return MarkupEditorController(repo, drawing);
});
