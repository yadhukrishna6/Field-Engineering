import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/models/stroke.dart';
import '../../domain/models/text_label.dart';
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

enum MarkupTool { pen, text, eraser }

/// Snapshot representing drawing markups state for undo/redo
class MarkupSnapshot {
  final List<Stroke> strokes;
  final List<TextLabel> labels;

  const MarkupSnapshot({
    required this.strokes,
    required this.labels,
  });
}

class MarkupEditorState {
  final DrawingFile drawing;
  final int currentPage;
  final MarkupTool selectedTool;
  final Color activeColor;
  final double activeStrokeWidth;
  final String activeLabelSize; // 'S' | 'M' | 'L'
  final List<Stroke> strokes;
  final List<TextLabel> labels;
  final String? selectedLabelId;
  final List<Point2D> activeStrokePoints;
  final List<MarkupSnapshot> undoStack;
  final List<MarkupSnapshot> redoStack;
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
    this.activeLabelSize = 'M',
    this.strokes = const [],
    this.labels = const [],
    this.selectedLabelId,
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
    String? activeLabelSize,
    List<Stroke>? strokes,
    List<TextLabel>? labels,
    String? selectedLabelId,
    bool clearSelectedLabel = false,
    List<Point2D>? activeStrokePoints,
    List<MarkupSnapshot>? undoStack,
    List<MarkupSnapshot>? redoStack,
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
      activeLabelSize: activeLabelSize ?? this.activeLabelSize,
      strokes: strokes ?? this.strokes,
      labels: labels ?? this.labels,
      selectedLabelId: clearSelectedLabel ? null : (selectedLabelId ?? this.selectedLabelId),
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
    final initialSnapshot = MarkupSnapshot(
      strokes: markup.strokes,
      labels: markup.labels,
    );

    state = state.copyWith(
      currentPage: pageNumber,
      strokes: markup.strokes,
      labels: markup.labels,
      selectedLabelId: null,
      clearSelectedLabel: true,
      activeStrokePoints: const [],
      undoStack: [initialSnapshot],
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
    state = state.copyWith(
      selectedTool: tool,
      clearSelectedLabel: tool != MarkupTool.text,
    );
  }

  void setColor(Color color) {
    state = state.copyWith(activeColor: color);
    // If a label is currently selected in text mode, update its color
    if (state.selectedTool == MarkupTool.text && state.selectedLabelId != null) {
      final updatedLabels = state.labels.map((l) {
        if (l.id == state.selectedLabelId) {
          return l.copyWith(color: color);
        }
        return l;
      }).toList();
      _pushSnapshot(state.strokes, updatedLabels);
    }
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(activeStrokeWidth: width);
  }

  void setLabelSize(String size) {
    state = state.copyWith(activeLabelSize: size);
    // If a label is currently selected in text mode, update its size
    if (state.selectedTool == MarkupTool.text && state.selectedLabelId != null) {
      final updatedLabels = state.labels.map((l) {
        if (l.id == state.selectedLabelId) {
          return l.copyWith(size: size);
        }
        return l;
      }).toList();
      _pushSnapshot(state.strokes, updatedLabels);
    }
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
    state = state.copyWith(activeStrokePoints: const []);
    _pushSnapshot(updatedStrokes, state.labels);
  }

  // --- Text Label Actions ---

  void addLabel({
    required String text,
    required double x,
    required double y,
    String? size,
    Color? color,
  }) {
    final labelId = 'lbl-';
    final newLabel = TextLabel(
      id: labelId,
      text: text,
      x: x.clamp(0.0, 0.95),
      y: y.clamp(0.0, 0.95),
      size: size ?? state.activeLabelSize,
      color: color ?? state.activeColor,
    );

    final updatedLabels = List<TextLabel>.from(state.labels)..add(newLabel);
    state = state.copyWith(selectedLabelId: labelId);
    _pushSnapshot(state.strokes, updatedLabels);
  }

  void selectLabel(String? id) {
    state = state.copyWith(
      selectedLabelId: id,
      clearSelectedLabel: id == null,
    );
  }

