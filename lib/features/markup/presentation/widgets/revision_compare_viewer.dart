import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/point_2d.dart';
import 'drawing_canvas_painter.dart';

enum CompareMode {
  splitSlider('Split View'),
  opacityOverlay('Opacity Blend'),
  markupDiff('Markup Diff');

  final String label;
  const CompareMode(this.label);
}

class RevisionCompareViewer extends StatefulWidget {
  final DrawingFile currentDrawing;
  final List<AnnotationItem> currentAnnotations;
  final List<AnnotationItem>? previousAnnotations;
  final String baseRevisionName;
  final String compareRevisionName;
  final bool isOutdoor;
  final bool isDark;

  const RevisionCompareViewer({
    super.key,
    required this.currentDrawing,
    required this.currentAnnotations,
    this.previousAnnotations,
    this.baseRevisionName = 'Rev 0 (Baseline)',
    this.compareRevisionName = 'Rev 1 (Current)',
    required this.isOutdoor,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required DrawingFile currentDrawing,
    required List<AnnotationItem> currentAnnotations,
    List<AnnotationItem>? previousAnnotations,
    String baseRevisionName = 'Rev 0 (Baseline)',
    String compareRevisionName = 'Rev 1 (Current)',
    required bool isOutdoor,
    required bool isDark,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.94,
        child: RevisionCompareViewer(
          currentDrawing: currentDrawing,
          currentAnnotations: currentAnnotations,
          previousAnnotations: previousAnnotations,
          baseRevisionName: baseRevisionName,
          compareRevisionName: compareRevisionName,
          isOutdoor: isOutdoor,
          isDark: isDark,
        ),
      ),
    );
  }

  @override
  State<RevisionCompareViewer> createState() => _RevisionCompareViewerState();
}

class _RevisionCompareViewerState extends State<RevisionCompareViewer> {
  CompareMode _selectedMode = CompareMode.splitSlider;
  double _sliderValue = 0.5; // 0.0 to 1.0 (50%)
  late List<AnnotationItem> _mockPreviousAnnotations;

  @override
  void initState() {
    super.initState();
    _mockPreviousAnnotations = widget.previousAnnotations ?? _generateMockPreviousRevision();
  }

