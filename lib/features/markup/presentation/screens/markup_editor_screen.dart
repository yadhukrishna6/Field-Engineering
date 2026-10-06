import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/point_2d.dart';
import '../../domain/models/text_label.dart';
import '../../domain/utils/markup_pdf_exporter.dart';
import '../../domain/utils/stroke_smoother.dart';
import '../controllers/drawings_list_controller.dart';
import '../controllers/markup_editor_controller.dart';
import '../widgets/add_label_sheet.dart';
import '../widgets/drawing_canvas_painter.dart';
import '../widgets/markup_bottom_toolbar.dart';

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
  bool _isDraggingLabel = false;

  Point2D _screenToPage(Offset globalPos) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return const Point2D(0, 0);
    final local = box.globalToLocal(globalPos);
    return Point2D(
      (local.dx / box.size.width).clamp(0.0, 1.0),
      (local.dy / box.size.height).clamp(0.0, 1.0),
    );
  }

  void _handleDoubleTapReset() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.2) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.2);
    }
  }

  Future<void> _exportPdf() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating client-ready Vector PDF with engineering font...'),
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
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(markupEditorControllerProvider(widget.drawing));
    final controller = ref.read(markupEditorControllerProvider(widget.drawing).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1218) : const Color(0xFFDDE3EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.drawing.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                if (widget.drawing.pageCount > 1) ...[
                  Text(
                    'Page ${state.currentPage} of ${widget.drawing.pageCount}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                    color: state.isAutosaving ? Colors.amber : Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Multi-page navigation for PDFs
          if (widget.drawing.pageCount > 1) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous Sheet',
              onPressed: state.currentPage > 1
                  ? () => controller.setPage(state.currentPage - 1)
                  : null,
            ),
            Center(
              child: Text(
                '${state.currentPage}/${widget.drawing.pageCount}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next Sheet',
              onPressed: state.currentPage < widget.drawing.pageCount
                  ? () => controller.setPage(state.currentPage + 1)
                  : null,
            ),
          ],

          // Undo
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo',
            onPressed: state.canUndo ? () => controller.undo() : null,
          ),

          // Redo
          IconButton(
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'Redo',
            onPressed: state.canRedo ? () => controller.redo() : null,
          ),

          // PDF Vector Export
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.safetyOrange),
            tooltip: 'Export Vector PDF',
            onPressed: _exportPdf,
          ),

          // Force Save
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Save Markups',
            onPressed: () => controller.saveNow(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Interactive Zoomable Drawing Canvas
          GestureDetector(
            onDoubleTap: _handleDoubleTapReset,
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

                      if (state.selectedTool == MarkupTool.pen) {
                        controller.startStroke(p);
                      } else if (state.selectedTool == MarkupTool.eraser) {
                        controller.eraseAt(p);
                      } else if (state.selectedTool == MarkupTool.text) {
                        // Check if tapped on existing label
                        TextLabel? hitLabel;
                        for (int i = state.labels.length - 1; i >= 0; i--) {
                          if (StrokeSmoother.isLabelHit(state.labels[i], p)) {
                            hitLabel = state.labels[i];
                            break;
                          }
                        }

                        if (hitLabel != null) {
                          controller.selectLabel(hitLabel.id);
                          _isDraggingLabel = true;
                        } else {
                          controller.selectLabel(null);
                          _isDraggingLabel = false;
                        }
                      }
                    },
                    onPointerMove: (event) {
                      if (!state.allowFingerDrawing && event.kind != PointerDeviceKind.stylus) {
                        return;
                      }

                      final p = _screenToPage(event.position);

                      if (state.selectedTool == MarkupTool.pen) {
                        controller.appendStrokePoint(p);
                      } else if (state.selectedTool == MarkupTool.eraser) {
                        controller.eraseAt(p);
                      } else if (state.selectedTool == MarkupTool.text) {
                        if (_isDraggingLabel && state.selectedLabelId != null) {
                          controller.moveLabel(state.selectedLabelId!, p);
                        }
                      }
                    },
                    onPointerUp: (event) {
                      final p = _screenToPage(event.position);

                      if (state.selectedTool == MarkupTool.pen) {
                        controller.finishStroke();
                      } else if (state.selectedTool == MarkupTool.text) {
                        if (_isDraggingLabel) {
                          _isDraggingLabel = false;
                          controller.finishMoveLabel();
                        } else if (_pointerDownPoint != null) {
                          final dist = (p.x - _pointerDownPoint!.x).abs() + (p.y - _pointerDownPoint!.y).abs();
                          // If it was a quick tap with minimal movement on empty space:
                          if (dist < 0.02 && state.selectedLabelId == null) {
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
                      }
                      _pointerDownPoint = null;
                    },
                    child: Container(
                      key: _canvasKey,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF13171F) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Base Blueprint / Image Layer
                          _buildBaseLayer(widget.drawing, isDark),

                          // Custom Vector Pen & Text Markup Layer
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);
                              return CustomPaint(
                                size: size,
                                painter: DrawingCanvasPainter(
                                  strokes: state.strokes,
                                  labels: state.labels,
                                  selectedLabelId: state.selectedLabelId,
                                  activeStrokePoints: state.activeStrokePoints,
                                  activeColor: state.activeColor,
                                  activeStrokeWidth: state.activeStrokeWidth,
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
          ),

          // Bottom Pen & Color Toolbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MarkupBottomToolbar(
              state: state,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseLayer(DrawingFile drawing, bool isDark) {
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
        loadingWidget: const Center(child: CircularProgressIndicator(color: AppColors.safetyOrange)),
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
              Icon(Icons.architecture_rounded, size: 64, color: AppColors.safetyOrange.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text(drawing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        );
      }
    }
  }
}
