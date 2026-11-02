import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/local/offline_sync_queue.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/drawing_text_token.dart';
import '../../domain/models/markup_layer.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/models/snap_config.dart';
import '../../domain/models/stroke.dart';
import '../../domain/models/text_label.dart';
import '../../domain/repositories/markup_repository.dart';
import '../../domain/utils/stroke_beautifier.dart';
import '../widgets/quick_notes_sheet.dart';
import '../widgets/stamps_sheet.dart';
import 'drawings_list_controller.dart';

enum MarkupTool {
  pen,
  marker,
  highlighter,
  text,
  quickNote,
  strikeOut,
  noteBox,
  stamp,
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
  final QuickNoteType? activeQuickNoteType;
  final StampType? activeStampType;
  final Color activeColor;
  final double activeStrokeWidth;
  final String activeLabelSize;
  final MarkupLayer activeLayer;
  final Map<MarkupLayer, bool> layerVisibility;
  final SnapConfig snapConfig;
  final String? selectedAnnotationId;
  final bool isLayersPanelOpen;
  final bool isFullscreen;
  final double zoomLevel;
  final List<Point2D> activeStrokePoints;
  final List<Point2D>? snapGuideLine;
  final bool allowFingerDrawing;
  final bool canUndo;
  final bool canRedo;
  final bool isAutosaving;
  final bool hasUnsavedChanges;
  final String? lastSavedTimestamp;
  final bool isWipeLocked;
  final bool autoLockedDueToPalm;
  final bool isGloveMode;

  // Phase C: In-drawing text search & highlights
  final bool isSearchOpen;
  final DrawingTextToken? searchHighlightToken;

  // Phase D: Review, Multi-User, Audit & Control
  final String currentUser;
  final Set<String> visibleAuthorFilters;
  final bool isAdmin;
  final bool isApproved;

  // Job Number configuration (standard prefix + dynamic 3-digit suffix)
  final String jobPrefix;
  final String jobSuffix;

  // Font & Typography configuration (downloaded handwriting & CAD fonts)
  final String activeFontFamily;
  final String activeTextAlignment;

  String get fullJobNumber => '$jobPrefix$jobSuffix';

  const MarkupEditorState({
    this.currentPage = 1,
    this.annotations = const [],
    this.selectedTool = MarkupTool.pen,
    this.selectedShape = AnnotationType.line,
    this.activeQuickNoteType,
    this.activeStampType,
    this.activeColor = const Color(0xFFD03A33),
    this.activeStrokeWidth = 3.0,
    this.activeLabelSize = 'M',
    this.activeLayer = MarkupLayer.markups,
    this.layerVisibility = const {
      MarkupLayer.originalDrawing: true,
      MarkupLayer.markups: true,
      MarkupLayer.measurements: true,
      MarkupLayer.issues: true,
      MarkupLayer.photos: true,
      MarkupLayer.inspection: true,
      MarkupLayer.previousRevision: false,
    },
    this.snapConfig = const SnapConfig(isEnabled: true, axisSet: SnapAxisSet.isometric),
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
    this.isWipeLocked = false,
    this.autoLockedDueToPalm = false,
    this.isGloveMode = false,
    this.isSearchOpen = false,
    this.searchHighlightToken,
    this.currentUser = 'Field Engineer',
    this.visibleAuthorFilters = const {},
    this.isAdmin = false,
    this.isApproved = false,
    this.jobPrefix = 'JOB-2026-',
    this.jobSuffix = '001',
    this.activeFontFamily = 'architectural',
    this.activeTextAlignment = 'left',
  });

  bool get isReadOnly => isApproved && !isAdmin;

  bool isAuthorVisible(String? author) {
    if (visibleAuthorFilters.isEmpty) return true;
    if (author == null || author.isEmpty) return visibleAuthorFilters.contains(currentUser);
    return visibleAuthorFilters.contains(author);
  }

  List<String> get availableAuthors {
    final authors = <String>{currentUser};
    for (final a in annotations) {
      if (a.author != null && a.author!.isNotEmpty) {
        authors.add(a.author!);
      }
    }
    return authors.toList()..sort();
  }

  List<AnnotationItem> get visibleAnnotations =>
      annotations.where((a) => !a.isConflictCopy && (layerVisibility[a.layer] ?? true) && isAuthorVisible(a.author)).toList();