  void moveLabel(String id, Point2D newPosition) {
    final updatedLabels = state.labels.map((l) {
      if (l.id == id) {
        return l.copyWith(
          x: newPosition.x.clamp(0.0, 0.95),
          y: newPosition.y.clamp(0.0, 0.95),
        );
      }
      return l;
    }).toList();

    state = state.copyWith(labels: updatedLabels, hasUnsavedChanges: true);
    _scheduleAutosave();
  }

  void finishMoveLabel() {
    _pushSnapshot(state.strokes, state.labels);
  }

  void deleteLabel(String id) {
    final updatedLabels = state.labels.where((l) => l.id != id).toList();
    state = state.copyWith(
      clearSelectedLabel: state.selectedLabelId == id,
    );
    _pushSnapshot(state.strokes, updatedLabels);
  }

  void deleteSelectedLabel() {
    if (state.selectedLabelId == null) return;
    deleteLabel(state.selectedLabelId!);
  }

  // --- Whole Item Eraser ---

  bool eraseAt(Point2D hitPoint) {
    bool erasedAny = false;

    // 1. Check labels hit (in reverse order for top-most first)
    final remainingLabels = <TextLabel>[];
    for (int i = state.labels.length - 1; i >= 0; i--) {
      final label = state.labels[i];
      if (!erasedAny && StrokeSmoother.isLabelHit(label, hitPoint)) {
        erasedAny = true;
        // Erased this label
      } else {
        remainingLabels.insert(0, label);
      }
    }

    if (erasedAny) {
      state = state.copyWith(clearSelectedLabel: true);
      _pushSnapshot(state.strokes, remainingLabels);
      return true;
    }

    // 2. Check strokes hit (in reverse order for top-most first)
    final remainingStrokes = <Stroke>[];
    for (int i = state.strokes.length - 1; i >= 0; i--) {
      final stroke = state.strokes[i];
      if (!erasedAny && StrokeSmoother.isStrokeHit(stroke, hitPoint, threshold: 0.025)) {
        erasedAny = true;
        // Erased this stroke
      } else {
        remainingStrokes.insert(0, stroke);
      }
    }

    if (erasedAny) {
      _pushSnapshot(remainingStrokes, state.labels);
      return true;
    }

    return false;
  }

  // --- Snapshot & History Management ---

  void _pushSnapshot(List<Stroke> newStrokes, List<TextLabel> newLabels) {
    final snapshot = MarkupSnapshot(
      strokes: List.unmodifiable(newStrokes),
      labels: List.unmodifiable(newLabels),
    );

    final updatedUndo = List<MarkupSnapshot>.from(state.undoStack)..add(snapshot);
    if (updatedUndo.length > 30) {
      updatedUndo.removeAt(0);
    }

    state = state.copyWith(
      strokes: newStrokes,
      labels: newLabels,
      undoStack: updatedUndo,
      redoStack: const [],
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  // --- Undo & Redo ---

  void undo() {
    if (state.undoStack.length <= 1) return;
    final current = state.undoStack.last;
    final newUndo = List<MarkupSnapshot>.from(state.undoStack)..removeLast();
    final prev = newUndo.last;
    final newRedo = List<MarkupSnapshot>.from(state.redoStack)..add(current);

    state = state.copyWith(
      strokes: prev.strokes,
      labels: prev.labels,
      clearSelectedLabel: true,
      undoStack: newUndo,
      redoStack: newRedo,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final next = state.redoStack.last;
    final newRedo = List<MarkupSnapshot>.from(state.redoStack)..removeLast();
    final newUndo = List<MarkupSnapshot>.from(state.undoStack)..add(next);

    state = state.copyWith(
      strokes: next.strokes,
      labels: next.labels,
      clearSelectedLabel: true,
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
        labels: state.labels,
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
      debugPrint('Autosave error: ');
      state = state.copyWith(isAutosaving: false);
    }
  }
}

final markupEditorControllerProvider =
    StateNotifierProvider.family<MarkupEditorController, MarkupEditorState, DrawingFile>((ref, drawing) {
  final repo = ref.watch(markupRepositoryProvider);
  return MarkupEditorController(repo, drawing);
});
