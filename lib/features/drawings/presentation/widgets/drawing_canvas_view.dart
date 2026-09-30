import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../domain/models/drawing.dart';
import '../../domain/models/markup.dart';
import '../controllers/markup_controller.dart';
import 'drawing_markup_painter.dart';
import '../../../../shared/widgets/loading_state_view.dart';
import '../../../../core/theme/color_palette.dart';

class DrawingCanvasView extends StatefulWidget {
  final Drawing drawing;
  final DrawingViewerState viewerState;
  final MarkupController controller;
  final TransformationController transformationController;
  final VoidCallback? onDoubleTapReset;

  const DrawingCanvasView({
    super.key,
    required this.drawing,
    required this.viewerState,
    required this.controller,
    required this.transformationController,
    this.onDoubleTapReset,
  });

  @override
  State<DrawingCanvasView> createState() => _DrawingCanvasViewState();
}

class _DrawingCanvasViewState extends State<DrawingCanvasView> {
  final GlobalKey _canvasKey = GlobalKey();
  Point2D? _currentPointerLocation;

  Point2D _screenToPageCoordinates(Offset globalPosition) {
    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const Point2D(0, 0);

    final localPosition = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;

    final normalizedX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / size.height).clamp(0.0, 1.0);

    return Point2D(normalizedX, normalizedY);
  }

  void _handlePointerDown(PointerDownEvent event) {
    // If stylus-only mode is active and pointer is not stylus, ignore drawing
    if (widget.viewerState.isStylusOnly && event.kind != PointerDeviceKind.stylus) {
      return;
    }

    if (widget.viewerState.isDrawingMode && widget.viewerState.selectedTool != null) {
      final pagePoint = _screenToPageCoordinates(event.position);
      setState(() => _currentPointerLocation = pagePoint);
      widget.controller.startDrawing(pagePoint);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.viewerState.isStylusOnly && event.kind != PointerDeviceKind.stylus) {
      return;
    }

    final pagePoint = _screenToPageCoordinates(event.position);
    setState(() => _currentPointerLocation = pagePoint);

    if (widget.viewerState.isDrawingMode && widget.viewerState.selectedTool != null) {
      widget.controller.updateDrawing(pagePoint);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (widget.viewerState.isDrawingMode && widget.viewerState.selectedTool != null) {
      widget.controller.finishDrawing();
    }
  }

  void _handleDoubleTap() {
    final currentScale = widget.transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.2) {
      // Reset to 1.0x
      widget.transformationController.value = Matrix4.identity();
    } else {
      // Quick zoom into 2.5x
      widget.transformationController.value = Matrix4.identity()..scale(2.5);
    }
    if (widget.onDoubleTapReset != null) widget.onDoubleTapReset!();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileExists = !kIsWeb && File(widget.drawing.filePath).existsSync();

    return Stack(
      children: [
        // Interactive Zoom & Pan Viewport
        GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: widget.transformationController,
            minScale: 0.5,
            maxScale: 10.0,
            boundaryMargin: const EdgeInsets.all(300),
            panEnabled: !widget.viewerState.isDrawingMode,
            scaleEnabled: !widget.viewerState.isDrawingMode,
            child: Center(
              child: AspectRatio(
                // Standard A3 Landscape engineering aspect ratio (420mm / 297mm ≈ 1.414)
                aspectRatio: 1.414,
                child: Listener(
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerUp: _handlePointerUp,
                  child: Container(
                    key: _canvasKey,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF13171F) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Layer 1: Base PDF Document (Vector Blueprint)
                        if (widget.viewerState.visibleLayers.contains(DrawingLayer.original))
                          PdfPreview(
                            build: (format) async {
                              if (!kIsWeb && fileExists) {
                                return await File(widget.drawing.filePath).readAsBytes();
                              } else {
                                // Fast web bundle / fallback loading
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
                            loadingWidget: const LoadingStateView(message: 'Loading blueprint...'),
                            pdfFileName: '${widget.drawing.drawingNumber}.pdf',
                          ),

                        // Layer 2: Custom Markup & Annotation Layer
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(constraints.maxWidth, constraints.maxHeight);
                            return CustomPaint(
                              size: size,
                              painter: DrawingMarkupPainter(
                                viewerState: widget.viewerState,
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

        // Live Coordinate HUD Pill (Bottom Left)
        if (_currentPointerLocation != null)
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.my_location_rounded, color: AppColors.safetyOrange, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'PAGE COORD: X: ${(_currentPointerLocation!.x * 100).toStringAsFixed(1)}% | Y: ${(_currentPointerLocation!.y * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
