import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/markup.dart';
import '../../domain/models/measurement.dart';
import '../../domain/models/drawing_calibration.dart';
import '../../domain/utils/measurement_calculator.dart';
import '../../domain/utils/stroke_smoother.dart';
import '../../domain/repositories/markups_repository.dart';
import '../../domain/repositories/measurements_repository.dart';
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
  Color(0xFF0288D1), // Dimension Cyan
];

class DrawingViewerState {
  final String drawingId;
  final int currentPage;
  final int totalPages;
  final MarkupType? selectedTool; // null = Pan/Navigate mode
  final MeasurementType? selectedMeasurementTool;
  final Color currentColor;
  final Color? currentFillColor;
  final double strokeWidth;
  final double opacity;
  final double fontSize;
  final Set<DrawingLayer> visibleLayers;
  final List<Markup> markups;
  final List<Measurement> measurements;
  final DrawingCalibration? calibration;
  final bool isCalibrating;
  final List<Point2D> calibrationPoints;
  final String activeCountComponentName;
  final String? selectedMarkupId;
  final String? selectedMeasurementId;
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
  final List<List<Measurement>> measurementUndoStack;
  final List<Markup> clipboard;

  const DrawingViewerState({
    required this.drawingId,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedTool,
    this.selectedMeasurementTool,
    this.currentColor = const Color(0xFFD32F2F),
    this.currentFillColor,
    this.strokeWidth = 3.0,
    this.opacity = 1.0,
    this.fontSize = 13.0,
    this.visibleLayers = const {
      DrawingLayer.original,
      DrawingLayer.markup,
      DrawingLayer.measurement,
      DrawingLayer.issue,
      DrawingLayer.photo,
      DrawingLayer.inspection,
    },
    this.markups = const [],
    this.measurements = const [],
    this.calibration,
    this.isCalibrating = false,
    this.calibrationPoints = const [],
    this.activeCountComponentName = 'Valve',
    this.selectedMarkupId,
    this.selectedMeasurementId,
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
    this.measurementUndoStack = const [],
    this.clipboard = const [],
  });

  DrawingViewerState copyWith({
    String? drawingId,
    int? currentPage,
    int? totalPages,
    MarkupType? selectedTool,
    bool clearTool = false,
    MeasurementType? selectedMeasurementTool,
    bool clearMeasurementTool = false,
    Color? currentColor,
    Color? currentFillColor,
    bool clearFillColor = false,
    double? strokeWidth,
    double? opacity,
    double? fontSize,
    Set<DrawingLayer>? visibleLayers,
    List<Markup>? markups,
    List<Measurement>? measurements,
    DrawingCalibration? calibration,
    bool clearCalibration = false,
    bool? isCalibrating,
    List<Point2D>? calibrationPoints,
    String? activeCountComponentName,
    String? selectedMarkupId,
    bool clearSelectedMarkup = false,
    String? selectedMeasurementId,
    bool clearSelectedMeasurement = false,
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
    List<List<Measurement>>? measurementUndoStack,
    List<Markup>? clipboard,
  }) {
    return DrawingViewerState(
      drawingId: drawingId ?? this.drawingId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedTool: clearTool ? null : (selectedTool ?? this.selectedTool),
      selectedMeasurementTool: clearMeasurementTool ? null : (selectedMeasurementTool ?? this.selectedMeasurementTool),
      currentColor: currentColor ?? this.currentColor,
      currentFillColor: clearFillColor ? null : (currentFillColor ?? this.currentFillColor),
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      visibleLayers: visibleLayers ?? this.visibleLayers,
      markups: markups ?? this.markups,
      measurements: measurements ?? this.measurements,
      calibration: clearCalibration ? null : (calibration ?? this.calibration),
      isCalibrating: isCalibrating ?? this.isCalibrating,
      calibrationPoints: calibrationPoints ?? this.calibrationPoints,
      activeCountComponentName: activeCountComponentName ?? this.activeCountComponentName,
      selectedMarkupId: clearSelectedMarkup ? null : (selectedMarkupId ?? this.selectedMarkupId),
      selectedMeasurementId: clearSelectedMeasurement ? null : (selectedMeasurementId ?? this.selectedMeasurementId),
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
      measurementUndoStack: measurementUndoStack ?? this.measurementUndoStack,
      clipboard: clipboard ?? this.clipboard,
    );
  }

  List<Markup> get activePageMarkups =>
      markups.where((m) => m.pageNumber == currentPage).toList();

  List<Measurement> get activePageMeasurements =>
      measurements.where((m) => m.pageNumber == currentPage).toList();

