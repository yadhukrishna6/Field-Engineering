import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/drawing.dart';
import '../../domain/models/drawing_revision.dart';
import '../providers/revisions_provider.dart';

enum ComparisonMode {
  sideBySide,
  sliderWipe,
  diffOverlay,
}

class RevisionComparisonScreen extends ConsumerStatefulWidget {
  final Drawing drawing;

  const RevisionComparisonScreen({
    super.key,
    required this.drawing,
  });

  @override
  ConsumerState<RevisionComparisonScreen> createState() => _RevisionComparisonScreenState();
}

class _RevisionComparisonScreenState extends ConsumerState<RevisionComparisonScreen> {
  ComparisonMode _mode = ComparisonMode.sliderWipe;
  double _wipePosition = 0.5; // 0.0 to 1.0 for wipe slider
  DrawingRevision? _selectedPreviousRevision;
  DrawingRevision? _selectedCurrentRevision;
  bool _highlightDiffs = true;

  @override
  Widget build(BuildContext context) {
    final revisionsAsync = ref.watch(drawingRevisionsProvider(widget.drawing.id));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revision Comparison — ${widget.drawing.drawingNumber}',
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.drawing.title,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Mode toggle segmented button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: SegmentedButton<ComparisonMode>(
              segments: const [
                ButtonSegment(
                  value: ComparisonMode.sliderWipe,
                  label: Text('Slider Wipe'),
                  icon: Icon(Icons.compare, size: 16),
                ),
                ButtonSegment(
                  value: ComparisonMode.sideBySide,
                  label: Text('Side-by-Side'),
                  icon: Icon(Icons.view_column, size: 16),
                ),
                ButtonSegment(
                  value: ComparisonMode.diffOverlay,
                  label: Text('Diff Layer'),
                  icon: Icon(Icons.layers_outlined, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (set) {
                setState(() {
                  _mode = set.first;
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
                backgroundColor: AppColors.surfaceDark,
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _highlightDiffs ? Icons.highlight : Icons.highlight_off,
              color: _highlightDiffs ? AppColors.accent : AppColors.textSecondary,
            ),
            tooltip: _highlightDiffs ? 'Highlights Active' : 'Highlights Off',
            onPressed: () {
              setState(() {
                _highlightDiffs = !_highlightDiffs;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: revisionsAsync.when(
        data: (revisions) {
          if (revisions.isEmpty) {
            return const Center(child: Text('No revisions available to compare.'));
          }

          // Default selection if not yet set
          if (_selectedPreviousRevision == null && revisions.length > 1) {
            _selectedPreviousRevision = revisions.last; // Older revision (e.g. Rev 00)
          } else if (_selectedPreviousRevision == null) {
            _selectedPreviousRevision = revisions.first;
          }

          if (_selectedCurrentRevision == null) {
            _selectedCurrentRevision = revisions.first; // Newer revision (e.g. Rev 01)
          }

          return Column(
            children: [
              // Revision selector bar
              _buildRevisionSelectorBar(revisions),
              // Comparison Canvas
              Expanded(
                child: _buildComparisonCanvas(),
              ),
              // Revision Details & Legend Footer
              _buildComparisonLegend(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading revisions: $e')),
      ),
    );
  }

  Widget _buildRevisionSelectorBar(List<DrawingRevision> revisions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surfaceDark,
      child: Row(
        children: [
          // Previous Revision (Base)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text('Previous Revision: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 4),
                  DropdownButton<DrawingRevision>(
                    value: _selectedPreviousRevision,
                    dropdownColor: AppColors.cardDark,
                    underline: const SizedBox(),
                    items: revisions.map((rev) {
                      return DropdownMenuItem(
                        value: rev,
                        child: Text('${rev.revisionNumber} (${rev.status.displayName})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPreviousRevision = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward, color: AppColors.textSecondary),
          ),
          // Current Revision (Target)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text('Current Revision: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 4),
                  DropdownButton<DrawingRevision>(
                    value: _selectedCurrentRevision,
                    dropdownColor: AppColors.cardDark,
                    underline: const SizedBox(),
                    items: revisions.map((rev) {
                      return DropdownMenuItem(
                        value: rev,
                        child: Text('${rev.revisionNumber} (${rev.status.displayName})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCurrentRevision = val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCanvas() {
    switch (_mode) {
      case ComparisonMode.sideBySide:
        return Row(
          children: [
            Expanded(
              child: _buildDrawingView(
                revision: _selectedPreviousRevision,
                title: 'PREVIOUS: ${_selectedPreviousRevision?.revisionNumber ?? ""}',
                badgeColor: Colors.redAccent,
                isPrevious: true,
              ),
            ),
            Container(width: 2, color: Colors.grey.shade800),
            Expanded(
              child: _buildDrawingView(
                revision: _selectedCurrentRevision,
                title: 'CURRENT: ${_selectedCurrentRevision?.revisionNumber ?? ""}',
                badgeColor: Colors.greenAccent,
                isPrevious: false,
              ),
            ),
          ],
        );

      case ComparisonMode.sliderWipe:
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final wipeX = width * _wipePosition;

            return Stack(
              children: [
                // Underneath Layer: Current Revision (Green tint)
                Positioned.fill(
                  child: _buildDrawingCanvasContent(
                    revision: _selectedCurrentRevision,
                    tint: Colors.green.withOpacity(0.05),
                    isPrevious: false,
                  ),
                ),
                // Top Clipped Layer: Previous Revision (Red tint)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: wipeX,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxWidth: width,
                      minWidth: width,
                      child: _buildDrawingCanvasContent(
                        revision: _selectedPreviousRevision,
                        tint: Colors.red.withOpacity(0.05),
                        isPrevious: true,
                      ),
                    ),
                  ),
                ),
                // Vertical Split Divider Bar
                Positioned(
                  left: wipeX - 16,
                  top: 0,
                  bottom: 0,
                  width: 32,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _wipePosition = (_wipePosition + details.delta.dx / width).clamp(0.05, 0.95);
                      });
                    },
                    child: Center(
                      child: Container(
                        width: 4,
                        color: AppColors.accent,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 32,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.drag_indicator, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Left & Right Floating Labels
                Positioned(
                  left: 16,
                  top: 16,
                  child: _buildFloatingRevisionBadge(
                    '${_selectedPreviousRevision?.revisionNumber ?? ""} (Baseline)',
                    Colors.redAccent,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: _buildFloatingRevisionBadge(
                    '${_selectedCurrentRevision?.revisionNumber ?? ""} (Latest)',
                    Colors.greenAccent,
                  ),
                ),
              ],
            );
          },
        );

      case ComparisonMode.diffOverlay:
        return Stack(
          children: [
            Positioned.fill(
              child: _buildDrawingCanvasContent(
                revision: _selectedCurrentRevision,
                tint: Colors.transparent,
                isPrevious: false,
              ),
            ),
            if (_highlightDiffs)
              Positioned.fill(
                child: CustomPaint(
                  painter: RevisionDiffPainter(),
                ),
              ),
            Positioned(
              left: 16,
              top: 16,
              child: _buildFloatingRevisionBadge(
                'Delta Overlay: Red = Removed, Green = Added, Yellow = Modified',
                AppColors.accent,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildFloatingRevisionBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.8), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDrawingView({
    required DrawingRevision? revision,
    required String title,
    required Color badgeColor,
    required bool isPrevious,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: badgeColor.withOpacity(0.15),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              if (revision != null)
                Text(
                  'Uploaded: ${DateFormat('yyyy-MM-dd').format(revision.uploadedAt)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildDrawingCanvasContent(
            revision: revision,
            tint: badgeColor.withOpacity(0.04),
            isPrevious: isPrevious,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingCanvasContent({
    required DrawingRevision? revision,
    required Color tint,
    required bool isPrevious,
  }) {
    return Container(
      color: tint == Colors.transparent ? AppColors.surfaceDark : tint,
      child: InteractiveViewer(
        maxScale: 5.0,
        minScale: 0.5,
        child: Center(
          child: CustomPaint(
            size: const Size(800, 600),
            painter: EngineeringCADDrawingPainter(
              isPrevious: isPrevious,
              highlightChanges: _highlightDiffs,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surfaceDark,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Text(
            'Description: ${_selectedCurrentRevision?.revisionDescription ?? "No change notes provided."}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          _buildLegendChip(Colors.greenAccent, 'Added in ${_selectedCurrentRevision?.revisionNumber ?? "Latest"}'),
          const SizedBox(width: 12),
          _buildLegendChip(Colors.redAccent, 'Removed from ${_selectedPreviousRevision?.revisionNumber ?? "Baseline"}'),
          const SizedBox(width: 12),
          _buildLegendChip(Colors.amberAccent, 'Modified Specs'),
        ],
      ),
    );
  }

  Widget _buildLegendChip(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
      ],
    );
  }
}

/// Specialized CAD & P&ID Drawing Painter demonstrating revision changes
class EngineeringCADDrawingPainter extends CustomPainter {
  final bool isPrevious;
  final bool highlightChanges;

  EngineeringCADDrawingPainter({
    required this.isPrevious,
    required this.highlightChanges,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background blueprint grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Border
    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(20, 20, size.width - 40, size.height - 40), borderPaint);

    final linePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Common Vessel Tank (V-101)
    final vesselRect = Rect.fromLTWH(100, 150, 180, 300);
    canvas.drawRRect(RRect.fromRectAndRadius(vesselRect, const Radius.circular(24)), linePaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: 'HIGH PRESSURE SEPARATOR\nV-101\nDesign: 45 Barg / 85°C',
      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(115, 260));

    // Main 8" Process Line
    canvas.drawLine(const Offset(280, 220), const Offset(650, 220), linePaint);

    // Pump P-102
    canvas.drawCircle(const Offset(450, 220), 22, linePaint);
    textPainter.text = const TextSpan(
      text: 'P-102A/B\n8"-HC-1002-CS',
      style: TextStyle(color: Colors.white60, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(420, 250));

    if (isPrevious) {
      // Old Revision (Rev 00) had manual globe valve and no bypass
      final oldValvePaint = Paint()
        ..color = highlightChanges ? Colors.redAccent : Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawLine(const Offset(550, 200), const Offset(550, 240), oldValvePaint);
      canvas.drawCircle(const Offset(550, 220), 8, oldValvePaint);

      textPainter.text = TextSpan(
        text: 'OLD GLOBE VALVE\n(Removed in Rev 01)',
        style: TextStyle(color: highlightChanges ? Colors.redAccent : Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(510, 165));
    } else {
      // New Revision (Rev 01) added automated control valve, PSV relief line, and 4" bypass
      final newPaint = Paint()
        ..color = highlightChanges ? Colors.greenAccent : Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      // Automated Control Valve FCV-101
      canvas.drawRect(const Rect.fromLTWH(540, 210, 20, 20), newPaint);
      canvas.drawLine(const Offset(550, 210), const Offset(550, 190), newPaint);
      canvas.drawCircle(const Offset(550, 185), 7, newPaint);

      // 4" Bypass Line
      final bypassPath = Path()
        ..moveTo(380, 220)
        ..lineTo(380, 360)
        ..lineTo(600, 360)
        ..lineTo(600, 220);
      canvas.drawPath(bypassPath, newPaint);

      textPainter.text = TextSpan(
        text: 'NEW 4" BYPASS & FCV-101\n(Added in Rev 01)',
        style: TextStyle(color: highlightChanges ? Colors.greenAccent : Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(420, 375));
    }
  }

  @override
  bool shouldRepaint(covariant EngineeringCADDrawingPainter oldDelegate) {
    return oldDelegate.isPrevious != isPrevious || oldDelegate.highlightChanges != highlightChanges;
  }
}

class RevisionDiffPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Diff Cloud Highlights
    final addCloudPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final addCloudBorder = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Green Highlight Box for Added Bypass
    final addedRect = Rect.fromLTWH(360, 340, 260, 70);
    canvas.drawRRect(RRect.fromRectAndRadius(addedRect, const Radius.circular(8)), addCloudPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(addedRect, const Radius.circular(8)), addCloudBorder);

    // Red Highlight Box for Removed Valve
    final remCloudPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final remCloudBorder = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final removedRect = Rect.fromLTWH(520, 160, 80, 90);
    canvas.drawRRect(RRect.fromRectAndRadius(removedRect, const Radius.circular(8)), remCloudPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(removedRect, const Radius.circular(8)), remCloudBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