  List<AnnotationItem> _generateMockPreviousRevision() {
    // Generates sample baseline Rev 0 markups for comparison demo
    return [
      AnnotationItem(
        id: 'rev0-ann-1',
        type: AnnotationType.line,
        color: const Color(0xFF185FA5),
        strokeWidth: 3.0,
        points: const [Point2D(0.2, 0.3), Point2D(0.5, 0.3)],
        author: 'Lead Drafter',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      AnnotationItem(
        id: 'rev0-ann-2',
        type: AnnotationType.text,
        color: const Color(0xFFD03A33),
        strokeWidth: 1.5,
        points: const [Point2D(0.55, 0.32)],
        text: 'OLD LINE 6"-HC-101 (REMOVED)',
        author: 'Lead Drafter',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  List<AnnotationItem> _calculateDiffAnnotations() {
    final diff = <AnnotationItem>[];

    // 1. Mark items in Rev 0 as deleted (Red)
    for (final a in _mockPreviousAnnotations) {
      diff.add(a.copyWith(
        color: const Color(0xFFD03A33),
        changeType: 'delete',
        metadata: {'diffStatus': 'deleted_in_rev1'},
      ));
    }

    // 2. Mark items in Rev 1 as added (Teal)
    for (final a in widget.currentAnnotations) {
      diff.add(a.copyWith(
        color: const Color(0xFF08605B),
        changeType: 'add',
        metadata: {'diffStatus': 'added_in_rev1'},
      ));
    }

    return diff;
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isOutdoor
        ? AppColors.outdoorSurface
        : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = widget.isOutdoor
        ? AppColors.outdoorText
        : (widget.isDark ? AppColors.darkText : AppColors.lightText);
    final outlineColor = widget.isOutdoor
        ? AppColors.outdoorOutline
        : (widget.isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final primaryColor = widget.isOutdoor
        ? AppColors.outdoorPrimary
        : (widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: outlineColor, width: widget.isOutdoor ? 1.5 : 1.0),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.compare_arrows_rounded, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revision Compare: ${widget.baseRevisionName} ➔ ${widget.compareRevisionName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Drawing: ${widget.currentDrawing.drawingNumber ?? widget.currentDrawing.name}',
                      style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
                    ),
                  ],
                ),
                const Spacer(),
                // Mode selector chips
                Wrap(
                  spacing: 6,
                  children: CompareMode.values.map((mode) {
                    final isSel = _selectedMode == mode;
                    return ChoiceChip(
                      label: Text(mode.label),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedMode = mode),
                      selectedColor: primaryColor.withOpacity(0.2),
                      backgroundColor: Colors.transparent,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? primaryColor : textColor,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Comparison Canvas
          Expanded(
            child: Container(
              color: widget.isDark ? Colors.black38 : const Color(0xFFE2E8F0),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.414,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Blueprint/Drawing
                        _buildDrawingBackground(),

                        // Mode 1: Split Slider View
                        if (_selectedMode == CompareMode.splitSlider)
                          _buildSplitSliderComparison(),

                        // Mode 2: Opacity Blend View
                        if (_selectedMode == CompareMode.opacityOverlay)
                          _buildOpacityOverlayComparison(),

                        // Mode 3: Markup Diff View
                        if (_selectedMode == CompareMode.markupDiff)
                          _buildMarkupDiffComparison(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Slider & Legend Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: outlineColor)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedMode == CompareMode.markupDiff) ...[
                    _buildDiffLegend(const Color(0xFFD03A33), 'Removed / Rev 0 only (${_mockPreviousAnnotations.length})', textColor),
                    const SizedBox(width: 16),
                    _buildDiffLegend(const Color(0xFF08605B), 'Added / Rev 1 redline (${widget.currentAnnotations.length})', textColor),
                    const SizedBox(width: 16),
                    _buildDiffLegend(const Color(0xFF185FA5), 'Unchanged base', textColor),
                  ] else ...[
                  Text(
                    _selectedMode == CompareMode.splitSlider
                        ? 'Split Position: ${(_sliderValue * 100).toInt()}% (${widget.baseRevisionName} ◀ ▶ ${widget.compareRevisionName})'
                        : 'Rev 1 Overlay Opacity: ${(_sliderValue * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: _sliderValue,
                      activeColor: primaryColor,
                      onChanged: (v) => setState(() => _sliderValue = v),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildDrawingBackground() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.architecture_rounded, size: 72, color: Colors.blueGrey.withOpacity(0.2)),
            const SizedBox(height: 6),
            Text(
              'ISOMETRIC DRAWING SHEET - ${widget.currentDrawing.drawingNumber ?? widget.currentDrawing.name}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitSliderComparison() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final splitX = width * _sliderValue;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Left Side: Base Revision Markups
            ClipRect(
              clipper: _HorizontalRectClipper(0, splitX),
              child: CustomPaint(
                painter: DrawingCanvasPainter(
                  annotations: _mockPreviousAnnotations,
                  activeStrokePoints: const [],
                  activeColor: Colors.blue,
                  activeStrokeWidth: 2,
                  canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
            ),

            // Right Side: Compare Revision Markups
            ClipRect(
              clipper: _HorizontalRectClipper(splitX, width),
              child: CustomPaint(
                painter: DrawingCanvasPainter(
                  annotations: widget.currentAnnotations,
                  activeStrokePoints: const [],
                  activeColor: Colors.teal,
                  activeStrokeWidth: 2,
                  canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
            ),

            // Draggable Split Divider Line
            Positioned(
              left: splitX - 1.5,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                color: const Color(0xFF08605B),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF08605B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.code_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOpacityOverlayComparison() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base Revision at 100% opacity
            CustomPaint(
              painter: DrawingCanvasPainter(
                annotations: _mockPreviousAnnotations,
                activeStrokePoints: const [],
                activeColor: Colors.blue,
                activeStrokeWidth: 2,
                canvasSize: size,
              ),
            ),

            // Compare Revision with interactive alpha slider
            Opacity(
              opacity: _sliderValue.clamp(0.0, 1.0),
              child: CustomPaint(
                painter: DrawingCanvasPainter(
                  annotations: widget.currentAnnotations,
                  activeStrokePoints: const [],
                  activeColor: Colors.teal,
                  activeStrokeWidth: 2,
                  canvasSize: size,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarkupDiffComparison() {
    final diffItems = _calculateDiffAnnotations();

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: DrawingCanvasPainter(
            annotations: diffItems,
            activeStrokePoints: const [],
            activeColor: Colors.orange,
            activeStrokeWidth: 2,
            canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }

  Widget _buildDiffLegend(Color color, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }
}

class _HorizontalRectClipper extends CustomClipper<Rect> {
  final double startX;
  final double endX;

  _HorizontalRectClipper(this.startX, this.endX);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(startX, 0, endX, size.height);
  }

  @override
  bool shouldReclip(_HorizontalRectClipper oldClipper) {
    return oldClipper.startX != startX || oldClipper.endX != endX;
  }
}
