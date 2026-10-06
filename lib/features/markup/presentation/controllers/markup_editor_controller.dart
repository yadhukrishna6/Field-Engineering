import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/markup_layer.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/models/snap_config.dart';
import '../../domain/models/stroke.dart';
import '../../domain/models/text_label.dart';
import '../../domain/repositories/markup_repository.dart';
import '../../domain/utils/stroke_beautifier.dart';
import 'drawings_list_controller.dart';

enum MarkupTool {
  pen,
  marker,
  highlighter,
  text,
  shapes,
  photo,
  voiceNote,
  more,
  eraser,
}

class MarkupEditorState {
  final int currentPage;
  final List<AnnotationItem> annotations;
  final MarkupTool selectedTool;
  final AnnotationType selectedShape;
  final Color activeColor;
  final double activeStrokeWidth;
  final String activeLabelSize; // 'S' | 'M' | 'L'
  final MarkupLayer activeLayer;
  final Map<MarkupLayer, bool> layerVisibility;
  final SnapConfig snapConfig;
  final String? selectedAnnotationId;
  final bool isLayersPanelOpen;
  final bool isFullscreen;
  final double zoomLevel; // 1.0 = 100%
  final List<Point2D> activeStrokePoints;
  final List<Point2D>? snapGuideLine;
  final bool allowFingerDrawing;
  final bool canUndo;
  final bool canRedo;
  final bool isAutosaving;
  final bool hasUnsavedChanges;
  final String? lastSavedTimestamp;

  const MarkupEditorState({
    required this.currentPage,
    this.annotations = const [],
    this.selectedTool = MarkupTool.pen,
    this.selectedShape = AnnotationType.line,
    this.activeColor = AppColors.inkRed,
    this.activeStrokeWidth = 3.0,
    this.activeLabelSize = 'M',
    this.activeLayer = MarkupLayer.markups,
    this.layerVisibility = const {},
    this.snapConfig = const SnapConfig(),
    this.selectedAnnotationId,
    this.isLayersPanelOpen = false,
    this.isFullscreen = false,
    this.zoomLevel = 1.0,
    this.activeStrokePoints = const [],
    this.snapGuideLine,
    this.allowFingerDrawing = true,
    this.canUndo = false,
    this.canRedo = false,
    this.isAutosaving = false,
    this.hasUnsavedChanges = false,
    this.lastSavedTimestamp,
  });

  // Backward compatibility getters
  List<Stroke> get strokes => annotations
      .where((a) => a.type != AnnotationType.text && a.type != AnnotationType.photoPin && a.type != AnnotationType.voicePin)
      .map((a) => Stroke(points: a.points, color: a.color, strokeWidth: a.strokeWidth))
      .toList();

  List<TextLabel> get labels => annotations
      .where((a) => a.type == AnnotationType.text)
      .map((a) => TextLabel(
            id: a.id,
            text: a.text ?? '',
            x: a.points.isNotEmpty ? a.points.first.x : 0.0,
            y: a.points.isNotEmpty ? a.points.first.y : 0.0,
            size: a.size ?? 'M',
            color: a.color,
          ))
      .toList();

  String? get selectedLabelId => selectedAnnotationId;

  MarkupEditorState copyWith({
    int? currentPage,
    List<AnnotationItem>? annotations,
    MarkupTool? selectedTool,
    AnnotationType? selectedShape,
    Color? activeColor,
    double? activeStrokeWidth,
    String? activeLabelSize,
    MarkupLayer? activeLayer,
    Map<MarkupLayer, bool>? layerVisibility,
    SnapConfig? snapConfig,
    String? selectedAnnotationId,
    bool? isLayersPanelOpen,
    bool? isFullscreen,
    double? zoomLevel,
    List<Point2D>? activeStrokePoints,
    List<Point2D>? snapGuideLine,
    bool? allowFingerDrawing,
    bool? canUndo,
    bool? canRedo,
    bool? isAutosaving,
    bool? hasUnsavedChanges,
    String? lastSavedTimestamp,
    bool clearSelectedId = false,
    bool clearSnapGuide = false,
  }) {
    return MarkupEditorState(
      currentPage: currentPage ?? this.currentPage,
      annotations: annotations ?? this.annotations,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedShape: selectedShape ?? this.selectedShape,
      activeColor: activeColor ?? this.activeColor,
      activeStrokeWidth: activeStrokeWidth ?? this.activeStrokeWidth,
      activeLabelSize: activeLabelSize ?? this.activeLabelSize,
      activeLayer: activeLayer ?? this.activeLayer,
      layerVisibility: layerVisibility ?? this.layerVisibility,
      snapConfig: snapConfig ?? this.snapConfig,
      selectedAnnotationId: clearSelectedId ? null : (selectedAnnotationId ?? this.selectedAnnotationId),
      isLayersPanelOpen: isLayersPanelOpen ?? this.isLayersPanelOpen,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      activeStrokePoints: activeStrokePoints ?? this.activeStrokePoints,
      snapGuideLine: clearSnapGuide ? null : (snapGuideLine ?? this.snapGuideLine),
      allowFingerDrawing: allowFingerDrawing ?? this.allowFingerDrawing,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isAutosaving: isAutosaving ?? this.isAutosaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastSavedTimestamp: lastSavedTimestamp ?? this.lastSavedTimestamp,
    );
  }
}

