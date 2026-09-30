import 'package:flutter/material.dart';

enum SplitPanelType {
  none,
  issues,
  inspections,
  equipment,
  takeoff,
  symbols,
  asBuiltWorkflow,
  copilot,
}

extension SplitPanelTypeExtension on SplitPanelType {
  String get title {
    switch (this) {
      case SplitPanelType.none:
        return 'Full Drawing';
      case SplitPanelType.issues:
        return 'Field Issues & Punch List';
      case SplitPanelType.inspections:
        return 'Active Inspection Checklist';
      case SplitPanelType.equipment:
        return 'Equipment Master Tag Link';
      case SplitPanelType.takeoff:
        return 'Material Takeoff (MTO)';
      case SplitPanelType.symbols:
        return 'P&ID Symbols & Stamps';
      case SplitPanelType.asBuiltWorkflow:
        return 'As-Built Certification Lifecycle';
      case SplitPanelType.copilot:
        return 'Field AI Copilot Assistant';
    }
  }

  IconData get icon {
    switch (this) {
      case SplitPanelType.none:
        return Icons.fullscreen_rounded;
      case SplitPanelType.issues:
        return Icons.report_problem_rounded;
      case SplitPanelType.inspections:
        return Icons.checklist_rounded;
      case SplitPanelType.equipment:
        return Icons.precision_manufacturing_rounded;
      case SplitPanelType.takeoff:
        return Icons.inventory_2_rounded;
      case SplitPanelType.symbols:
        return Icons.architecture_rounded;
      case SplitPanelType.asBuiltWorkflow:
        return Icons.verified_user_rounded;
      case SplitPanelType.copilot:
        return Icons.auto_awesome_rounded;
    }
  }
}

class DrawingSplitView extends StatefulWidget {
  final Widget drawingWidget;
  final Widget? sidePanelWidget;
  final SplitPanelType activePanelType;
  final ValueChanged<SplitPanelType> onPanelTypeChanged;
  final double initialSplitRatio; // e.g. 0.65 for 65% drawing, 35% side panel

  const DrawingSplitView({
    super.key,
    required this.drawingWidget,
    this.sidePanelWidget,
    required this.activePanelType,
    required this.onPanelTypeChanged,
    this.initialSplitRatio = 0.65,
  });

  @override
  State<DrawingSplitView> createState() => _DrawingSplitViewState();
}

class _DrawingSplitViewState extends State<DrawingSplitView> {
  late double _splitRatio;

  @override
  void initState() {
    super.initState();
    _splitRatio = widget.initialSplitRatio;
  }

  @override
  Widget build(BuildContext context) {
    final isSplitActive = widget.activePanelType != SplitPanelType.none && widget.sidePanelWidget != null;

    if (!isSplitActive) {
      return widget.drawingWidget;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftWidth = totalWidth * _splitRatio;
        final rightWidth = totalWidth * (1.0 - _splitRatio);

        return Row(
          children: [
            // Left Workspace: The Drawing Canvas
            SizedBox(
              width: leftWidth,
              child: widget.drawingWidget,
            ),

            // Draggable Divider Bar
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  final newRatio = _splitRatio + (details.delta.dx / totalWidth);
                  _splitRatio = newRatio.clamp(0.40, 0.80);
                });
              },
              child: Container(
                width: 14,
                color: const Color(0xFF10141D),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Right Companion Workspace
            SizedBox(
              width: rightWidth - 14,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF161B26),
                  border: Border(left: BorderSide(color: Color(0xFF2A3445), width: 1)),
                ),
                child: Column(
                  children: [
                    // Header with active panel title and close button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF121620),
                        border: Border(bottom: BorderSide(color: Color(0xFF2A3445))),
                      ),
                      child: Row(
                        children: [
                          Icon(widget.activePanelType.icon, color: Colors.cyanAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.activePanelType.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => widget.onPanelTypeChanged(SplitPanelType.none),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: widget.sidePanelWidget!),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
