import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../domain/models/drawing.dart';
import '../../domain/models/markup.dart';
import '../../domain/utils/stroke_smoother.dart';
import '../controllers/markup_controller.dart';
import 'drawing_markup_painter.dart';
import 'text_annotation_dialog.dart';
import 'annotation_comments_sheet.dart';
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

    final pagePoint = _screenToPageCoordinates(event.position);
    setState(() => _currentPointerLocation = pagePoint);

    if (widget.viewerState.isDrawingMode && widget.viewerState.selectedTool == MarkupType.text) {
      _showTextDialog(pagePoint);
      return;
    }

    if (widget.viewerState.isDrawingMode && widget.viewerState.selectedTool != null) {
      widget.controller.startDrawing(pagePoint);
      return;
    }

    // Navigation / Pointer Selection Mode (Tap to select or inspect markup)
    if (!widget.viewerState.isDrawingMode) {
      _handleSelectionTap(pagePoint);
    }
  }

  void _handleSelectionTap(Point2D pagePoint) {
    final activeMarkups = widget.viewerState.activePageMarkups;
    Markup? hitMarkup;

    for (final m in activeMarkups.reversed) {
      if (StrokeSmoother.isMarkupHit(m, pagePoint, 0.035)) {
        hitMarkup = m;
        break;
      }
    }

    if (hitMarkup != null) {
      if (widget.viewerState.selectedMarkupId == hitMarkup.id) {
        // Tapped again -> open discussion comment & review thread
        AnnotationCommentsSheet.show(
          context,
          markup: hitMarkup,
          controller: widget.controller,
        );
      } else {
        widget.controller.selectMarkup(hitMarkup.id);
      }
    } else {
      if (widget.viewerState.selectedMarkupId != null) {
        widget.controller.selectMarkup(null);
      }
    }
  }

  void _showTextDialog(Point2D position) {
    showDialog(
      context: context,
      builder: (ctx) => TextAnnotationDialog(
        initialColor: widget.viewerState.activeColor,
        initialFontSize: widget.viewerState.fontSize,
        onConfirm: (text, fontSize, rotation, withLeader) {
          Point2D? leaderPoint;
          if (withLeader) {
            leaderPoint = Point2D(
              (position.x + 0.08).clamp(0.0, 1.0),
              (position.y + 0.08).clamp(0.0, 1.0),
            );
          }
          widget.controller.addTextCallout(
            position,
            text,
            fontSize: fontSize,
            rotation: rotation,
            leaderPoint: leaderPoint,
            hasHalo: true,
          );
        },
      ),
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.viewerState.isStylusOnly && event.kind != PointerDeviceKind.stylus) {
      return;
    }

    final pagePoint = _screenToPageCoordinates(event.position);
    setState(() => _currentPointerLocation = pagePoint);

    if (widget.viewerState.isDrawingMode && widget.viewerState.selectedTool != null) {
      if (widget.viewerState.selectedTool != MarkupType.text) {
        widget.controller.updateDrawing(pagePoint);
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (widget.viewerState.isDrawingMode && widget.viewerState.selectedTool != null) {
      if (widget.viewerState.selectedTool != MarkupType.text) {
        widget.controller.finishDrawing();
      }
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
    final selectedMarkup = widget.viewerState.selectedMarkupId != null
        ? widget.viewerState.activePageMarkups
            .where((m) => m.id == widget.viewerState.selectedMarkupId)
            .firstOrNull
        : null;

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
                        // Layer 1: Base Document (PDF Blueprint or High-Resolution Site Image)
                        if (widget.viewerState.visibleLayers.contains(DrawingLayer.original))
                          _buildBaseDocumentLayer(context, isDark),

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

        // Floating Selected Markup Context Bar (Bottom Center)
        if (selectedMarkup != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.safetyOrange, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: selectedMarkup.status == 'Closed'
                            ? const Color(0xFF00E676).withOpacity(0.2)
                            : (selectedMarkup.status == 'Addressed'
                                ? Colors.blueAccent.withOpacity(0.2)
                                : AppColors.safetyOrange.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedMarkup.status.toUpperCase(),
                        style: TextStyle(
                          color: selectedMarkup.status == 'Closed'
                              ? const Color(0xFF00E676)
                              : (selectedMarkup.status == 'Addressed'
                                  ? Colors.blueAccent
                                  : AppColors.safetyOrange),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Review & Comments Thread Button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.forum_rounded, size: 16, color: Colors.cyanAccent),
                      label: const Text('Review Thread', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        AnnotationCommentsSheet.show(
                          context,
                          markup: selectedMarkup,
                          controller: widget.controller,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    // Copy / Duplicate Button
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Duplicate Markup',
                      onPressed: () {
                        widget.controller.copySelectedMarkup();
                        widget.controller.pasteMarkup();
                      },
                    ),
                    // Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      tooltip: 'Delete Markup',
                      onPressed: () {
                        widget.controller.deleteSelectedMarkup();
                      },
                    ),
                    // Deselect Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Deselect',
                      onPressed: () {
                        widget.controller.selectMarkup(null);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isImageFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.png') ||
        p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.webp') ||
        p.endsWith('.bmp') ||
        p.endsWith('.gif') ||
        p.endsWith('.tif') ||
        p.endsWith('.tiff') ||
        p.contains('image_picker') ||
        p.startsWith('data:image');
  }

  Widget _buildBaseDocumentLayer(BuildContext context, bool isDark) {
    final filePath = widget.drawing.filePath;

    if (_isImageFile(filePath)) {
      if (filePath.startsWith('data:image')) {
        try {
          final commaIndex = filePath.indexOf(',');
          if (commaIndex != -1) {
            final base64Data = filePath.substring(commaIndex + 1);
            return Image.memory(
              base64Decode(base64Data),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildFallbackVectorCanvas(isDark),
            );
          }
        } catch (_) {}
        return Image.network(
          filePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallbackVectorCanvas(isDark),
        );
      } else if (filePath.startsWith('assets/')) {
        return Image.asset(
          filePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallbackVectorCanvas(isDark),
        );
      } else if (!kIsWeb && File(filePath).existsSync()) {
        return Image.file(
          File(filePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallbackVectorCanvas(isDark),
        );
      } else {
        return Image.network(
          filePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallbackVectorCanvas(isDark),
        );
      }
    }

    // Default: PDF Document Preview
    final fileExists = !kIsWeb && File(filePath).existsSync();
    return PdfPreview(
      build: (format) async {
        if (filePath.startsWith('data:application/pdf;base64,')) {
          final base64Data = filePath.substring('data:application/pdf;base64,'.length);
          return base64Decode(base64Data);
        } else if (!kIsWeb && fileExists) {
          return await File(filePath).readAsBytes();
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
      loadingWidget: const LoadingStateView(message: 'Loading blueprint document...'),
      pdfFileName: '${widget.drawing.drawingNumber}.pdf',
    );
  }

  Widget _buildFallbackVectorCanvas(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.architecture_rounded, size: 64, color: AppColors.safetyOrange.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              widget.drawing.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.drawing.drawingNumber} • ${widget.drawing.revision}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
