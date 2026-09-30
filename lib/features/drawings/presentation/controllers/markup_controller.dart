import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/markup.dart';
import '../../domain/repositories/markups_repository.dart';
import '../../../../core/providers/core_providers.dart';

const List<Color> kEngineeringColors = [
  Color(0xFFD32F2F), // Safety Red
  Color(0xFF2E7D32), // Field Green
  Color(0xFF1565C0), // P&ID Blue
  Color(0xFFFBC02D), // Warning Yellow
  Color(0xFF7B1FA2), // Instrument Purple
  Color(0xFF212121), // Carbon Black
  Color(0xFFFF6F00), // Hazard Orange
  Color(0xFF00838F), // Cyan / Process Line
];

class DrawingViewerState {
  final String drawingId;
  final int currentPage;
  final int totalPages;
  final MarkupType? selectedTool; // null = Pan/Navigate mode
  final Color currentColor;
  final Color? currentFillColor;
  final double strokeWidth;
  final double opacity;
  final double fontSize;
  final Set<DrawingLayer> visibleLayers;
  final List<Markup> markups;
  final String? selectedMarkupId;
  final Set<String> selectedMarkupIds;
  final List<Point2D> inProgressPoints;
  final Rect? inProgressBounds;
  final bool isDrawingMode;
  final bool isStylusOnly;
  final bool isFullscreen;
  final bool isAutosaving;
  final bool hasUnsavedChanges;
  final DateTime? lastSavedTime;
  final List<List<Markup>> undoStack;
  final List<List<Markup>> redoStack;
  final List<Markup> clipboard;

  const DrawingViewerState({
    required this.drawingId,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedTool,
    this.currentColor = const Color(0xFFD32F2F), // Default Red
    this.currentFillColor,
    this.strokeWidth = 3.0,
    this.opacity = 1.0,
    this.fontSize = 14.0,
    this.visibleLayers = const {
      DrawingLayer.original,
      DrawingLayer.markup,
      DrawingLayer.measurement,
      DrawingLayer.issue,
      DrawingLayer.photo,
    },
    this.markups = const [],
    this.selectedMarkupId,
    this.selectedMarkupIds = const {},
    this.inProgressPoints = const [],
    this.inProgressBounds,
    this.isDrawingMode = false,
    this.isStylusOnly = false,
    this.isFullscreen = false,
    this.isAutosaving = false,
    this.hasUnsavedChanges = false,
    this.lastSavedTime,
    this.undoStack = const [],
    this.redoStack = const [],
    this.clipboard = const [],
  });

  DrawingViewerState copyWith({
    String? drawingId,
    int? currentPage,
    int? totalPages,
    MarkupType? selectedTool,
    bool clearTool = false,
    Color? currentColor,
    Color? currentFillColor,
    bool clearFillColor = false,
    double? strokeWidth,
    double? opacity,
    double? fontSize,
    Set<DrawingLayer>? visibleLayers,
    List<Markup>? markups,
    String? selectedMarkupId,
    bool clearSelectedMarkup = false,
    Set<String>? selectedMarkupIds,
    List<Point2D>? inProgressPoints,
    Rect? inProgressBounds,
    bool clearInProgress = false,
    bool? isDrawingMode,
    bool? isStylusOnly,
    bool? isFullscreen,
    bool? isAutosaving,
    bool? hasUnsavedChanges,
    DateTime? lastSavedTime,
    List<List<Markup>>? undoStack,
    List<List<Markup>>? redoStack,
    List<Markup>? clipboard,
  }) {
    return DrawingViewerState(
      drawingId: drawingId ?? this.drawingId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedTool: clearTool ? null : (selectedTool ?? this.selectedTool),
      currentColor: currentColor ?? this.currentColor,
      currentFillColor: clearFillColor ? null : (currentFillColor ?? this.currentFillColor),
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      visibleLayers: visibleLayers ?? this.visibleLayers,
      markups: markups ?? this.markups,
      selectedMarkupId: clearSelectedMarkup ? null : (selectedMarkupId ?? this.selectedMarkupId),
      selectedMarkupIds: selectedMarkupIds ?? this.selectedMarkupIds,
      inProgressPoints: clearInProgress ? const [] : (inProgressPoints ?? this.inProgressPoints),
      inProgressBounds: clearInProgress ? null : (inProgressBounds ?? this.inProgressBounds),
      isDrawingMode: isDrawingMode ?? this.isDrawingMode,
      isStylusOnly: isStylusOnly ?? this.isStylusOnly,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isAutosaving: isAutosaving ?? this.isAutosaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastSavedTime: lastSavedTime ?? this.lastSavedTime,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      clipboard: clipboard ?? this.clipboard,
    );
  }

  List<Markup> get activePageMarkups =>
      markups.where((m) => m.pageNumber == currentPage).toList();