  List<AnnotationItem> get conflictCopies =>
      annotations.where((a) => a.isConflictCopy).toList();

  List<Stroke> get strokes => visibleAnnotations
      .where((a) => a.type != AnnotationType.text && a.type != AnnotationType.noteBox && a.type != AnnotationType.stamp && a.type != AnnotationType.photoPin)
      .map((a) => Stroke(points: a.points, color: a.color, strokeWidth: a.strokeWidth))
      .toList();

  List<TextLabel> get labels => visibleAnnotations
      .where((a) => a.type == AnnotationType.text || a.type == AnnotationType.noteBox)
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
    QuickNoteType? activeQuickNoteType,
    StampType? activeStampType,
    Color? activeColor,
    double? activeStrokeWidth,
    String? activeLabelSize,
    MarkupLayer? activeLayer,
    Map<MarkupLayer, bool>? layerVisibility,
    SnapConfig? snapConfig,
    String? selectedAnnotationId,
    bool clearSelectedId = false,
    bool? isLayersPanelOpen,
    bool? isFullscreen,
    double? zoomLevel,
    List<Point2D>? activeStrokePoints,
    List<Point2D>? snapGuideLine,
    bool clearSnapGuide = false,
    bool? allowFingerDrawing,
    bool? canUndo,
    bool? canRedo,
    bool? isAutosaving,
    bool? hasUnsavedChanges,
    String? lastSavedTimestamp,
    bool? isWipeLocked,
    bool? autoLockedDueToPalm,
    bool? isGloveMode,
    bool? isSearchOpen,
    DrawingTextToken? searchHighlightToken,
    bool clearSearchHighlight = false,
    String? currentUser,
    Set<String>? visibleAuthorFilters,
    bool? isAdmin,
    bool? isApproved,
    String? jobPrefix,
    String? jobSuffix,
    String? activeFontFamily,
    String? activeTextAlignment,
  }) {
    return MarkupEditorState(
      currentPage: currentPage ?? this.currentPage,
      annotations: annotations ?? this.annotations,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedShape: selectedShape ?? this.selectedShape,
      activeQuickNoteType: activeQuickNoteType ?? this.activeQuickNoteType,
      activeStampType: activeStampType ?? this.activeStampType,
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
      isWipeLocked: isWipeLocked ?? this.isWipeLocked,
      autoLockedDueToPalm: autoLockedDueToPalm ?? this.autoLockedDueToPalm,
      isGloveMode: isGloveMode ?? this.isGloveMode,
      isSearchOpen: isSearchOpen ?? this.isSearchOpen,
      searchHighlightToken: clearSearchHighlight ? null : (searchHighlightToken ?? this.searchHighlightToken),
      currentUser: currentUser ?? this.currentUser,
      visibleAuthorFilters: visibleAuthorFilters ?? this.visibleAuthorFilters,
      isAdmin: isAdmin ?? this.isAdmin,
      isApproved: isApproved ?? this.isApproved,
      jobPrefix: jobPrefix ?? this.jobPrefix,
      jobSuffix: jobSuffix ?? this.jobSuffix,
      activeFontFamily: activeFontFamily ?? this.activeFontFamily,
      activeTextAlignment: activeTextAlignment ?? this.activeTextAlignment,
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
      : super(MarkupEditorState(isApproved: _drawing.isApproved)) {
    _loadPageMarkup(1);
  }

  Future<void> _loadPageMarkup(int page) async {
    final pageMarkup = await _repository.getPageMarkup(_drawing.id, page);
    _undoStack.clear();
    _redoStack.clear();

    state = state.copyWith(
      currentPage: page,
      annotations: pageMarkup.annotations,
      canUndo: false,
      canRedo: false,
      hasUnsavedChanges: false,
      clearSelectedId: true,
      clearSnapGuide: true,
      isApproved: _drawing.isApproved,
    );
  }

  void _pushUndoSnapshot() {
    _undoStack.add(List.from(state.annotations));
    _redoStack.clear();
    state = state.copyWith(canUndo: true, canRedo: false, hasUnsavedChanges: true);
    _triggerAutosave();
  }

  // --- Phase D: Multi-User & Author Layers ---

  void toggleAuthorFilter(String author) {
    final currentFilters = Set<String>.from(state.visibleAuthorFilters);
    if (currentFilters.isEmpty) {
      // If currently all authors visible, switch to all except this one
      final all = Set<String>.from(state.availableAuthors);
      all.remove(author);
      state = state.copyWith(visibleAuthorFilters: all);
    } else if (currentFilters.contains(author)) {
      currentFilters.remove(author);
      state = state.copyWith(visibleAuthorFilters: currentFilters);
    } else {
      currentFilters.add(author);
      state = state.copyWith(visibleAuthorFilters: currentFilters);
    }
  }

  void setAllAuthorsVisible() {
    state = state.copyWith(visibleAuthorFilters: const {});
  }

  void setOnlyCurrentUserVisible() {
    state = state.copyWith(visibleAuthorFilters: {state.currentUser});
  }

  void setCurrentUser(String userName) {
    state = state.copyWith(currentUser: userName);
  }

  // --- Phase D: Admin & Read-Only Locking ---

  void setAdminMode(bool enabled) {
    state = state.copyWith(isAdmin: enabled);
  }

  void reopenDrawing() {
    state = state.copyWith(isApproved: false, isAdmin: true);
    _triggerAutosave();
  }

  // --- Phase D: Photo & GPS Pinning ---

  void addPhotoPin({
    required double x,
    required double y,
    required String base64Image,
    required GpsCoord gps,
    required String caption,
    String accuracy = '±2.8m',
  }) {
    if (state.isWipeLocked || state.isReadOnly) return;
    _pushUndoSnapshot();

    final newAnnotation = AnnotationItem(
      id: 'photo-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.photoPin,
      layer: MarkupLayer.photos,
      color: const Color(0xFF185FA5),
      strokeWidth: 2.0,
      points: [Point2D(x, y)],
      photoIds: [base64Image],
      gps: gps,
      text: caption,
      author: state.currentUser,
      metadata: {
        'accuracy': accuracy,
        'caption': caption,
        'timestamp': DateTime.now().toIso8601String(),
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updated = List<AnnotationItem>.from(state.annotations)..add(newAnnotation);
    state = state.copyWith(
      annotations: updated,
      selectedAnnotationId: newAnnotation.id,
    );
    HapticFeedback.selectionClick();
  }

  // --- Phase C: Text Search & Tap-To-Attach ---

  void toggleSearch([bool? force]) {
    final next = force ?? !state.isSearchOpen;
    state = state.copyWith(
      isSearchOpen: next,
      clearSearchHighlight: !next,
    );
  }

  void setSearchHighlight(DrawingTextToken? token) {
    state = state.copyWith(
      searchHighlightToken: token,
      clearSearchHighlight: token == null,
    );
  }

  AttachedTag? findAttachedTagAt(Point2D tapPoint, Size canvasSize, {double thresholdPixels = 24.0}) {
    final tokensOnPage = _drawing.extractedTokens.where((t) => t.pageNumber == state.currentPage);
    DrawingTextToken? bestToken;
    double minDistance = thresholdPixels + 0.001;

    for (final token in tokensOnPage) {
      final tokenCenterX = (token.x + token.width / 2) * canvasSize.width;
      final tokenCenterY = (token.y + token.height / 2) * canvasSize.height;

      final tapX = tapPoint.x * canvasSize.width;
      final tapY = tapPoint.y * canvasSize.height;

      final dx = (tokenCenterX - tapX).abs();
      final dy = (tokenCenterY - tapY).abs();
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist <= thresholdPixels && dist < minDistance) {
        minDistance = dist;
        bestToken = token;
      }
    }

    if (bestToken != null) {
      return AttachedTag(
        text: bestToken.text,
        bbox: [bestToken.x, bestToken.y, bestToken.width, bestToken.height],
      );
    }
    return null;
  }

  // --- Wipe Lock ---

  void toggleWipeLock([bool? forceState]) {
    final newState = forceState ?? !state.isWipeLocked;
    state = state.copyWith(
      isWipeLocked: newState,
      autoLockedDueToPalm: false,
      activeStrokePoints: const [],
      clearSnapGuide: true,
    );
    HapticFeedback.mediumImpact();
  }

  void triggerPalmClothAutoLock() {
    if (state.isWipeLocked) return;
    state = state.copyWith(
      isWipeLocked: true,
      autoLockedDueToPalm: true,
      activeStrokePoints: const [],
      clearSnapGuide: true,
    );
    HapticFeedback.heavyImpact();
  }

  void unlockWipe() {
    state = state.copyWith(
      isWipeLocked: false,
      autoLockedDueToPalm: false,
    );
    HapticFeedback.lightImpact();
  }

  void setGloveMode(bool enabled) {
    state = state.copyWith(
      isGloveMode: enabled,
      activeStrokeWidth: enabled && state.activeStrokeWidth < 4.0 ? 4.0 : state.activeStrokeWidth,
    );
  }

  // --- Offline Conflict Resolution & Restore ---

  void resolveOfflineSyncConflicts(List<AnnotationItem> remoteAnnotations) {
    final resolved = AnnotationConflictResolver.resolveConflicts(
      localAnnotations: state.annotations,
      remoteAnnotations: remoteAnnotations,
    );
    _pushUndoSnapshot();
    state = state.copyWith(annotations: resolved);
    _triggerAutosave();
  }

  void restoreConflictCopy(String conflictCopyId) {
    _pushUndoSnapshot();
    final updated = AnnotationConflictResolver.restoreConflictCopy(
      annotations: state.annotations,
      conflictCopyId: conflictCopyId,
    );
    state = state.copyWith(annotations: updated);
    _triggerAutosave();
  }

  // --- Phase B/C: Quick-Notes & Tap-to-Attach ---

  void setQuickNoteType(QuickNoteType qType, bool isOutdoor) {
    state = state.copyWith(
      selectedTool: MarkupTool.quickNote,
      activeQuickNoteType: qType,
      activeColor: qType.getColor(isOutdoor),
      clearSelectedId: true,
    );
  }

  void setStampType(StampType stampType, bool isOutdoor) {
    state = state.copyWith(
      selectedTool: MarkupTool.stamp,
      activeStampType: stampType,
      activeColor: stampType.getColor(isOutdoor),
      clearSelectedId: true,
    );
  }

  void addQuickNote({
    required String text,
    required String changeType,
    required Color color,
    required double x,
    required double y,
    AttachedTag? attachedTag,
  }) {
    if (state.isWipeLocked || state.isReadOnly) return;
    _pushUndoSnapshot();

    final newAnnotation = AnnotationItem(
      id: 'qn-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.text,
      layer: MarkupLayer.markups,
      color: color,
      strokeWidth: 1.5,
      points: [Point2D(x, y)],
      text: text,
      changeType: changeType,
      attachedTag: attachedTag,
      author: state.currentUser,
      size: 'M',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updated = List<AnnotationItem>.from(state.annotations)..add(newAnnotation);
    state = state.copyWith(
      annotations: updated,
      selectedAnnotationId: newAnnotation.id,
    );
    HapticFeedback.selectionClick();
  }

  void addNoteBox({
    required String text,
    required double x,
    required double y,
    Color? color,
  }) {
    if (state.isWipeLocked || state.isReadOnly) return;
    _pushUndoSnapshot();

    final noteColor = color ?? state.activeColor;
    final newAnnotation = AnnotationItem(
      id: 'note-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.noteBox,
      layer: MarkupLayer.markups,
      color: noteColor,
      strokeWidth: 1.5,
      points: [Point2D(x, y)],
      text: text,
      changeType: 'note',
      author: state.currentUser,
      size: 'M',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updated = List<AnnotationItem>.from(state.annotations)..add(newAnnotation);
    state = state.copyWith(
      annotations: updated,
      selectedAnnotationId: newAnnotation.id,
    );
    HapticFeedback.selectionClick();
  }

  void addStamp({
    required String stampTitle,
    required Color color,
    required double x,
    required double y,
    String? sealCode,
    String? userName,
  }) {
    if (state.isWipeLocked || state.isReadOnly) return;
    _pushUndoSnapshot();

    final authorName = userName ?? state.currentUser;
    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final newAnnotation = AnnotationItem(
      id: 'stamp-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.stamp,
      layer: MarkupLayer.inspection,
      color: color,
      strokeWidth: 2.0,
      points: [Point2D(x, y)],
      text: sealCode == 'jobNumber' ? state.fullJobNumber : stampTitle,
      changeType: 'stamp',
      author: authorName,
      metadata: {
        'date': nowStr,
        'user': authorName,
        'sealType': sealCode,
        'isLocked': false, // Can be dragged and positioned
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updated = List<AnnotationItem>.from(state.annotations)..add(newAnnotation);
    state = state.copyWith(
      annotations: updated,
      selectedAnnotationId: newAnnotation.id,
    );
    HapticFeedback.heavyImpact();
  }

  /// Places all 3 standard seals and the signature in predefined engineering title block slots
  void applyStandardTitleBlockSealSet() {
    if (state.isWipeLocked || state.isReadOnly) return;
    _pushUndoSnapshot();

    final authorName = state.currentUser;
    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final ts = DateTime.now().microsecondsSinceEpoch;

    // Standard A3 Title Block coordinates:
    // Seals 1, 2, 3 aligned in standard approval row
    // Official Signature and Job Number badge positioned right underneath
    final standardSet = <AnnotationItem>[
      // Seal 1: QA/QC Approved
      AnnotationItem(
        id: 'seal-qa-$ts',
        type: AnnotationType.stamp,
        layer: MarkupLayer.inspection,
        color: const Color(0xFF1B5E20),
        strokeWidth: 2.0,
        points: const [Point2D(0.68, 0.79)],
        text: 'QA / QC APPROVED (Seal 1)',
        changeType: 'stamp',
        author: authorName,
        metadata: {'date': nowStr, 'user': authorName, 'sealType': 'qaQcSeal', 'isLocked': false},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Seal 2: Safety & Structural Integrity
      AnnotationItem(
        id: 'seal-safety-$ts',
        type: AnnotationType.stamp,
        layer: MarkupLayer.inspection,
        color: const Color(0xFF0D47A1),
        strokeWidth: 2.0,
        points: const [Point2D(0.79, 0.79)],
        text: 'SAFETY & STRUCTURAL (Seal 2)',
        changeType: 'stamp',
        author: authorName,
        metadata: {'date': nowStr, 'user': authorName, 'sealType': 'safetySeal', 'isLocked': false},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Seal 3: Licensed PE Seal
      AnnotationItem(
        id: 'seal-pe-$ts',
        type: AnnotationType.stamp,
        layer: MarkupLayer.inspection,
        color: const Color(0xFFB71C1C),
        strokeWidth: 2.0,
        points: const [Point2D(0.89, 0.79)],
        text: 'LICENSED PE SEAL (Seal 3)',
        changeType: 'stamp',
        author: authorName,
        metadata: {'date': nowStr, 'user': authorName, 'sealType': 'peSeal', 'isLocked': false},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Reusable Signature
      AnnotationItem(
        id: 'seal-sig-$ts',
        type: AnnotationType.stamp,
        layer: MarkupLayer.inspection,
        color: const Color(0xFF1A237E),
        strokeWidth: 2.0,
        points: const [Point2D(0.71, 0.90)],
        text: 'OFFICIAL SIGNATURE',
        changeType: 'stamp',
        author: authorName,
        metadata: {'date': nowStr, 'user': authorName, 'sealType': 'signature', 'isLocked': false},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Job Number Badge
      AnnotationItem(
        id: 'seal-job-$ts',
        type: AnnotationType.stamp,
        layer: MarkupLayer.inspection,
        color: const Color(0xFF37474F),
        strokeWidth: 2.0,
        points: const [Point2D(0.86, 0.90)],
        text: state.fullJobNumber,
        changeType: 'stamp',
        author: authorName,
        metadata: {'date': nowStr, 'user': authorName, 'sealType': 'jobNumber', 'isLocked': false},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final updated = List<AnnotationItem>.from(state.annotations)..addAll(standardSet);
    state = state.copyWith(annotations: updated);
    HapticFeedback.heavyImpact();
  }

  /// Updates dynamic 3-digit suffix of the job number and synchronizes drawing badges
  void setJobSuffix(String suffix) {
    final clean = suffix.trim();
    final updatedJobNumber = '${state.jobPrefix}$clean';

    final updatedAnnotations = state.annotations.map((a) {
      if (a.type == AnnotationType.stamp && a.metadata?['sealType'] == 'jobNumber') {
        return a.copyWith(text: updatedJobNumber, updatedAt: DateTime.now());
      }
      return a;
    }).toList();

    state = state.copyWith(
      jobSuffix: clean,
      annotations: updatedAnnotations,
    );
  }

  /// Toggles Palm Rejection / Stylus-Only mode
  void toggleStylusOnly() {
    state = state.copyWith(allowFingerDrawing: !state.allowFingerDrawing);
  }

  void setAllowFingerDrawing(bool allow) {
    state = state.copyWith(allowFingerDrawing: allow);
  }

  // --- Tool & Property Selection ---

  void selectTool(MarkupTool tool) {
    state = state.copyWith(
      selectedTool: tool,
      clearSelectedId: true,
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
        final item = state.annotations[index];
        if (item.type == AnnotationType.stamp || item.metadata?['isLocked'] == true) return;
        if (!state.isAdmin && item.author != null && item.author != state.currentUser) return;

        _pushUndoSnapshot();
        final updated = List<AnnotationItem>.from(state.annotations);
        updated[index] = item.copyWith(color: color, updatedAt: DateTime.now());
        state = state.copyWith(annotations: updated);
      }
    }
  }

  void setStrokeWidth(double width) {
    final effectiveWidth = state.isGloveMode && width < 4.0 ? 4.0 : width;
    state = state.copyWith(activeStrokeWidth: effectiveWidth);
  }

  void setLabelSize(String size) {
    state = state.copyWith(activeLabelSize: size);
  }

  void setActiveLayer(MarkupLayer layer) {
    state = state.copyWith(activeLayer: layer);
  }

  void toggleLayer(MarkupLayer layer) {
    final current = state.layerVisibility[layer] ?? true;
    final updated = Map<MarkupLayer, bool>.from(state.layerVisibility)..[layer] = !current;
    state = state.copyWith(layerVisibility: updated);
  }

  void setSnapConfig(SnapConfig config) {
    state = state.copyWith(snapConfig: config);
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

  void selectAnnotation(String? id) {
    state = state.copyWith(
      selectedAnnotationId: id,
      clearSelectedId: id == null,
    );
  }

  // --- Realtime Vector Inking & Beautification ---

  void startStroke(Point2D point) {
    if (state.isWipeLocked || state.isReadOnly) return;
    _holdToBeautifyTimer?.cancel();
    state = state.copyWith(
      activeStrokePoints: [point],
      clearSelectedId: true,
      clearSnapGuide: true,
    );
  }

  void appendStrokePoint(Point2D point) {
    if (state.isWipeLocked || state.isReadOnly || state.activeStrokePoints.isEmpty) return;

    final updated = List<Point2D>.from(state.activeStrokePoints)..add(point);
    state = state.copyWith(activeStrokePoints: updated);

    if (state.snapConfig.isEnabled && updated.length >= 4) {
      final start = updated.first;
      final current = updated.last;
      final snapped = StrokeBeautifier.snapAngle(
        origin: start,
        target: current,
        axisSet: state.snapConfig.axisSet,
        toleranceDegrees: state.snapConfig.angleToleranceDegrees,
      );
      state = state.copyWith(snapGuideLine: [start, snapped]);
    }
  }

  void finishStroke() {
    if (state.isWipeLocked || state.isReadOnly) return;
    _holdToBeautifyTimer?.cancel();
    if (state.activeStrokePoints.isEmpty) return;

    _pushUndoSnapshot();

    AnnotationType? forcedType;
    if (state.selectedTool == MarkupTool.marker) forcedType = AnnotationType.marker;
    if (state.selectedTool == MarkupTool.highlighter) forcedType = AnnotationType.highlighter;
    if (state.selectedTool == MarkupTool.shapes) forcedType = state.selectedShape;
    if (state.selectedTool == MarkupTool.strikeOut) forcedType = AnnotationType.strikeOut;

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
      changeType: state.selectedTool == MarkupTool.strikeOut ? 'delete' : null,
      text: state.selectedTool == MarkupTool.strikeOut ? 'DELETE' : null,
      author: state.currentUser,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updatedAnnotations = List<AnnotationItem>.from(state.annotations)..add(newAnnotation);

    state = state.copyWith(
      annotations: updatedAnnotations,
      activeStrokePoints: const [],
      clearSnapGuide: true,
    );
  }

  // --- Whole Item Eraser (Protected for Multi-User) ---

  bool eraseAt(Point2D hitPoint) {
    if (state.isWipeLocked || state.isReadOnly) return false;
    int hitIndex = -1;

    for (int i = state.annotations.length - 1; i >= 0; i--) {
      final ann = state.annotations[i];
      if (ann.isConflictCopy) continue;
      if (ann.type == AnnotationType.stamp || ann.metadata?['isLocked'] == true) continue;
      if (state.layerVisibility[ann.layer] == false) continue;
      if (!state.isAuthorVisible(ann.author)) continue;

      // Multi-User Protection: Can only erase annotations created by current user unless Admin
      if (!state.isAdmin && ann.author != null && ann.author != state.currentUser) continue;

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

    if (ann.type == AnnotationType.text || ann.type == AnnotationType.callout || ann.type == AnnotationType.noteBox || ann.type == AnnotationType.stamp || ann.type == AnnotationType.photoPin) {
      final origin = ann.points.first;
      return (p.x >= origin.x - 0.04 && p.x <= origin.x + 0.22 &&
              p.y >= origin.y - 0.04 && p.y <= origin.y + 0.12);
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
    String? fontFamily,
    String? alignment,
  }) {
    if (state.isWipeLocked || state.isReadOnly) return;
    _pushUndoSnapshot();

    final chosenFont = fontFamily ?? state.activeFontFamily;
    final chosenAlignment = alignment ?? state.activeTextAlignment;

    final newAnnotation = AnnotationItem(
      id: 'lbl-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.text,
      layer: state.activeLayer,
      color: color ?? state.activeColor,
      strokeWidth: 1.5,
      points: [Point2D(x, y)],
      text: text,
      author: state.currentUser,
      size: size,
      metadata: {
        'fontFamily': chosenFont,
        'alignment': chosenAlignment,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updated = List<AnnotationItem>.from(state.annotations)..add(newAnnotation);
    state = state.copyWith(
      annotations: updated,
      selectedAnnotationId: newAnnotation.id,
    );
  }

  /// Sets the active downloaded font for handwriting & text annotations
  void setActiveFont(String fontId) {
    state = state.copyWith(activeFontFamily: fontId);

    // If an annotation is currently selected, update its font dynamically
    if (state.selectedAnnotationId != null) {
      final index = state.annotations.indexWhere((a) => a.id == state.selectedAnnotationId);
      if (index != -1 && (state.annotations[index].type == AnnotationType.text || state.annotations[index].type == AnnotationType.callout)) {
        final item = state.annotations[index];
        final updatedMeta = Map<String, dynamic>.from(item.metadata ?? {});
        updatedMeta['fontFamily'] = fontId;
        final updatedList = List<AnnotationItem>.from(state.annotations);
        updatedList[index] = item.copyWith(metadata: updatedMeta, updatedAt: DateTime.now());
        state = state.copyWith(annotations: updatedList);
      }
    }
  }

  /// Sets active text alignment ('left', 'center', 'right')
  void setTextAlignment(String alignment) {
    state = state.copyWith(activeTextAlignment: alignment);

    // If a text annotation is currently selected, update its alignment dynamically
    if (state.selectedAnnotationId != null) {
      final index = state.annotations.indexWhere((a) => a.id == state.selectedAnnotationId);
      if (index != -1 && state.annotations[index].type == AnnotationType.text) {
        final item = state.annotations[index];
        final updatedMeta = Map<String, dynamic>.from(item.metadata ?? {});
        updatedMeta['alignment'] = alignment;
        final updatedList = List<AnnotationItem>.from(state.annotations);
        updatedList[index] = item.copyWith(metadata: updatedMeta, updatedAt: DateTime.now());
        state = state.copyWith(annotations: updatedList);
      }
    }
  }

  /// Updates an existing label's text, size, color, font, or alignment
  void updateLabel({
    required String annotationId,
    required String text,
    String? size,
    Color? color,
    String? fontFamily,
    String? alignment,
  }) {
    if (state.isWipeLocked || state.isReadOnly) return;
    final index = state.annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) return;

    _pushUndoSnapshot();
    final item = state.annotations[index];
    final updatedMeta = Map<String, dynamic>.from(item.metadata ?? {});
    if (fontFamily != null) updatedMeta['fontFamily'] = fontFamily;
    if (alignment != null) updatedMeta['alignment'] = alignment;

    final updated = List<AnnotationItem>.from(state.annotations);
    updated[index] = item.copyWith(
      text: text,
      size: size ?? item.size,
      color: color ?? item.color,
      metadata: updatedMeta,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      annotations: updated,
      hasUnsavedChanges: true,
      canUndo: true,
    );
  }

  /// Converts a handwritten pen stroke into aligned text in the downloaded font
  void convertAnnotationToText({
    required String annotationId,
    required String text,
    String? fontFamily,
    String? alignment,
    String size = 'M',
    Color? color,
  }) {
    if (state.isWipeLocked || state.isReadOnly) return;
    final index = state.annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) return;

    _pushUndoSnapshot();

    final original = state.annotations[index];
    final origin = original.points.isNotEmpty ? original.points.first : const Point2D(0.5, 0.5);
    final chosenFont = fontFamily ?? state.activeFontFamily;
    final chosenAlignment = alignment ?? state.activeTextAlignment;

    final newTextAnnotation = AnnotationItem(
      id: 'lbl-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.text,
      layer: original.layer,
      color: color ?? original.color,
      strokeWidth: 1.5,
      points: [origin],
      text: text,
      author: state.currentUser,
      size: size,
      metadata: {
        'fontFamily': chosenFont,
        'alignment': chosenAlignment,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updated = List<AnnotationItem>.from(state.annotations);
    updated[index] = newTextAnnotation;
    state = state.copyWith(
      annotations: updated,
      selectedAnnotationId: newTextAnnotation.id,
      hasUnsavedChanges: true,
      canUndo: true,
    );
  }

  void moveAnnotation(String id, Point2D newPos) {
    if (state.isWipeLocked || state.isReadOnly) return;
    final index = state.annotations.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final item = state.annotations[index];
    if (item.metadata?['isLocked'] == true) return;
    if (!state.isAdmin && item.author != null && item.author != state.currentUser) return;

    final updated = List<AnnotationItem>.from(state.annotations);

    if (item.type == AnnotationType.text ||
        item.type == AnnotationType.noteBox ||
        item.type == AnnotationType.stamp ||
        item.type == AnnotationType.photoPin ||
        item.points.length == 1) {
      updated[index] = item.copyWith(points: [newPos], updatedAt: DateTime.now());
    } else if (item.points.isNotEmpty) {
      final origin = item.points.first;
      final dx = newPos.x - origin.x;
      final dy = newPos.y - origin.y;
      final shifted = item.points.map((p) => Point2D((p.x + dx).clamp(0.0, 1.0), (p.y + dy).clamp(0.0, 1.0))).toList();
      updated[index] = item.copyWith(points: shifted, updatedAt: DateTime.now());
    }

    state = state.copyWith(annotations: updated);
  }

  void moveLabel(String id, Point2D newPos) => moveAnnotation(id, newPos);

  void finishMoveLabel() {
    if (state.isWipeLocked || state.isReadOnly) return;
    _triggerAutosave();
    state = state.copyWith(hasUnsavedChanges: true, canUndo: true);
  }

  void deleteSelectedLabel() {
    if (state.isWipeLocked || state.isReadOnly || state.selectedAnnotationId == null) return;
    final item = state.annotations.where((a) => a.id == state.selectedAnnotationId).firstOrNull;
    if (item != null) {
      if (item.type == AnnotationType.stamp || item.metadata?['isLocked'] == true) return;
      if (!state.isAdmin && item.author != null && item.author != state.currentUser) return;
    }

    _pushUndoSnapshot();
    final updated = state.annotations.where((a) => a.id != state.selectedAnnotationId).toList();
    state = state.copyWith(
      annotations: updated,
      clearSelectedId: true,
    );
  }

  // --- Undo & Redo ---

  void undo() {
    if (state.isWipeLocked || state.isReadOnly || _undoStack.isEmpty) return;

    if (state.annotations.isNotEmpty && state.annotations.last.rawPoints != null) {
      _redoStack.add(List.from(state.annotations));
      final last = state.annotations.last;
      final restored = last.copyWith(
        type: AnnotationType.stroke,
        points: last.rawPoints,
        clearRawPoints: true,
        updatedAt: DateTime.now(),
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
    if (state.isWipeLocked || state.isReadOnly || _redoStack.isEmpty) return;

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
    if (state.isReadOnly) return;
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 500), () {
      saveNow();
    });
  }

  Future<void> saveNow() async {
    if (state.isReadOnly) return;
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
