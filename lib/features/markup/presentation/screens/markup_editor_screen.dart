import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/markup_layer.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/utils/markup_pdf_exporter.dart';
import '../controllers/drawings_list_controller.dart';
import '../controllers/markup_editor_controller.dart';
import '../widgets/add_label_sheet.dart';
import '../widgets/drawing_canvas_painter.dart';
import '../widgets/layers_panel.dart';
import '../widgets/markup_bottom_toolbar.dart';
import '../widgets/minimap_view.dart';
import '../widgets/shapes_selection_popup.dart';
import '../widgets/snap_settings_chip.dart';
import '../widgets/theme_selector_modal.dart';

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

  Future<void> _exportPdf() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating client-ready Vector PDF with embedded markups...'),
          duration: Duration(seconds: 1),
        ),
      );
      final repo = ref.read(markupRepositoryProvider);
      final pdfBytes = await MarkupPdfExporter.exportFlattenedPdf(
        drawing: widget.drawing,
        repository: repo,
      );
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${widget.drawing.name}_markup.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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

    final isOutdoor = themeState.isOutdoorActive;
    final isDark = themeState.isDarkActive;

    final backgroundColor = isOutdoor
        ? AppColors.outdoorBackground
        : (isDark ? AppColors.darkBackground : AppColors.lightBackground);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletLandscape = screenWidth >= 768;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: state.isFullscreen
          ? null
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.drawing.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isOutdoor ? 17 : 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (widget.drawing.pageCount > 1) ...[
                        Text(
                          'Page ${state.currentPage} of ${widget.drawing.pageCount}',
                          style: TextStyle(
                            fontSize: isOutdoor ? 12 : 11,
                            color: isOutdoor ? AppColors.outdoorSecondaryText : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        state.isAutosaving
                            ? 'Saving...'
                            : (state.hasUnsavedChanges ? 'Edited' : 'Saved'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: state.isAutosaving
                              ? Colors.amber
                              : (isOutdoor ? AppColors.outdoorInkGreen : Colors.greenAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                if (widget.drawing.pageCount > 1) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Previous Sheet',
                    onPressed: state.currentPage > 1 ? () => controller.setPage(state.currentPage - 1) : null,
                  ),
                  Center(
                    child: Text(
                      '${state.currentPage}/${widget.drawing.pageCount}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isOutdoor ? 14 : 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next Sheet',
                    onPressed: state.currentPage < widget.drawing.pageCount ? () => controller.setPage(state.currentPage + 1) : null,
                  ),
                ],
                IconButton(
                  icon: Icon(Icons.palette_outlined, color: primaryColor),
                  tooltip: 'Display Theme',
                  onPressed: () => ThemeSelectorModal.show(context),
                ),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf_rounded, color: primaryColor),
                  tooltip: 'Export Vector PDF',
                  onPressed: _exportPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.save_rounded),
                  tooltip: 'Save Markups',
                  onPressed: () => controller.saveNow(),
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left Tool Rail (Tablet Landscape & Desktop)
                if (isTabletLandscape)
                  _buildLeftToolRail(context, state, controller, isOutdoor, isDark),

                // Main Canvas Area with Overlays
                Expanded(
                  child: Stack(
                    children: [
                      // Interactive Drawing Canvas (White paper in ALL themes)
                      Positioned.fill(
                        child: _buildCanvasArea(state, controller, isDark),
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
                            onToggleLayer: (l) => controller.toggleLayer(l),
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phone Tools Rail / Bottom Bar
          if (!isTabletLandscape)
            _buildPhoneToolRail(context, state, controller, isOutdoor, isDark),

          // Bottom Bar
          MarkupBottomToolbar(
            state: state,
            controller: controller,
            onResetZoom: _handleResetZoom,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftToolRail(
    BuildContext context,
    MarkupEditorState state,
    MarkupEditorController controller,
    bool isOutdoor,
    bool isDark,
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
      {'tool': MarkupTool.shapes, 'icon': Icons.category_rounded, 'label': 'Shapes'},
      {'tool': MarkupTool.photo, 'icon': Icons.camera_alt_rounded, 'label': 'Photo'},
      {'tool': MarkupTool.voiceNote, 'icon': Icons.mic_rounded, 'label': 'Voice'},
      {'tool': MarkupTool.eraser, 'icon': Icons.auto_fix_high_rounded, 'label': 'Eraser'},
    ];

    return Container(
      width: isOutdoor ? 84 : 76,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(right: BorderSide(color: outlineColor, width: isOutdoor ? 1.5 : 1.0)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: tools.map((t) {
          final tool = t['tool'] as MarkupTool;
          final isSelected = state.selectedTool == tool;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isOutdoor ? 6 : 8, vertical: isOutdoor ? 4 : 4),
            child: InkWell(
              onTap: () {
                if (tool == MarkupTool.shapes) {
                  _showShapesPopup(context, state, controller);
                } else {
                  controller.selectTool(tool);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: BoxConstraints(minHeight: isOutdoor ? 52 : 44), // Min 48dp touch target
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                      size: isOutdoor ? 24 : 22,
                      color: isSelected ? primaryColor : textColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: isOutdoor ? 11 : 10,
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

  Widget _buildPhoneToolRail(
    BuildContext context,
    MarkupEditorState state,
    MarkupEditorController controller,
    bool isOutdoor,
    bool isDark,
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
      {'tool': MarkupTool.shapes, 'icon': Icons.category_rounded, 'label': 'Shapes'},
      {'tool': MarkupTool.photo, 'icon': Icons.camera_alt_rounded, 'label': 'Photo'},
      {'tool': MarkupTool.voiceNote, 'icon': Icons.mic_rounded, 'label': 'Voice'},
      {'tool': MarkupTool.eraser, 'icon': Icons.auto_fix_high_rounded, 'label': 'Eraser'},
    ];

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: outlineColor, width: isOutdoor ? 1.5 : 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tools.map((t) {
            final tool = t['tool'] as MarkupTool;
            final isSelected = state.selectedTool == tool;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                avatar: Icon(t['icon'] as IconData, size: isOutdoor ? 18 : 16, color: isSelected ? primaryColor : textColor),
                label: Text(t['label'] as String, style: TextStyle(fontSize: isOutdoor ? 13 : 12)),
                selected: isSelected,
                selectedColor: primaryColor.withOpacity(0.18),
                onSelected: (_) {
                  if (tool == MarkupTool.shapes) {
                    _showShapesPopup(context, state, controller);
                  } else {
                    controller.selectTool(tool);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCanvasArea(
    MarkupEditorState state,
    MarkupEditorController controller,
    bool isDark,
  ) {
    final showOriginal = state.layerVisibility[MarkupLayer.originalDrawing] ?? true;

    return GestureDetector(
      onDoubleTap: _handleResetZoom,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 8.0,
        boundaryMargin: const EdgeInsets.all(200),
        panEnabled: !state.allowFingerDrawing,
        scaleEnabled: true,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.414, // A3 Landscape proportion
            child: Listener(
              onPointerDown: (event) {
                if (!state.allowFingerDrawing && event.kind != PointerDeviceKind.stylus) {
                  return;
                }

                final p = _screenToPage(event.position);
                _pointerDownPoint = p;

                if (state.selectedTool == MarkupTool.eraser) {
                  controller.eraseAt(p);
                } else if (state.selectedTool == MarkupTool.text) {
                  AnnotationItem? hitItem;
                  for (int i = state.annotations.length - 1; i >= 0; i--) {
                    final a = state.annotations[i];
                    if (a.type == AnnotationType.text && a.points.isNotEmpty) {
                      final origin = a.points.first;
                      if (p.x >= origin.x - 0.04 && p.x <= origin.x + 0.18 &&
                          p.y >= origin.y - 0.04 && p.y <= origin.y + 0.08) {
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
                } else {
                  controller.appendStrokePoint(p);
                }
              },
              onPointerUp: (event) {
                final p = _screenToPage(event.position);

                if (state.selectedTool == MarkupTool.text) {
                  if (_isDraggingAnnotation) {
                    _isDraggingAnnotation = false;
                    controller.finishMoveLabel();
                  } else if (_pointerDownPoint != null) {
                    final dist = (p.x - _pointerDownPoint!.x).abs() + (p.y - _pointerDownPoint!.y).abs();
                    if (dist < 0.02 && state.selectedAnnotationId == null) {
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
                } else if (state.selectedTool != MarkupTool.eraser) {
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
    if (drawing.isPdf) {
      final fileExists = !kIsWeb && File(path).existsSync();
      return PdfPreview(
        build: (format) async {
          if (!kIsWeb && fileExists) {
            return await File(path).readAsBytes();
          } else {
            try {
              final bd = await rootBundle.load('assets/sample_drawings/pid_drawing_sample.pdf');
              return bd.buffer.asUint8List();
            } catch (_) {
              return Uint8List(0);
            }
          }
        },
        useActions: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        dynamicLayout: false,
        maxPageWidth: 1600,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        pdfFileName: '${drawing.name}.pdf',
      );
    } else {
      if (!kIsWeb && File(path).existsSync()) {
        return Image.file(File(path), fit: BoxFit.contain);
      } else {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.architecture_rounded, size: 64, color: AppColors.lightPrimary),
              const SizedBox(height: 8),
              Text(drawing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            ],
          ),
        );
      }
    }
  }
}
