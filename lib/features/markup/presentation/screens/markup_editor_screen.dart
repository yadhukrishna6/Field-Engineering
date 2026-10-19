import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glove_mode_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/field_change_item.dart';
import '../../domain/models/markup_layer.dart';
import '../../domain/models/point_2d.dart';
import '../controllers/drawings_list_controller.dart';
import '../controllers/markup_editor_controller.dart';
import '../widgets/add_label_sheet.dart';
import '../widgets/change_list_sheet.dart';
import '../widgets/drawing_canvas_painter.dart';
import '../widgets/drawing_search_bar.dart';
import '../widgets/export_share_hub_sheet.dart';
import '../widgets/field_calculations_sheet.dart';

import '../widgets/layers_panel.dart';
import '../widgets/markup_bottom_toolbar.dart';
import '../widgets/minimap_view.dart';
import '../widgets/note_box_dialog.dart';
import '../widgets/photo_gps_pin_sheet.dart';
import '../widgets/photo_preview_dialog.dart';
import '../widgets/quick_notes_sheet.dart';
import '../widgets/revision_compare_viewer.dart';
import '../widgets/shapes_selection_popup.dart';
import '../widgets/snap_settings_chip.dart';
import '../widgets/stamps_sheet.dart';
import '../widgets/sync_status_chip.dart';
import '../widgets/theme_selector_modal.dart';
import '../widgets/wipe_lock_overlay.dart';

class MarkupEditorScreen extends ConsumerStatefulWidget {
  final DrawingFile drawing;

  const MarkupEditorScreen({
    super.key,
    required this.drawing,
  });

  @override
  ConsumerState<MarkupEditorScreen> createState() => _MarkupEditorScreenState();
}