class MarkupEditorController extends StateNotifier<MarkupEditorState> {
  final MarkupRepository _repository;
  final DrawingFile _drawing;

  final List<List<AnnotationItem>> _undoStack = [];
  final List<List<AnnotationItem>> _redoStack = [];

  Timer? _autosaveDebounce;
  Timer? _holdToBeautifyTimer;

  MarkupEditorController(this._repository, this._drawing)
      : super(MarkupEditorState(
          currentPage: 1,
          layerVisibility: {for (final l in MarkupLayer.values) l: true},
        )) {
    _loadPageMarkup(1);
  }

  Future<void> _loadPageMarkup(int page) async {
    final pageMarkup = await _repository.getPageMarkup(_drawing.id, page);
    final initialAnnotations = pageMarkup.annotations;

    _undoStack.clear();
    _redoStack.clear();

    state = state.copyWith(
      currentPage: page,
      annotations: initialAnnotations,
      canUndo: false,
      canRedo: false,
      hasUnsavedChanges: false,
      clearSelectedId: true,
      clearSnapGuide: true,
    );
  }

  void _pushUndoSnapshot() {
    _undoStack.add(List.from(state.annotations));
    _redoStack.clear();
    state = state.copyWith(canUndo: true, canRedo: false, hasUnsavedChanges: true);
    _triggerAutosave();
  }

  void selectTool(MarkupTool tool) {
    state = state.copyWith(
      selectedTool: tool,
      clearSelectedId: tool != MarkupTool.text,
      clearSnapGuide: true,
    );
  }

  void selectShape(AnnotationType shape) {
    state = state.copyWith(
      selectedTool: MarkupTool.shapes,
      selectedShape: shape,
    );
  }

  void setColor(Color color) {
    state = state.copyWith(activeColor: color);
    if (state.selectedAnnotationId != null) {
      final index = state.annotations.indexWhere((a) => a.id == state.selectedAnnotationId);
      if (index != -1) {
        _pushUndoSnapshot();
        final updated = List<AnnotationItem>.from(state.annotations);
        updated[index] = updated[index].copyWith(color: color);
        state = state.copyWith(annotations: updated);
      }
    }
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(activeStrokeWidth: width);
  }

  void setLabelSize(String size) {
    state = state.copyWith(activeLabelSize: size);
  }

  void setSnapConfig(SnapConfig config) {
    state = state.copyWith(snapConfig: config);
  }

  void toggleLayer(MarkupLayer layer) {
    final updated = Map<MarkupLayer, bool>.from(state.layerVisibility);
    updated[layer] = !(updated[layer] ?? true);
    state = state.copyWith(layerVisibility: updated);
  }