  MeasurementType? get activeMeasurementType => selectedMeasurementTool;

  Color get activeColor => currentColor;

  String get activeCountLabel => activeCountComponentName;

  DrawingCalibration get effectiveCalibration =>
      calibration ?? DrawingCalibration.defaultScale(drawingId, pageNumber: currentPage);

  int getLayerCount(DrawingLayer layer) {
    if (layer == DrawingLayer.measurement) {
      return activePageMeasurements.length;
    }
    return markups.where((m) => m.layer == layer && m.pageNumber == currentPage).length;
  }
}

class MarkupController extends StateNotifier<DrawingViewerState> {
  final MarkupsRepository _markupsRepository;
  final MeasurementsRepository? _measurementsRepository;
  final String _drawingId;
  Timer? _autosaveTimer;
  final _uuid = const Uuid();

  MarkupController(
    this._markupsRepository,
    this._drawingId, {
    int totalPages = 1,
    MeasurementsRepository? measurementsRepository,
  })  : _measurementsRepository = measurementsRepository,
        super(DrawingViewerState(drawingId: _drawingId, totalPages: totalPages)) {
    loadAllData();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }

  Future<void> loadAllData() async {
    try {
      final markups = await _markupsRepository.getMarkupsForDrawing(_drawingId);
      List<Measurement> measurements = [];
      DrawingCalibration? calibration;

      if (_measurementsRepository != null) {
        measurements = await _measurementsRepository.getMeasurementsForDrawing(_drawingId);
        calibration = await _measurementsRepository.getCalibration(_drawingId, pageNumber: state.currentPage);
      }

      state = state.copyWith(
        markups: markups,
        measurements: measurements,
        calibration: calibration,
        undoStack: [markups],
        redoStack: [],
        measurementUndoStack: [measurements],
        hasUnsavedChanges: false,
        lastSavedTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error loading drawing data: $e');
    }
  }

  Future<void> loadMarkups() => loadAllData();

  void setPage(int page) async {
    if (page == state.currentPage) return;
    _scheduleAutosaveNow();

    DrawingCalibration? pageCalibration;
    if (_measurementsRepository != null) {
      pageCalibration = await _measurementsRepository.getCalibration(_drawingId, pageNumber: page);
    }

    state = state.copyWith(
      currentPage: page,
      calibration: pageCalibration,
      selectedMarkupId: null,
      selectedMeasurementId: null,
      clearSelectedMarkup: true,
      clearSelectedMeasurement: true,
      clearInProgress: true,
      isCalibrating: false,
      calibrationPoints: const [],
    );
  }

  void setTotalPages(int total) {
    state = state.copyWith(totalPages: total);
  }

  // --- Tool Selection ---

  void selectTool(MarkupType? tool) {
    if (tool == null) {
      state = state.copyWith(
        clearTool: true,
        clearMeasurementTool: true,
        isDrawingMode: false,
        clearSelectedMarkup: true,
        clearSelectedMeasurement: true,
        clearInProgress: true,
      );
    } else {
      state = state.copyWith(
        selectedTool: tool,
        clearMeasurementTool: true,
        isDrawingMode: true,
        clearSelectedMarkup: true,
        clearSelectedMeasurement: true,
        clearInProgress: true,
      );
    }
  }

  void selectMeasurementTool(MeasurementType? tool) {
    if (tool == null) {
      state = state.copyWith(
        clearMeasurementTool: true,
        isDrawingMode: false,
        clearInProgress: true,
      );
    } else {
      state = state.copyWith(
        selectedMeasurementTool: tool,
        clearTool: true,
        isDrawingMode: true,
        clearSelectedMarkup: true,
        clearSelectedMeasurement: true,
        clearInProgress: true,
      );
    }
  }

  void selectMeasurementType(MeasurementType type) => selectMeasurementTool(type);

  void startCountMode({required String label, required Color color}) {
    state = state.copyWith(
      selectedMeasurementTool: MeasurementType.count,
      activeCountComponentName: label,
      currentColor: color,
      clearTool: true,
      isDrawingMode: true,
      clearSelectedMarkup: true,
      clearSelectedMeasurement: true,
      clearInProgress: true,
    );
  }

  void toggleDrawingMode() {
    final newMode = !state.isDrawingMode;
    state = state.copyWith(
      isDrawingMode: newMode,
      selectedTool: newMode ? (state.selectedTool ?? MarkupType.pen) : null,
      clearTool: !newMode,
      clearMeasurementTool: !newMode,
      clearSelectedMarkup: true,
      clearSelectedMeasurement: true,
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

  // --- Part 1: Calibration Engine ---

  void startCalibration() {
    state = state.copyWith(
      isCalibrating: true,
      calibrationPoints: const [],
      clearTool: true,
      clearMeasurementTool: true,
      isDrawingMode: true,
    );
  }

  void cancelCalibration() {
    state = state.copyWith(
      isCalibrating: false,
      calibrationPoints: const [],
    );
  }

  void addCalibrationPoint(Point2D point) {
    final updated = List<Point2D>.from(state.calibrationPoints)..add(point);
    state = state.copyWith(calibrationPoints: updated);
  }

  Future<DrawingCalibration?> applyCalibration(
    double knownDistance,
    CalibrationUnit unit,
  ) async {
    if (state.calibrationPoints.length < 2) return null;

    final p1 = state.calibrationPoints[0];
    final p2 = state.calibrationPoints[1];

    final newCalibration = DrawingCalibration.fromPoints(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      point1: p1,
      point2: p2,
      knownDistance: knownDistance,
      unit: unit,
    );

    if (_measurementsRepository != null) {
      await _measurementsRepository.saveCalibration(newCalibration);
    }

    state = state.copyWith(
      calibration: newCalibration,
      isCalibrating: false,
      calibrationPoints: const [],
    );

    return newCalibration;
  }

  Future<DrawingCalibration?> completeCalibration({
    required double knownDistance,
    required CalibrationUnit unit,
  }) =>
      applyCalibration(knownDistance, unit);

  // --- Part 2 & Part 5: Drawing & Measurement Interaction ---

  void startDrawing(Point2D point) {
    if (state.isCalibrating) {
      addCalibrationPoint(point);
      return;
    }

    if (!state.isDrawingMode) return;

    if (state.selectedTool == MarkupType.eraser) {
      _eraseNear(point);
      return;
    }

    if (state.selectedMeasurementTool != null) {
      _handleMeasurementPointerDown(point);
      return;
    }

    if (state.selectedTool != null) {
      state = state.copyWith(
        inProgressPoints: [point],
        inProgressBounds: Rect.fromPoints(
          Offset(point.x, point.y),
          Offset(point.x, point.y),
        ),
      );
    }
  }

  void updateDrawing(Point2D point) {
    if (state.isCalibrating) return;
    if (!state.isDrawingMode) return;

    if (state.selectedTool == MarkupType.eraser) {
      _eraseNear(point);
      return;
    }

    if (state.selectedMeasurementTool != null) {
      _handleMeasurementPointerMove(point);
      return;
    }

    if (state.selectedTool != null) {
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
  }

  void finishDrawing({String? text, Map<String, dynamic>? metadata}) {
    if (state.isCalibrating) return;

    if (state.selectedMeasurementTool != null) {
      _handleMeasurementPointerUp();
      return;
    }

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

    List<Point2D> finalPoints = List<Point2D>.from(state.inProgressPoints);
    if ((tool == MarkupType.pen || tool == MarkupType.highlighter) && finalPoints.length > 3) {
      finalPoints = StrokeSmoother.simplifyRDP(finalPoints, epsilon: 0.0008);
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
      strokeWidth: tool == MarkupType.highlighter ? 20.0 : state.strokeWidth,
      opacity: tool == MarkupType.highlighter ? 0.38 : state.opacity,
      points: finalPoints,
      bounds: state.inProgressBounds,
      text: text,
      metadata: metadata,
      createdBy: 'Lead Field Engineer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pushUndoState();
    final updated = List<Markup>.from(state.markups)..add(newMarkup);
    state = state.copyWith(
      markups: updated,
      clearInProgress: true,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void _handleMeasurementPointerDown(Point2D point) {
    final type = state.selectedMeasurementTool!;
    if (type == MeasurementType.count) {
      _addCountMarker(point);
      return;
    }

    state = state.copyWith(
      inProgressPoints: [point],
    );
  }

  void _handleMeasurementPointerMove(Point2D point) {
    final type = state.selectedMeasurementTool!;
    if (type == MeasurementType.count) return;

    final updated = List<Point2D>.from(state.inProgressPoints)..add(point);
    state = state.copyWith(inProgressPoints: updated);
  }

  void _handleMeasurementPointerUp() {
    final type = state.selectedMeasurementTool!;
    final points = state.inProgressPoints;

    if (points.length < 2 && type != MeasurementType.count) {
      state = state.copyWith(clearInProgress: true);
      return;
    }

    final cal = state.effectiveCalibration;
    final calculatedValue = MeasurementCalculator.calculateValue(
      type: type,
      points: points,
      calibration: cal,
    );
    final unitStr = MeasurementCalculator.getUnitSymbol(type, cal);

    final newMeasurement = Measurement(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      type: type,
      points: List<Point2D>.from(points),
      calculatedValue: calculatedValue,
      unit: unitStr,
      color: state.currentColor,
      createdAt: DateTime.now(),
    );

    _pushMeasurementUndoState();
    final updated = List<Measurement>.from(state.measurements)..add(newMeasurement);
    state = state.copyWith(
      measurements: updated,
      clearInProgress: true,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void _addCountMarker(Point2D point) {
    final tag = state.activeCountComponentName;
    final existingCount = state.activePageMeasurements
        .where((m) => m.type == MeasurementType.count && m.label == tag)
        .length;

    final nextNumber = existingCount + 1;
    final formatted = '$tag #$nextNumber';

    final newMeasurement = Measurement(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      type: MeasurementType.count,
      points: [point],
      calculatedValue: nextNumber.toDouble(),
      unit: 'count',
      label: formatted,
      color: state.currentColor,
      metadata: {'componentName': tag, 'count': nextNumber},
      createdAt: DateTime.now(),
    );

    _pushMeasurementUndoState();
    final updated = List<Measurement>.from(state.measurements)..add(newMeasurement);
    state = state.copyWith(
      measurements: updated,
      hasUnsavedChanges: true,
    );
    _scheduleAutosave();
  }

  void deleteMeasurement(String id) {
    _pushMeasurementUndoState();
    final updated = state.measurements.where((m) => m.id != id).toList();
    if (_measurementsRepository != null) {
      _measurementsRepository.deleteMeasurement(id);
    }
    state = state.copyWith(measurements: updated, hasUnsavedChanges: true);
    _scheduleAutosave();
  }

  // --- Specialized Annotations ---

  void addTextCallout(
    Point2D position,
    String text, {
    double fontSize = 13.0,
    double rotation = 0.0,
    Point2D? leaderPoint,
    bool hasHalo = true,
  }) {
    final snappedRotation = StrokeSmoother.snapRotationRadians(rotation);
    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: DrawingLayer.markup,
      type: MarkupType.text,
      color: state.currentColor,
      fillColor: const Color(0xFF0F172A),
      strokeWidth: state.strokeWidth,
      opacity: state.opacity,
      points: [position],
      bounds: Rect.fromLTWH(position.x, position.y, 0.22, 0.05),
      text: text,
      fontSize: fontSize,
      rotation: snappedRotation,
      leaderPoint: leaderPoint,
      hasHalo: hasHalo,
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

  void updateMarkupStatus(String markupId, String status) {
    _pushUndoState();
    final updated = state.markups.map((m) {
      if (m.id == markupId) {
        return m.copyWith(status: status, updatedAt: DateTime.now());
      }
      return m;
    }).toList();

    state = state.copyWith(markups: updated, hasUnsavedChanges: true);
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

  void addPhotoPin(
    Point2D position, {
    String? photoUrl,
    String? photoPath,
    String? caption,
  }) {
    final finalUrl = photoPath ?? photoUrl ?? '';
    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: DrawingLayer.photo,
      type: MarkupType.photoPin,
      color: Colors.amber.shade800,
      strokeWidth: 2.0,
      opacity: 1.0,
      points: [position],
      bounds: Rect.fromLTWH(position.x - 0.015, position.y - 0.03, 0.03, 0.03),
      text: 'PHOTO',
      metadata: {'photoUrl': finalUrl, 'photoPath': finalUrl, 'caption': caption},
      createdBy: 'Lead Field Engineer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _pushUndoState();
    final updated = List<Markup>.from(state.markups)..add(newMarkup);
    state = state.copyWith(markups: updated, hasUnsavedChanges: true);
    _scheduleAutosave();
  }

  void addFieldStamp(Point2D position, String stampText, Color color) {
    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: DrawingLayer.inspection,
      type: MarkupType.stamp,
      color: color,
      fillColor: color.withOpacity(0.12),
      strokeWidth: 2.5,
      opacity: 1.0,
      points: [position],
      bounds: Rect.fromLTWH(position.x, position.y, 0.28, 0.06),
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

  void addEngineeringSymbol(
    Point2D position, {
    required String symbolId,
    String? name,
    required String tag,
    Color? color,
    double scale = 1.0,
    double rotation = 0.0,
    bool isStamp = false,
  }) {
    final symbolColor = color ?? state.currentColor;
    final newMarkup = Markup(
      id: _uuid.v4(),
      drawingId: _drawingId,
      pageNumber: state.currentPage,
      layer: isStamp ? DrawingLayer.inspection : DrawingLayer.markup,
      type: isStamp ? MarkupType.stamp : MarkupType.text,
      color: symbolColor,
      strokeWidth: state.strokeWidth,
      opacity: state.opacity,
      points: [position],
      bounds: Rect.fromLTWH(position.x, position.y, 0.08 * scale, 0.08 * scale),
      text: tag.isNotEmpty ? tag : (name ?? 'SYM'),
      rotation: rotation,
      metadata: {
        'symbolId': symbolId,
        'name': name,
        'tag': tag,
        'scale': scale,
        'rotation': rotation,
        'isSymbol': true,
        'isStamp': isStamp,
      },
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
      final shiftedLeader = m.leaderPoint != null
          ? Point2D(m.leaderPoint!.x + deltaNormalized.dx, m.leaderPoint!.y + deltaNormalized.dy)
          : null;
      return m.copyWith(
        points: shiftedPoints,
        bounds: shiftedBounds,
        leaderPoint: shiftedLeader,
        updatedAt: DateTime.now(),
      );
    });
  }

  void deleteSelectedMarkup() {
    if (state.selectedMarkupId == null) return;
    _pushUndoState();
    final updated = state.markups.where((m) => m.id != state.selectedMarkupId).toList();
    _markupsRepository.deleteMarkup(state.selectedMarkupId!);
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
    const offset = 0.02;

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
    _pushMeasurementUndoState();

    final remainingMarkups = state.markups.where((m) => m.pageNumber != state.currentPage).toList();
    final remainingMeasurements = state.measurements.where((m) => m.pageNumber != state.currentPage).toList();

    _markupsRepository.deleteMarkupsForDrawing(_drawingId, pageNumber: state.currentPage);
    if (_measurementsRepository != null) {
      _measurementsRepository.deleteMeasurementsForDrawing(_drawingId, pageNumber: state.currentPage);
    }

    state = state.copyWith(
      markups: remainingMarkups,
      measurements: remainingMeasurements,
      clearSelectedMarkup: true,
      clearSelectedMeasurement: true,
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
      redoStack: [],
    );
  }

  void _pushMeasurementUndoState() {
    final currentList = List<Measurement>.from(state.measurements);
    final undoList = List<List<Measurement>>.from(state.measurementUndoStack)..add(currentList);
    if (undoList.length > 30) undoList.removeAt(0);
    state = state.copyWith(measurementUndoStack: undoList);
  }

  void undo() {
    if (state.undoStack.isNotEmpty) {
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
    } else if (state.measurementUndoStack.isNotEmpty) {
      final prevMeasurements = state.measurementUndoStack.last;
      final newUndoStack = List<List<Measurement>>.from(state.measurementUndoStack)..removeLast();
      state = state.copyWith(
        measurements: prevMeasurements,
        measurementUndoStack: newUndoStack,
        hasUnsavedChanges: true,
      );
      _scheduleAutosave();
    }
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

  // --- High-Precision Stroke Eraser ---

  void _eraseNear(Point2D hit) {
    const threshold = 0.025; // 2.5% normalized radius
    final markupsOnPage = state.activePageMarkups;
    Markup? hitMarkup;

    for (final m in markupsOnPage.reversed) {
      if (StrokeSmoother.isMarkupHit(m, hit, threshold)) {
        hitMarkup = m;
        break;
      }
    }

    if (hitMarkup != null) {
      _pushUndoState();
      final updated = state.markups.where((m) => m.id != hitMarkup!.id).toList();
      _markupsRepository.deleteMarkup(hitMarkup.id);
      state = state.copyWith(markups: updated, hasUnsavedChanges: true);
      _scheduleAutosave();
      return;
    }

    // Check measurements for erasure
    for (final meas in state.activePageMeasurements.reversed) {
      for (final p in meas.points) {
        final dist = (p.x - hit.x).abs() + (p.y - hit.y).abs();
        if (dist < threshold) {
          deleteMeasurement(meas.id);
          return;
        }
      }
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
      await _markupsRepository.saveMarkupsBatch(state.markups);
      if (_measurementsRepository != null) {
        await _measurementsRepository.saveMeasurementsBatch(state.measurements);
      }
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
  final measRepo = ref.watch(measurementsRepositoryProvider);
  return MarkupController(repo, drawingId, measurementsRepository: measRepo);
});