class _MarkupEditorScreenState extends ConsumerState<MarkupEditorScreen> {
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  Point2D? _pointerDownPoint;
  bool _isDraggingAnnotation = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    ref.read(markupEditorControllerProvider(widget.drawing).notifier).setZoomLevel(scale);
  }

  Point2D _screenToPage(Offset globalPos) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return const Point2D(0, 0);
    final local = box.globalToLocal(globalPos);
    return Point2D(
      (local.dx / box.size.width).clamp(0.0, 1.0),
      (local.dy / box.size.height).clamp(0.0, 1.0),
    );
  }

  void _handleResetZoom() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.2) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.2);
    }
  }

  void _showShapesPopup(BuildContext context, MarkupEditorState state, MarkupEditorController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShapesSelectionPopup(
        currentShape: state.selectedShape,
        onSelectShape: (shape) => controller.selectShape(shape),
      ),
    );
  }

  void _showRevisionCompare(BuildContext context, MarkupEditorState state, bool isOutdoor, bool isDark) {
    RevisionCompareViewer.show(
      context,
      currentDrawing: widget.drawing,
      currentAnnotations: state.annotations,
      baseRevisionName: 'Rev 0 (Baseline)',
      compareRevisionName: widget.drawing.revision ?? 'Rev 1 (Field)',
      isOutdoor: isOutdoor,
      isDark: isDark,
    );
  }

  void _showChangeList(BuildContext context, MarkupEditorState state, bool isOutdoor, bool isDark) {
    ChangeListSheet.show(
      context,
      drawing: widget.drawing,
      annotations: state.annotations,
      isOutdoor: isOutdoor,
      isDark: isDark,
      onSelectChange: (item) {
        if (item.pageNumber != state.currentPage) {
          ref.read(markupEditorControllerProvider(widget.drawing).notifier).setPage(item.pageNumber);
        }
        final matrix = Matrix4.identity()
          ..scale(2.5)
          ..translate(-item.x * 400, -item.y * 300);
        _transformationController.value = matrix;
      },
      onExportPdf: () => _openExportHub(context, state, isOutdoor, isDark),
      onExportCsv: () => _openExportHub(context, state, isOutdoor, isDark),
    );
  }


  void _showFieldCalculations(BuildContext context, MarkupEditorState state, bool isOutdoor, bool isDark) {
    FieldCalculationsSheet.show(
      context,
      annotations: state.annotations,
      isOutdoor: isOutdoor,
      isDark: isDark,
    );
  }

  void _openExportHub(BuildContext context, MarkupEditorState state, bool isOutdoor, bool isDark) {
    final repo = ref.read(markupRepositoryProvider);
    ExportShareHubSheet.show(
      context,
      drawing: widget.drawing,
      annotations: state.annotations,
      repository: repo,
      isOutdoor: isOutdoor,
      isDark: isDark,
    );
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(markupEditorControllerProvider(widget.drawing));
    final controller = ref.read(markupEditorControllerProvider(widget.drawing).notifier);
    final themeState = ref.watch(themeControllerProvider);
    final gloveState = ref.watch(gloveModeProvider);

    final isOutdoor = themeState.isOutdoorActive;
    final isDark = themeState.isDarkActive;
    final isGlove = gloveState.isGloveMode;

    final backgroundColor = isOutdoor
        ? AppColors.outdoorBackground
        : (isDark ? AppColors.darkBackground : AppColors.lightBackground);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletLandscape = screenWidth >= 768;

    final changesCount = FieldChangeItem.extractChanges(state.annotations).length;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (state.canUndo) controller.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (state.canUndo) controller.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (state.canRedo) controller.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): () {
          if (state.canRedo) controller.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          if (state.canRedo) controller.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          controller.saveNow();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          controller.saveNow();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: state.isFullscreen
          ? null
          : AppBar(
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.drawing.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isOutdoor ? 15 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (state.isApproved) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'APPROVED',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Sheet ${state.currentPage}/${widget.drawing.pageCount} | ${state.currentUser}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isOutdoor ? 10 : 9.5,
                        fontWeight: FontWeight.w500,
                        color: isOutdoor ? AppColors.outdoorSecondaryText : null,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // 1. Undo Button (Ctrl+Z)
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: 'Undo (Ctrl+Z)',
                  onPressed: state.canUndo ? () => controller.undo() : null,
                ),

                // 2. Redo Button (Ctrl+Y)
                IconButton(
                  icon: const Icon(Icons.redo_rounded),
                  tooltip: 'Redo (Ctrl+Y / Ctrl+Shift+Z)',
                  onPressed: state.canRedo ? () => controller.redo() : null,
                ),

                // 3. Structured Change List (# Callouts)
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.format_list_numbered_rounded, color: primaryColor),
                      if (changesCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD03A33),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$changesCount',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Structured Change List (Phase E)',
                  onPressed: () => _showChangeList(context, state, isOutdoor, isDark),
                ),

                // 4. In-Drawing Text Search (Phase C)
                IconButton(
                  icon: Icon(
                    state.isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
                    color: state.isSearchOpen ? Colors.amber : primaryColor,
                  ),
                  tooltip: 'Search Drawing Text (Phase C)',
                  onPressed: () => controller.toggleSearch(),
                ),

                // 5. Calculations & Quantities (Phase F)
                IconButton(
                  icon: Icon(Icons.calculate_rounded, color: primaryColor),
                  tooltip: 'Field Calculations & Quantities (Phase F)',
                  onPressed: () => _showFieldCalculations(context, state, isOutdoor, isDark),
                ),

                // 6. Wide Screen Direct Actions (if width >= 950px) or Overflow Menu
                if (screenWidth >= 950) ...[
                  if (widget.drawing.pageCount > 1) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Previous Sheet',
                      onPressed: state.currentPage > 1 ? () => controller.setPage(state.currentPage - 1) : null,
                    ),
                    Center(
                      child: Text(
                        '${state.currentPage}/${widget.drawing.pageCount}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Next Sheet',
                      onPressed: state.currentPage < widget.drawing.pageCount ? () => controller.setPage(state.currentPage + 1) : null,
                    ),
                  ],
                  IconButton(
                    icon: Icon(Icons.compare_arrows_rounded, color: primaryColor),
                    tooltip: 'Compare Revisions Overlay (Phase D)',
                    onPressed: () => _showRevisionCompare(context, state, isOutdoor, isDark),
                  ),
                  IconButton(
                    icon: Icon(
                      state.isWipeLocked ? Icons.lock_rounded : Icons.lock_outline_rounded,
                      color: state.isWipeLocked ? Colors.amber : primaryColor,
                    ),
                    tooltip: 'Wipe Lock',
                    onPressed: () => controller.toggleWipeLock(),
                  ),
                  IconButton(
                    icon: Icon(Icons.palette_outlined, color: primaryColor),
                    tooltip: 'Display Theme',
                    onPressed: () => ThemeSelectorModal.show(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.share_rounded, color: primaryColor),
                    tooltip: 'Export & Hand-off Hub',
                    onPressed: () => _openExportHub(context, state, isOutdoor, isDark),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Center(child: SyncStatusChip()),
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: primaryColor),
                    tooltip: 'More Actions',
                    onSelected: (val) {
                      switch (val) {
                        case 'export':
                          _openExportHub(context, state, isOutdoor, isDark);
                          break;
                        case 'compare':
                          _showRevisionCompare(context, state, isOutdoor, isDark);
                          break;
                        case 'wipeLock':
                          controller.toggleWipeLock();
                          break;
                        case 'theme':
                          ThemeSelectorModal.show(context);
                          break;
                        case 'prevPage':
                          if (state.currentPage > 1) controller.setPage(state.currentPage - 1);
                          break;
                        case 'nextPage':
                          if (state.currentPage < widget.drawing.pageCount) controller.setPage(state.currentPage + 1);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (widget.drawing.pageCount > 1) ...[
                        PopupMenuItem(
                          value: 'prevPage',
                          enabled: state.currentPage > 1,
                          child: Text('Previous Sheet (${state.currentPage - 1})'),
                        ),
                        PopupMenuItem(
                          value: 'nextPage',
                          enabled: state.currentPage < widget.drawing.pageCount,
                          child: Text('Next Sheet (${state.currentPage + 1})'),
                        ),
                        const PopupMenuDivider(),
                      ],
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.share_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Export & Hand-off Hub'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'compare',
                        child: Row(
                          children: [
                            Icon(Icons.compare_arrows_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Revision Compare Overlay'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'wipeLock',
                        child: Row(
                          children: [
                            Icon(state.isWipeLocked ? Icons.lock_open_rounded : Icons.lock_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(state.isWipeLocked ? 'Unlock Canvas' : 'Wipe Lock Canvas'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'theme',
                        child: Row(
                          children: [
                            Icon(Icons.palette_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Display Theme'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // 7. Save Markups
                IconButton(
                  icon: const Icon(Icons.save_rounded),
                  tooltip: 'Save Markups (Ctrl+S)',
                  onPressed: () => controller.saveNow(),
                ),
              ],
            ),
      body: Column(
        children: [
          // Phase D: Read-Only Approved Banner
          if (state.isReadOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF3E0),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'DRAWING IS APPROVED (READ-ONLY) — Office-approved revision is locked against field edits.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE65100),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                    label: const Text('Admin Reopen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Admin Reopen Drawing'),
                          content: const Text('Unlock approved drawing for field engineering revision?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF08605B), foregroundColor: Colors.white),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                controller.reopenDrawing();
                              },
                              child: const Text('Reopen & Unlock'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          Expanded(
            child: Row(
              children: [
                // Left Tool Rail (Tablet Landscape & Desktop)
                if (isTabletLandscape)
                  _buildLeftToolRail(context, state, controller, isOutdoor, isDark, isGlove),

                // Main Canvas Area with Overlays
                Expanded(
                  child: Stack(
                    children: [
                      // Interactive Drawing Canvas (White paper in ALL themes)
                      Positioned.fill(
                        child: _buildCanvasArea(state, controller, isDark, gloveState.tapDistanceThreshold),
                      ),

                      // Top-Left Smart Snap Chip
                      Positioned(
                        left: 12,
                        top: 12,
                        child: SnapSettingsChip(
                          snapConfig: state.snapConfig,
                          onConfigChanged: (cfg) => controller.setSnapConfig(cfg),
                        ),
                      ),

                      // Top-Right Collapsible Layers Panel
                      if (state.isLayersPanelOpen)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: LayersPanel(
                            layerVisibility: state.layerVisibility,
                            conflictCopies: state.conflictCopies,
                            availableAuthors: state.availableAuthors,
                            visibleAuthorFilters: state.visibleAuthorFilters,
                            onToggleLayer: (l) => controller.toggleLayer(l),
                            onToggleAuthor: (a) => controller.toggleAuthorFilter(a),
                            onShowAllAuthors: () => controller.setAllAuthorsVisible(),
                            onShowOnlyMine: () => controller.setOnlyCurrentUserVisible(),
                            currentUser: state.currentUser,
                            onRestoreConflictCopy: (id) => controller.restoreConflictCopy(id),
                            onOpenRevisionCompare: () => _showRevisionCompare(context, state, isOutdoor, isDark),
                            onClose: () => controller.toggleLayersPanel(),
                          ),
                        ),

                      // Bottom-Right Floating Minimap
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: MinimapView(
                          transformationController: _transformationController,
                          drawing: widget.drawing,
                          onResetZoom: _handleResetZoom,
                        ),
                      ),

                      // In-Drawing Text Search Overlay (Phase C)
                      if (state.isSearchOpen)
                        Positioned(
                          top: 12,
                          left: 60,
                          child: DrawingSearchBar(
                            tokens: widget.drawing.extractedTokens,
                            isOutdoor: isOutdoor,
                            isDark: isDark,
                            onSelectToken: (token) {
                              if (token.pageNumber != state.currentPage) {
                                controller.setPage(token.pageNumber);
                              }
                              controller.setSearchHighlight(token);
                              final matrix = Matrix4.identity()
                                ..scale(2.5)
                                ..translate(-token.x * 400, -token.y * 300);
                              _transformationController.value = matrix;
                            },
                            onClose: () => controller.toggleSearch(false),
                          ),
                        ),

                      // Wipe Lock Protection Overlay (Phase A)
                      if (state.isWipeLocked)
                        Positioned.fill(
                          child: WipeLockOverlay(
                            isAutoLocked: state.autoLockedDueToPalm,
                            isOutdoor: isOutdoor,
                            isDark: isDark,
                            onUnlock: () => controller.unlockWipe(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phone Tools Rail / Bottom Bar
          if (!isTabletLandscape)
            _buildPhoneToolRail(context, state, controller, isOutdoor, isDark, isGlove),

          // Bottom Bar
          MarkupBottomToolbar(
            state: state,
            controller: controller,
            onResetZoom: _handleResetZoom,
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildLeftToolRail(
    BuildContext context,
    MarkupEditorState state,
    MarkupEditorController controller,
    bool isOutdoor,
    bool isDark,
    bool isGlove,
  ) {
    final surfaceColor = isOutdoor
        ? AppColors.outdoorSurface
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final outlineColor = isOutdoor
        ? AppColors.outdoorOutline
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final textColor = isOutdoor
        ? AppColors.outdoorText
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    final tools = [
      {'tool': MarkupTool.pen, 'icon': Icons.edit_rounded, 'label': 'Pen'},
      {'tool': MarkupTool.marker, 'icon': Icons.border_color_rounded, 'label': 'Marker'},
      {'tool': MarkupTool.highlighter, 'icon': Icons.highlight_rounded, 'label': 'Highlighter'},
      {'tool': MarkupTool.text, 'icon': Icons.text_fields_rounded, 'label': 'Text'},
      {'tool': MarkupTool.quickNote, 'icon': Icons.bolt_rounded, 'label': 'Quick Note'},
      {'tool': MarkupTool.strikeOut, 'icon': Icons.strikethrough_s_rounded, 'label': 'Strike'},
      {'tool': MarkupTool.noteBox, 'icon': Icons.notes_rounded, 'label': 'Note Box'},
      {'tool': MarkupTool.stamp, 'icon': Icons.approval_rounded, 'label': 'Stamp'},
      {'tool': MarkupTool.photo, 'icon': Icons.photo_camera_rounded, 'label': 'Photo'},
      {'tool': MarkupTool.shapes, 'icon': Icons.category_rounded, 'label': 'Shapes'},
      {'tool': MarkupTool.eraser, 'icon': Icons.auto_fix_high_rounded, 'label': 'Eraser'},
    ];

    final targetHeight = isGlove ? 58.0 : (isOutdoor ? 52.0 : 46.0);
    final iconSize = isGlove ? 26.0 : (isOutdoor ? 24.0 : 22.0);

    return Container(
      width: isGlove ? 92 : (isOutdoor ? 86 : 78),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(right: BorderSide(color: outlineColor, width: isOutdoor ? 1.5 : 1.0)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: tools.map((t) {
          final tool = t['tool'] as MarkupTool;
          final isSelected = state.selectedTool == tool;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isGlove ? 6 : (isOutdoor ? 6 : 8), vertical: 3),
            child: InkWell(
              onTap: () async {
                if (tool == MarkupTool.shapes) {
                  _showShapesPopup(context, state, controller);
                } else if (tool == MarkupTool.photo) {
                  controller.selectTool(MarkupTool.photo);
                } else if (tool == MarkupTool.quickNote) {
                  final chosen = await QuickNotesSheet.show(context, isOutdoor: isOutdoor, isDark: isDark);
                  if (chosen != null) {
                    controller.setQuickNoteType(chosen, isOutdoor);
                  } else {
                    controller.selectTool(MarkupTool.quickNote);
                  }
                } else if (tool == MarkupTool.stamp) {
                  final stamp = await StampsSheet.show(context, isOutdoor: isOutdoor, isDark: isDark);
                  if (stamp != null) {
                    controller.setStampType(stamp, isOutdoor);
                  } else {
                    controller.selectTool(MarkupTool.stamp);
                  }
                } else {
                  controller.selectTool(tool);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: BoxConstraints(minHeight: targetHeight),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isOutdoor ? outlineColor.withOpacity(0.3) : Colors.transparent),
                    width: isOutdoor ? 1.5 : 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: iconSize,
                      color: isSelected ? primaryColor : textColor,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: isOutdoor ? 11 : 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? primaryColor : textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhoneToolRail(
    BuildContext context,
    MarkupEditorState state,
    MarkupEditorController controller,
    bool isOutdoor,
    bool isDark,
    bool isGlove,
  ) {
    final surfaceColor = isOutdoor
        ? AppColors.outdoorSurface
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final outlineColor = isOutdoor
        ? AppColors.outdoorOutline
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final textColor = isOutdoor
        ? AppColors.outdoorText
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    final tools = [
      {'tool': MarkupTool.pen, 'icon': Icons.edit_rounded, 'label': 'Pen'},
      {'tool': MarkupTool.marker, 'icon': Icons.border_color_rounded, 'label': 'Marker'},
      {'tool': MarkupTool.highlighter, 'icon': Icons.highlight_rounded, 'label': 'Highlighter'},
      {'tool': MarkupTool.text, 'icon': Icons.text_fields_rounded, 'label': 'Text'},
      {'tool': MarkupTool.quickNote, 'icon': Icons.bolt_rounded, 'label': 'Quick Note'},
      {'tool': MarkupTool.strikeOut, 'icon': Icons.strikethrough_s_rounded, 'label': 'Strike'},
      {'tool': MarkupTool.noteBox, 'icon': Icons.notes_rounded, 'label': 'Note Box'},
      {'tool': MarkupTool.stamp, 'icon': Icons.approval_rounded, 'label': 'Stamp'},
      {'tool': MarkupTool.photo, 'icon': Icons.photo_camera_rounded, 'label': 'Photo'},
      {'tool': MarkupTool.shapes, 'icon': Icons.category_rounded, 'label': 'Shapes'},
      {'tool': MarkupTool.eraser, 'icon': Icons.auto_fix_high_rounded, 'label': 'Eraser'},
    ];

    final targetHeight = isGlove ? 56.0 : (isOutdoor ? 50.0 : 44.0);

    return Container(
      height: targetHeight + 10,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: outlineColor, width: isOutdoor ? 1.5 : 1.0)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: tools.map((t) {
          final tool = t['tool'] as MarkupTool;
          final isSelected = state.selectedTool == tool;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () async {
                if (tool == MarkupTool.shapes) {
                  _showShapesPopup(context, state, controller);
                } else if (tool == MarkupTool.photo) {
                  controller.selectTool(MarkupTool.photo);
                } else if (tool == MarkupTool.quickNote) {
                  final chosen = await QuickNotesSheet.show(context, isOutdoor: isOutdoor, isDark: isDark);
                  if (chosen != null) {
                    controller.setQuickNoteType(chosen, isOutdoor);
                  } else {
                    controller.selectTool(MarkupTool.quickNote);
                  }
                } else if (tool == MarkupTool.stamp) {
                  final stamp = await StampsSheet.show(context, isOutdoor: isOutdoor, isDark: isDark);
                  if (stamp != null) {
                    controller.setStampType(stamp, isOutdoor);
                  } else {
                    controller.selectTool(MarkupTool.stamp);
                  }
                } else {
                  controller.selectTool(tool);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(minWidth: isGlove ? 64 : 54, minHeight: targetHeight),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? primaryColor : outlineColor.withOpacity(0.3),
                    width: isOutdoor ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t['icon'] as IconData, size: isGlove ? 22 : 20, color: isSelected ? primaryColor : textColor),
                    const SizedBox(height: 2),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? primaryColor : textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCanvasArea(
    MarkupEditorState state,
    MarkupEditorController controller,
    bool isDark,
    double tapTolerance,
  ) {
    final showOriginal = state.layerVisibility[MarkupLayer.originalDrawing] ?? true;
    final isLocked = state.isWipeLocked;

    return GestureDetector(
      onDoubleTap: isLocked ? null : _handleResetZoom,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 8.0,
        boundaryMargin: const EdgeInsets.all(200),
        panEnabled: !isLocked && !state.allowFingerDrawing,
        scaleEnabled: !isLocked,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.414, // A3 Landscape proportion
            child: Listener(
              onPointerDown: (event) {
                if (isLocked) return;

                // Palm / cloth contact auto-lock detection (Phase A)
                if (event.kind == PointerDeviceKind.touch &&
                    (event.radiusMajor > 25.0 || event.radiusMinor > 25.0 || event.size > 0.25)) {
                  controller.triggerPalmClothAutoLock();
                  return;
                }

                if (!state.allowFingerDrawing && event.kind != PointerDeviceKind.stylus) {
                  return;
                }

                final p = _screenToPage(event.position);
                _pointerDownPoint = p;

                // Check if user tapped an existing photoPin
                AnnotationItem? hitPhotoPin;
                for (final ann in state.annotations) {
                  if (ann.type == AnnotationType.photoPin && ann.points.isNotEmpty) {
                    final origin = ann.points.first;
                    final dist = (p.x - origin.x).abs() + (p.y - origin.y).abs();
                    if (dist < 0.04) {
                      hitPhotoPin = ann;
                      break;
                    }
                  }
                }

                if (hitPhotoPin != null) {
                  final themeState = ref.read(themeControllerProvider);
                  PhotoPreviewDialog.show(
                    context,
                    annotation: hitPhotoPin,
                    isOutdoor: themeState.isOutdoorActive,
                    isDark: themeState.isDarkActive,
                    canDelete: !state.isReadOnly,
                    onDelete: () {
                      controller.selectAnnotation(hitPhotoPin!.id);
                      controller.deleteSelectedLabel();
                    },
                  );
                  return;
                }

                if (state.isReadOnly) return; // Prevent creating new markups in read-only mode

                if (state.selectedTool == MarkupTool.eraser) {
                  controller.eraseAt(p);
                } else if (state.selectedTool == MarkupTool.photo) {
                  // Phase D: Place Photo + GPS Pin
                  final themeState = ref.read(themeControllerProvider);
                  PhotoGpsPinSheet.show(
                    context,
                    isOutdoor: themeState.isOutdoorActive,
                    isDark: themeState.isDarkActive,
                  ).then((result) {
                    if (result != null) {
                      controller.addPhotoPin(
                        x: p.x,
                        y: p.y,
                        base64Image: result.base64Image,
                        gps: result.gps,
                        caption: result.caption,
                        accuracy: result.accuracy,
                      );
                    }
                  });
                } else if (state.selectedTool == MarkupTool.quickNote) {
                  // Phase B & C: One tap places standard quick-note with Tap-to-Attach (<= 24px)
                  final qType = state.activeQuickNoteType ?? QuickNoteType.delete;
                  final themeState = ref.read(themeControllerProvider);
                  final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                  final canvasSize = box?.size ?? const Size(800, 600);
                  final attachedTag = controller.findAttachedTagAt(p, canvasSize, thresholdPixels: 24.0);

                  controller.addQuickNote(
                    text: qType.label,
                    changeType: qType.changeType,
                    color: qType.getColor(themeState.isOutdoorActive),
                    x: p.x,
                    y: p.y,
                    attachedTag: attachedTag,
                  );
                } else if (state.selectedTool == MarkupTool.stamp) {
                  // Phase B: One tap places official stamp
                  final sType = state.activeStampType ?? StampType.approved;
                  final themeState = ref.read(themeControllerProvider);
                  controller.addStamp(
                    stampTitle: sType.title,
                    color: sType.getColor(themeState.isOutdoorActive),
                    x: p.x,
                    y: p.y,
                  );
                } else if (state.selectedTool == MarkupTool.noteBox) {
                  // Phase B: Note box placement dialog
                  final themeState = ref.read(themeControllerProvider);
                  NoteBoxDialog.show(
                    context,
                    isOutdoor: themeState.isOutdoorActive,
                    isDark: themeState.isDarkActive,
                  ).then((text) {
                    if (text != null && text.isNotEmpty) {
                      controller.addNoteBox(text: text, x: p.x, y: p.y);
                    }
                  });
                } else if (state.selectedTool == MarkupTool.text) {
                  AnnotationItem? hitItem;
                  for (int i = state.annotations.length - 1; i >= 0; i--) {
                    final a = state.annotations[i];
                    if (a.isConflictCopy) continue;
                    if ((a.type == AnnotationType.text || a.type == AnnotationType.noteBox) && a.points.isNotEmpty) {
                      final origin = a.points.first;
                      if (p.x >= origin.x - 0.04 && p.x <= origin.x + 0.20 &&
                          p.y >= origin.y - 0.04 && p.y <= origin.y + 0.10) {
                        hitItem = a;
                        break;
                      }
                    }
                  }

                  if (hitItem != null) {
                    controller.selectAnnotation(hitItem.id);
                    _isDraggingAnnotation = true;
                  } else {
                    controller.selectAnnotation(null);
                    _isDraggingAnnotation = false;
                  }
                } else {
                  controller.startStroke(p);
                }
              },
              onPointerMove: (event) {
                if (isLocked || state.isReadOnly) return;
                if (!state.allowFingerDrawing && event.kind != PointerDeviceKind.stylus) {
                  return;
                }

                final p = _screenToPage(event.position);

                if (state.selectedTool == MarkupTool.eraser) {
                  controller.eraseAt(p);
                } else if (state.selectedTool == MarkupTool.text) {
                  if (_isDraggingAnnotation && state.selectedAnnotationId != null) {
                    controller.moveAnnotation(state.selectedAnnotationId!, p);
                  }
                } else if (state.selectedTool != MarkupTool.quickNote &&
                           state.selectedTool != MarkupTool.stamp &&
                           state.selectedTool != MarkupTool.noteBox &&
                           state.selectedTool != MarkupTool.photo) {
                  controller.appendStrokePoint(p);
                }
              },
              onPointerUp: (event) {
                if (isLocked || state.isReadOnly) return;
                final p = _screenToPage(event.position);

                if (state.selectedTool == MarkupTool.text) {
                  if (_isDraggingAnnotation) {
                    _isDraggingAnnotation = false;
                    controller.finishMoveLabel();
                  } else if (_pointerDownPoint != null) {
                    final dist = (p.x - _pointerDownPoint!.x).abs() + (p.y - _pointerDownPoint!.y).abs();
                    if (dist < tapTolerance && state.selectedAnnotationId == null) {
                      AddLabelSheet.show(
                        context,
                        initialColor: state.activeColor,
                        initialSize: state.activeLabelSize,
                        onConfirm: (text, size, color) {
                          controller.addLabel(
                            text: text,
                            x: p.x,
                            y: p.y,
                            size: size,
                            color: color,
                          );
                        },
                      );
                    }
                  }
                } else if (state.selectedTool != MarkupTool.eraser &&
                           state.selectedTool != MarkupTool.quickNote &&
                           state.selectedTool != MarkupTool.stamp &&
                           state.selectedTool != MarkupTool.noteBox &&
                           state.selectedTool != MarkupTool.photo) {
                  controller.finishStroke();
                }
                _pointerDownPoint = null;
              },
              child: Container(
                key: _canvasKey,
                decoration: BoxDecoration(
                  color: AppColors.canvasPaper, // Stays pure white #FFFFFF in ALL themes
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Original Blueprint Layer (respects layer visibility)
                    if (showOriginal)
                      _buildBaseLayer(widget.drawing),

                    // Custom Vector Inking & Annotation Layer
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        AnnotationType currentToolType = AnnotationType.stroke;
                        if (state.selectedTool == MarkupTool.marker) currentToolType = AnnotationType.marker;
                        if (state.selectedTool == MarkupTool.highlighter) currentToolType = AnnotationType.highlighter;
                        if (state.selectedTool == MarkupTool.strikeOut) currentToolType = AnnotationType.strikeOut;
                        if (state.selectedTool == MarkupTool.shapes) currentToolType = state.selectedShape;

                        return CustomPaint(
                          size: size,
                          painter: DrawingCanvasPainter(
                            annotations: state.annotations,
                            layerVisibility: state.layerVisibility,
                            selectedAnnotationId: state.selectedAnnotationId,
                            activeStrokePoints: state.activeStrokePoints,
                            activeColor: state.activeColor,
                            activeStrokeWidth: state.activeStrokeWidth,
                            activeToolType: currentToolType,
                            snapGuideLine: state.snapGuideLine,
                            canvasSize: size,
                            searchHighlightToken: state.searchHighlightToken,
                            isAuthorVisible: (author) => state.isAuthorVisible(author),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBaseLayer(DrawingFile drawing) {
    final path = drawing.localPath;
    if (!kIsWeb && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildBlueprintPlaceholder(),
      );
    } else if (drawing.fileUrl != null && drawing.fileUrl!.isNotEmpty && !drawing.isPdf) {
      final url = drawing.fileUrl!.startsWith('http')
          ? drawing.fileUrl!
          : 'http://localhost:8081${drawing.fileUrl}';
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildBlueprintPlaceholder(),
      );
    }
    return _buildBlueprintPlaceholder();
  }

  Widget _buildBlueprintPlaceholder() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.architecture_rounded, size: 64, color: Colors.blueGrey.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text(
              'ISOMETRIC DRAWING - ${widget.drawing.name}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.withOpacity(0.5),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'DWG: ${widget.drawing.drawingNumber ?? "ISO-3001-HC"} | REV: ${widget.drawing.revision ?? "REV 0"}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blueGrey.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