  int getLayerCount(DrawingLayer layer) =>
      markups.where((m) => m.layer == layer && m.pageNumber == currentPage).length;
}

class MarkupController extends StateNotifier<DrawingViewerState> {
  final MarkupsRepository _repository;
  final String _drawingId;
  Timer? _autosaveTimer;
  final _uuid = const Uuid();

  MarkupController(this._repository, this._drawingId, {int totalPages = 1})
      : super(DrawingViewerState(drawingId: _drawingId, totalPages: totalPages)) {
    loadMarkups();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMarkups() async {
    try {
      final markups = await _repository.getMarkupsForDrawing(_drawingId);
      state = state.copyWith(
        markups: markups,
        undoStack: [markups],
        redoStack: [],
        hasUnsavedChanges: false,
        lastSavedTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error loading markups: $e');
    }
  }

  void setPage(int page) {
    if (page == state.currentPage) return;
    _scheduleAutosaveNow();
    state = state.copyWith(
      currentPage: page,
      selectedMarkupId: null,
      clearSelectedMarkup: true,
      clearInProgress: true,
    );
  }

  void setTotalPages(int total) {
    state = state.copyWith(totalPages: total);
  }

  void selectTool(MarkupType? tool) {
    if (tool == null) {
      state = state.copyWith(
        clearTool: true,
        isDrawingMode: false,
        clearSelectedMarkup: true,
        clearInProgress: true,
      );
    } else {
      state = state.copyWith(
        selectedTool: tool,
        isDrawingMode: true,
        clearSelectedMarkup: true,
        clearInProgress: true,
      );
    }
  }

  void toggleDrawingMode() {
    final newMode = !state.isDrawingMode;
    state = state.copyWith(
      isDrawingMode: newMode,
      selectedTool: newMode ? (state.selectedTool ?? MarkupType.pen) : null,
      clearTool: !newMode,
      clearSelectedMarkup: true,
      clearInProgress: true,
    );
  }

  void setColor(Color color) {
    state = state.copyWith(currentColor: color);
    if (state.selectedMarkupId != null) {
      _updateSelectedMarkupProperty((m) => m.copyWith(color: color));
    }
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
    if (state.selectedMarkupId != null) {
      _updateSelectedMarkupProperty((m) => m.copyWith(strokeWidth: width));
    }
  }

  void setOpacity(double opacity) {
    state = state.copyWith(opacity: opacity);
    if (state.selectedMarkupId != null) {
      _updateSelectedMarkupProperty((m) => m.copyWith(opacity: opacity));
    }
  }

  void setFillColor(Color? fillColor) {
    state = state.copyWith(currentFillColor: fillColor);
    if (state.selectedMarkupId != null) {
      _updateSelectedMarkupProperty((m) => m.copyWith(fillColor: fillColor));
    }
  }

  void toggleLayer(DrawingLayer layer) {
    final updated = Set<DrawingLayer>.from(state.visibleLayers);
    if (updated.contains(layer)) {
      updated.remove(layer);
    } else {
      updated.add(layer);
    }
    state = state.copyWith(visibleLayers: updated);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void toggleStylusMode() {
    state = state.copyWith(isStylusOnly: !state.isStylusOnly);
  }

  // --- Drawing Interaction Hooks (Normalized Page Coordinates) ---

  void startDrawing(Point2D point) {
    if (!state.isDrawingMode || state.selectedTool == null) return;

    if (state.selectedTool == MarkupType.eraser) {
      _eraseNear(point);
      return;
    }

    state = state.copyWith(
      inProgressPoints: [point],
      inProgressBounds: Rect.fromPoints(
        Offset(point.x, point.y),
        Offset(point.x, point.y),
      ),
    );
  }

  void updateDrawing(Point2D point) {
    if (!state.isDrawingMode || state.selectedTool == null) return;

    if (state.selectedTool == MarkupType.eraser) {
      _eraseNear(point);
      return;
    }

    final points = List<Point2D>.from(state.inProgressPoints)..add(point);
    final start = points.first;
    final bounds = Rect.fromPoints(
      Offset(start.x, start.y),
      Offset(point.x, point.y),
    );

    state = state.copyWith(
      inProgressPoints: points,
      inProgressBounds: bounds,
    );
  }

  void finishDrawing({String? text, Map<String, dynamic>? metadata}) {
    if (!state.isDrawingMode || state.selectedTool == null || state.inProgressPoints.isEmpty) {
      state = state.copyWith(clearInProgress: true);
      return;
    }

    final tool = state.selectedTool!;
    if (tool == MarkupType.eraser) {
      state = state.copyWith(clearInProgress: true);
      return;
    }

    DrawingLayer layer = DrawingLayer.markup;
    if (tool == MarkupType.measurement) {
      layer = DrawingLayer.measurement;
    } else if (tool == MarkupType.issuePin) {
      layer = DrawingLayer.issue;
    } else if (tool == MarkupType.photoPin) {
      layer = DrawingLayer.photo;
    } else if (tool == MarkupType.stamp) {
      layer = DrawingLayer.inspection;
    }

    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: layer,
      type: tool,
      color: tool == MarkupType.highlighter
          ? state.currentColor.withOpacity(0.4)
          : state.currentColor,
      fillColor: state.currentFillColor,
      strokeWidth: tool == MarkupType.highlighter ? 18.0 : state.strokeWidth,
      opacity: tool == MarkupType.highlighter ? 0.45 : state.opacity,
      points: List<Point2D>.from(state.inProgressPoints),
      bounds: state.inProgressBounds,
      text: text,
      metadata: metadata,
      createdBy: 'Lead Field Engineer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pushUndoState();

    final updatedMarkups = List<Markup>.from(state.markups)..add(newMarkup);
    state = state.copyWith(
      markups: updatedMarkups,
      clearInProgress: true,
      hasUnsavedChanges: true,
    );

    _scheduleAutosave();
  }

  void addTextCallout(Point2D position, String text, {double fontSize = 14.0}) {
    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: DrawingLayer.markup,
      type: MarkupType.text,
      color: state.currentColor,
      fillColor: Colors.black.withOpacity(0.75),
      strokeWidth: state.strokeWidth,
      opacity: state.opacity,
      points: [position],
      bounds: Rect.fromLTWH(position.x, position.y, 0.25, 0.06),
      text: text,
      fontSize: fontSize,
      createdBy: 'Lead Field Engineer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pushUndoState();
    final updated = List<Markup>.from(state.markups)..add(newMarkup);
    state = state.copyWith(
      markups: updated,
      selectedMarkupId: newMarkup.id,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void addIssuePin(Point2D position, {required String issueTag, required String title}) {
    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: DrawingLayer.issue,
      type: MarkupType.issuePin,
      color: Colors.redAccent,
      strokeWidth: 2.0,
      opacity: 1.0,
      points: [position],
      bounds: Rect.fromLTWH(position.x - 0.015, position.y - 0.03, 0.03, 0.03),
      text: issueTag,
      metadata: {'title': title, 'status': 'OPEN', 'severity': 'HIGH'},
      createdBy: 'Lead Field Engineer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pushUndoState();
    final updated = List<Markup>.from(state.markups)..add(newMarkup);
    state = state.copyWith(markups: updated, hasUnsavedChanges: true);
    _scheduleAutosave();
  }

  void addPhotoPin(Point2D position, {required String photoPath, required String caption}) {
    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: DrawingLayer.photo,
      type: MarkupType.photoPin,
      color: Colors.amberAccent,
      strokeWidth: 2.0,
      opacity: 1.0,
      points: [position],
      bounds: Rect.fromLTWH(position.x - 0.015, position.y - 0.03, 0.03, 0.03),
      text: caption,
      metadata: {'photoPath': photoPath},
      createdBy: 'Lead Field Engineer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pushUndoState();
    final updated = List<Markup>.from(state.markups)..add(newMarkup);
    state = state.copyWith(markups: updated, hasUnsavedChanges: true);
    _scheduleAutosave();
  }

  void addFieldStamp(Point2D position, {required String stampText, required Color stampColor}) {
    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: DrawingLayer.inspection,
      type: MarkupType.stamp,
      color: stampColor,
      strokeWidth: 3.0,
      opacity: 0.9,
      points: [position],
      bounds: Rect.fromLTWH(position.x, position.y, 0.18, 0.08),
      text: stampText,
      createdBy: 'Lead Field Engineer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pushUndoState();
    final updated = List<Markup>.from(state.markups)..add(newMarkup);
    state = state.copyWith(markups: updated, hasUnsavedChanges: true);
    _scheduleAutosave();
  }

  // --- Selection & Transform Operations ---

  void selectMarkup(String? id) {
    state = state.copyWith(
      selectedMarkupId: id,
      clearSelectedMarkup: id == null,
    );
  }

  void moveSelectedMarkup(Offset deltaNormalized) {
    if (state.selectedMarkupId == null) return;
    _updateSelectedMarkupProperty((m) {
      final shiftedPoints = m.points.map((p) => Point2D(p.x + deltaNormalized.dx, p.y + deltaNormalized.dy)).toList();
      final shiftedBounds = m.bounds?.shift(deltaNormalized);
      return m.copyWith(
        points: shiftedPoints,
        bounds: shiftedBounds,
        updatedAt: DateTime.now(),
      );
    });
  }

  void deleteSelectedMarkup() {
    if (state.selectedMarkupId == null) return;
    _pushUndoState();
    final updated = state.markups.where((m) => m.id != state.selectedMarkupId).toList();
    _repository.deleteMarkup(state.selectedMarkupId!);
    state = state.copyWith(
      markups: updated,
      clearSelectedMarkup: true,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void copySelectedMarkup() {
    if (state.selectedMarkupId == null) return;
    final selected = state.markups.firstWhere((m) => m.id == state.selectedMarkupId);
    state = state.copyWith(clipboard: [selected]);
  }

  void pasteMarkup() {
    if (state.clipboard.isEmpty) return;
    final original = state.clipboard.first;
    const offset = 0.02; // Shift pasted item slightly

    final shiftedPoints = original.points.map((p) => Point2D(p.x + offset, p.y + offset)).toList();
    final shiftedBounds = original.bounds?.shift(const Offset(offset, offset));

    final pasted = original.copyWith(
      id: _uuid.v4(),
      pageNumber: state.currentPage,
      points: shiftedPoints,
      bounds: shiftedBounds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pushUndoState();
    final updated = List<Markup>.from(state.markups)..add(pasted);
    state = state.copyWith(
      markups: updated,
      selectedMarkupId: pasted.id,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void clearCurrentPageMarkups() {
    _pushUndoState();
    final remaining = state.markups.where((m) => m.pageNumber != state.currentPage).toList();
    _repository.deleteMarkupsForDrawing(_drawingId, pageNumber: state.currentPage);
    state = state.copyWith(
      markups: remaining,
      clearSelectedMarkup: true,
      hasUnsavedChanges: true,
    );
  }

  // --- Undo & Redo System ---

  void _pushUndoState() {
    final currentList = List<Markup>.from(state.markups);
    final undoList = List<List<Markup>>.from(state.undoStack)..add(currentList);
    if (undoList.length > 30) undoList.removeAt(0);
    state = state.copyWith(
      undoStack: undoList,
      redoStack: [], // Clear redo on new action
    );
  }

  void undo() {
    if (state.undoStack.isEmpty) return;
    final previousMarkups = state.undoStack.last;
    final newUndoStack = List<List<Markup>>.from(state.undoStack)..removeLast();
    final newRedoStack = List<List<Markup>>.from(state.redoStack)..add(List<Markup>.from(state.markups));

    state = state.copyWith(
      markups: previousMarkups,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      clearSelectedMarkup: true,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final nextMarkups = state.redoStack.last;
    final newRedoStack = List<List<Markup>>.from(state.redoStack)..removeLast();
    final newUndoStack = List<List<Markup>>.from(state.undoStack)..add(List<Markup>.from(state.markups));

    state = state.copyWith(
      markups: nextMarkups,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      clearSelectedMarkup: true,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  // --- Eraser Helper ---

  void _eraseNear(Point2D hit) {
    const threshold = 0.03; // In normalized page space
    final markupsOnPage = state.activePageMarkups;
    Markup? hitMarkup;

    for (final m in markupsOnPage.reversed) {
      if (m.bounds != null && m.bounds!.inflate(threshold).contains(Offset(hit.x, hit.y))) {
        hitMarkup = m;
        break;
      }
      for (final p in m.points) {
        final dist = (p.x - hit.x).abs() + (p.y - hit.y).abs();
        if (dist < threshold) {
          hitMarkup = m;
          break;
        }
      }
      if (hitMarkup != null) break;
    }

    if (hitMarkup != null) {
      _pushUndoState();
      final updated = state.markups.where((m) => m.id != hitMarkup!.id).toList();
      _repository.deleteMarkup(hitMarkup.id);
      state = state.copyWith(markups: updated, hasUnsavedChanges: true);
      _scheduleAutosave();
    }
  }

  void _updateSelectedMarkupProperty(Markup Function(Markup) updater) {
    final updated = state.markups.map((m) {
      if (m.id == state.selectedMarkupId) {
        return updater(m);
      }
      return m;
    }).toList();

    state = state.copyWith(markups: updated, hasUnsavedChanges: true);
    _scheduleAutosave();
  }

  // --- Autosave Engine ---

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 600), () {
      _saveToDatabase();
    });
  }

  void _scheduleAutosaveNow() {
    _autosaveTimer?.cancel();
    _saveToDatabase();
  }

  Future<void> _saveToDatabase() async {
    if (!state.hasUnsavedChanges) return;
    state = state.copyWith(isAutosaving: true);

    try {
      await _repository.saveMarkupsBatch(state.markups);
      state = state.copyWith(
        isAutosaving: false,
        hasUnsavedChanges: false,
        lastSavedTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Autosave failed: $e');
      state = state.copyWith(isAutosaving: false);
    }
  }
}

final markupControllerProvider =
    StateNotifierProvider.family<MarkupController, DrawingViewerState, String>((ref, drawingId) {
  final repo = ref.watch(markupsRepositoryProvider);
  return MarkupController(repo, drawingId);
});