  void toggleLayersPanel() {
    state = state.copyWith(isLayersPanelOpen: !state.isLayersPanelOpen);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom);
  }

  void toggleFingerDrawing() {
    state = state.copyWith(allowFingerDrawing: !state.allowFingerDrawing);
  }

  void selectAnnotation(String? id) {
    state = state.copyWith(
      selectedAnnotationId: id,
      clearSelectedId: id == null,
    );
  }

  void selectLabel(String? id) => selectAnnotation(id);

  // --- Inking & Beautification Engine ---

  void startStroke(Point2D p) {
    state = state.copyWith(
      activeStrokePoints: [p],
      clearSnapGuide: true,
    );

    _holdToBeautifyTimer?.cancel();
    // 500ms hold at the end of stroke auto-triggers beautification preview
    _holdToBeautifyTimer = Timer(const Duration(milliseconds: 500), () {
      _computeLiveSnapGuide();
    });
  }

  void appendStrokePoint(Point2D p) {
    final updated = List<Point2D>.from(state.activeStrokePoints)..add(p);
    state = state.copyWith(activeStrokePoints: updated);

    _holdToBeautifyTimer?.cancel();
    _holdToBeautifyTimer = Timer(const Duration(milliseconds: 500), () {
      _computeLiveSnapGuide();
    });
  }

  void _computeLiveSnapGuide() {
    if (state.activeStrokePoints.length < 2 || !state.snapConfig.isEnabled) return;

    final start = state.activeStrokePoints.first;
    final end = state.activeStrokePoints.last;
    final snapped = StrokeBeautifier.snapAngle(
      origin: start,
      target: end,
      axisSet: state.snapConfig.axisSet,
      toleranceDegrees: state.snapConfig.angleToleranceDegrees,
    );

    if (snapped.x != end.x || snapped.y != end.y) {
      HapticFeedback.selectionClick();
      state = state.copyWith(snapGuideLine: [start, snapped]);
    }
  }

  void finishStroke() {
    _holdToBeautifyTimer?.cancel();
    if (state.activeStrokePoints.isEmpty) return;

    _pushUndoSnapshot();

    AnnotationType? forcedType;
    if (state.selectedTool == MarkupTool.marker) forcedType = AnnotationType.marker;
    if (state.selectedTool == MarkupTool.highlighter) forcedType = AnnotationType.highlighter;
    if (state.selectedTool == MarkupTool.shapes) forcedType = state.selectedShape;

    final beautified = StrokeBeautifier.beautify(
      rawPoints: state.activeStrokePoints,
      color: state.activeColor,
      strokeWidth: state.activeStrokeWidth,
      snapConfig: state.snapConfig,
      layer: state.activeLayer,
      forcedType: forcedType,
    );

    if (beautified.didSnap) {
      HapticFeedback.lightImpact();
    }

    final newAnnotation = AnnotationItem(
      id: 'ann-${DateTime.now().microsecondsSinceEpoch}',
      type: beautified.type,
      layer: state.activeLayer,
      color: state.activeColor,
      strokeWidth: state.activeStrokeWidth,
      points: beautified.points,
      rawPoints: beautified.didSnap ? state.activeStrokePoints : null,
      metadata: beautified.metadata,
    );

    final updatedAnnotations = List<AnnotationItem>.from(state.annotations)..add(newAnnotation);

    state = state.copyWith(
      annotations: updatedAnnotations,
      activeStrokePoints: const [],
      clearSnapGuide: true,
    );
  }

  // --- Whole Item Eraser ---

  bool eraseAt(Point2D hitPoint) {
    int hitIndex = -1;

    for (int i = state.annotations.length - 1; i >= 0; i--) {
      final ann = state.annotations[i];
      if (state.layerVisibility[ann.layer] == false) continue;

      if (_isAnnotationHit(ann, hitPoint)) {
        hitIndex = i;
        break;
      }
    }

    if (hitIndex != -1) {
      _pushUndoSnapshot();
      final updated = List<AnnotationItem>.from(state.annotations)..removeAt(hitIndex);
      state = state.copyWith(
        annotations: updated,
        clearSelectedId: true,
      );
      HapticFeedback.selectionClick();
      return true;
    }
    return false;
  }

  bool _isAnnotationHit(AnnotationItem ann, Point2D p) {
    if (ann.points.isEmpty) return false;

    if (ann.type == AnnotationType.text || ann.type == AnnotationType.callout) {
      final origin = ann.points.first;
      return (p.x >= origin.x - 0.04 && p.x <= origin.x + 0.18 &&
              p.y >= origin.y - 0.04 && p.y <= origin.y + 0.08);
    }

    for (int i = 0; i < ann.points.length; i++) {
      if ((p.x - ann.points[i].x).abs() < 0.025 && (p.y - ann.points[i].y).abs() < 0.025) {
        return true;
      }
    }

    for (int i = 0; i < ann.points.length - 1; i++) {
      final p1 = ann.points[i];
      final p2 = ann.points[i + 1];
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;
      final lenSq = dx * dx + dy * dy;
      if (lenSq == 0) continue;

      final t = (((p.x - p1.x) * dx + (p.y - p1.y) * dy) / lenSq).clamp(0.0, 1.0);
      final projX = p1.x + t * dx;
      final projY = p1.y + t * dy;
      final dist = (p.x - projX) * (p.x - projX) + (p.y - projY) * (p.y - projY);

      if (dist < 0.0006) return true;
    }

    return false;
  }

  // --- Text Labels ---

  void addLabel({
    required String text,
    required double x,
    required double y,
    String size = 'M',
    Color? color,
  }) {
    _pushUndoSnapshot();
    final newAnnotation = AnnotationItem(
      id: 'lbl-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.text,
      layer: state.activeLayer,
      color: color ?? state.activeColor,
      strokeWidth: 1.5,
      points: [Point2D(x, y)],
      text: text,
      size: size,
    );

    final updated = List<AnnotationItem>.from(state.annotations)..add(newAnnotation);
    state = state.copyWith(
      annotations: updated,
      selectedAnnotationId: newAnnotation.id,
    );
  }

  void moveAnnotation(String id, Point2D newPos) {
    final index = state.annotations.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final item = state.annotations[index];
    final updated = List<AnnotationItem>.from(state.annotations);

    if (item.type == AnnotationType.text || item.points.length == 1) {
      updated[index] = item.copyWith(points: [newPos]);
    } else if (item.points.isNotEmpty) {
      final origin = item.points.first;
      final dx = newPos.x - origin.x;
      final dy = newPos.y - origin.y;
      final shifted = item.points.map((p) => Point2D((p.x + dx).clamp(0.0, 1.0), (p.y + dy).clamp(0.0, 1.0))).toList();
      updated[index] = item.copyWith(points: shifted);
    }

    state = state.copyWith(annotations: updated);
  }

  void moveLabel(String id, Point2D newPos) => moveAnnotation(id, newPos);

  void finishMoveLabel() {
    _triggerAutosave();
    state = state.copyWith(hasUnsavedChanges: true, canUndo: true);
  }

  void deleteSelectedLabel() {
    if (state.selectedAnnotationId == null) return;
    _pushUndoSnapshot();
    final updated = state.annotations.where((a) => a.id != state.selectedAnnotationId).toList();
    state = state.copyWith(
      annotations: updated,
      clearSelectedId: true,
    );
  }

  // --- Undo & Redo (Supports Single-Tap "Undo Snap") ---

  void undo() {
    if (_undoStack.isEmpty) return;

    // Check if the last annotation was snapped and can be restored to raw points
    if (state.annotations.isNotEmpty && state.annotations.last.rawPoints != null) {
      _redoStack.add(List.from(state.annotations));
      final last = state.annotations.last;
      final restored = last.copyWith(
        type: AnnotationType.stroke,
        points: last.rawPoints,
        clearRawPoints: true,
      );
      final updated = List<AnnotationItem>.from(state.annotations)..removeLast()..add(restored);

      state = state.copyWith(
        annotations: updated,
        canUndo: true,
        canRedo: true,
      );
      _triggerAutosave();
      return;
    }

    _redoStack.add(List.from(state.annotations));
    final previous = _undoStack.removeLast();

    state = state.copyWith(
      annotations: previous,
      canUndo: _undoStack.isNotEmpty,
      canRedo: true,
      clearSelectedId: true,
    );

    _triggerAutosave();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add(List.from(state.annotations));
    final next = _redoStack.removeLast();

    state = state.copyWith(
      annotations: next,
      canUndo: true,
      canRedo: _redoStack.isNotEmpty,
      clearSelectedId: true,
    );

    _triggerAutosave();
  }

  void setPage(int page) {
    if (page == state.currentPage) return;
    saveNow();
    _loadPageMarkup(page);
  }

  void _triggerAutosave() {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 500), () {
      saveNow();
    });
  }

  Future<void> saveNow() async {
    state = state.copyWith(isAutosaving: true);
    final pageMarkup = PageMarkup(
      drawingId: _drawing.id,
      pageNumber: state.currentPage,
      annotations: state.annotations,
      updatedAt: DateTime.now(),
    );

    await _repository.savePageMarkup(pageMarkup);

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    state = state.copyWith(
      isAutosaving: false,
      hasUnsavedChanges: false,
      lastSavedTimestamp: timeStr,
    );
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    _holdToBeautifyTimer?.cancel();
    super.dispose();
  }
}

final markupEditorControllerProvider = StateNotifierProvider.autoDispose.family<
    MarkupEditorController, MarkupEditorState, DrawingFile>(
  (ref, drawing) {
    final repo = ref.watch(markupRepositoryProvider);
    return MarkupEditorController(repo, drawing);
  },
);
