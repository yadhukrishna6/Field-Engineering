import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../domain/models/drawing_type.dart';
import '../../domain/models/markup.dart';
import '../../domain/models/drawing_calibration.dart';
import '../controllers/drawings_controller.dart';
import '../controllers/markup_controller.dart';
import '../widgets/drawing_canvas_view.dart';
import '../widgets/markup_toolbar.dart';
import '../widgets/layer_management_panel.dart';
import '../widgets/thumbnail_navigation_drawer.dart';
import '../widgets/calibration_dialog.dart';
import '../widgets/count_tool_dialog.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/storage/storage_models.dart';
import '../../../../shared/widgets/loading_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';

class DrawingDetailsScreen extends ConsumerStatefulWidget {
  final String drawingId;

  const DrawingDetailsScreen({
    super.key,
    required this.drawingId,
  });

  @override
  ConsumerState<DrawingDetailsScreen> createState() => _DrawingDetailsScreenState();
}

class _DrawingDetailsScreenState extends ConsumerState<DrawingDetailsScreen> {
  final TransformationController _transformationController = TransformationController();
  bool _showInspector = false;
  bool _showLayerPanel = false;
  bool _showThumbnailDrawer = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  void _fitToScreen() {
    setState(() {
      _transformationController.value = Matrix4.identity()..scale(1.0);
    });
  }

  // --- Dialogs for Specialized Engineering Annotations ---

  void _showAddTextDialog(MarkupController controller) {
    final textController = TextEditingController(text: 'Note: Verify tie-in location on site');
    double fontSize = 14.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.text_fields_rounded, color: AppColors.safetyOrange),
                  SizedBox(width: 8),
                  Text('Add Text Callout'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Annotation Note / Tag Callout',
                      hintText: 'e.g. 6"-HC-1001 Tie-in requires field verification',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size:'),
                      DropdownButton<double>(
                        value: fontSize,
                        items: [10.0, 12.0, 14.0, 18.0, 24.0, 32.0]
                            .map((s) => DropdownMenuItem(value: s, child: Text('${s.toInt()} pt')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => fontSize = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (textController.text.trim().isNotEmpty) {
                      // Add to center of page
                      controller.addTextCallout(
                        const Point2D(0.4, 0.45),
                        textController.text.trim(),
                        fontSize: fontSize,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Place Callout'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddIssueDialog(MarkupController controller) {
    final tagController = TextEditingController(text: 'PNC-${DateTime.now().millisecondsSinceEpoch % 1000}');
    final titleController = TextEditingController(text: 'Flange bolt torque verification required');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Pin Punchlist Issue'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tagController,
                decoration: const InputDecoration(labelText: 'Issue Punch Tag *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Non-Conformance / Action Item *'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                if (tagController.text.trim().isNotEmpty) {
                  controller.addIssuePin(
                    const Point2D(0.5, 0.5),
                    issueTag: tagController.text.trim(),
                    title: titleController.text.trim(),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Place Issue Pin', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPhotoDialog(MarkupController controller) {
    final captionController = TextEditingController(text: 'Weld joint W-04 visual inspection photo');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.photo_camera_rounded, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('Pin Field Inspection Photo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: captionController,
                decoration: const InputDecoration(labelText: 'Photo Caption / Location Note'),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.online, size: 16),
                  SizedBox(width: 8),
                  Text('Photo linked to local device camera cache', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
              onPressed: () {
                controller.addPhotoPin(
                  const Point2D(0.5, 0.5),
                  photoPath: 'photo_local_cache.jpg',
                  caption: captionController.text.trim(),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Pin Photo', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddStampDialog(MarkupController controller) {
    String selectedStamp = '★ APPROVED FOR CONSTRUCTION ★';
    Color stampColor = const Color(0xFFD32F2F);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.verified_outlined, color: AppColors.online),
                  SizedBox(width: 8),
                  Text('Apply Engineering Stamp'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStamp,
                    decoration: const InputDecoration(labelText: 'Stamp Type'),
                    items: [
                      '★ APPROVED FOR CONSTRUCTION ★',
                      '★ AS-BUILT CERTIFIED ★',
                      '★ HOLD FOR CLARIFICATION ★',
                      '★ VOID / SUPERSEDED ★',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          selectedStamp = v;
                          if (v.contains('APPROVED')) {
                            stampColor = const Color(0xFFD32F2F);
                          } else if (v.contains('AS-BUILT')) {
                            stampColor = const Color(0xFF2E7D32);
                          } else if (v.contains('HOLD')) {
                            stampColor = const Color(0xFFFF6F00);
                          } else {
                            stampColor = Colors.grey;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.addFieldStamp(
                      const Point2D(0.05, 0.85),
                      stampText: selectedStamp,
                      stampColor: stampColor,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply Stamp'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleCalibration(MarkupController controller, DrawingViewerState viewerState) {
    if (viewerState.isCalibrating) {
      if (viewerState.calibrationPoints.length >= 2) {
        CalibrationDialog.show(context, controller: controller, viewerState: viewerState);
      } else {
        controller.cancelCalibration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scale calibration cancelled')),
        );
      }
    } else {
      controller.startCalibration();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap 2 reference points on the drawing with a known dimension'),
          backgroundColor: AppColors.safetyOrange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawingAsync = ref.watch(singleDrawingProvider(widget.drawingId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return drawingAsync.when(
      loading: () => const Scaffold(
        body: LoadingStateView(message: 'Loading offline vector drawing & markups...'),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: ErrorStateView(
          message: 'Could not load drawing: $err',
          onRetry: () => ref.refresh(singleDrawingProvider(widget.drawingId)),
        ),
      ),
      data: (drawing) {
        if (drawing == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: const ErrorStateView(
              message: 'The requested drawing was not found in local offline storage.',
            ),
          );
        }

        final viewerState = ref.watch(markupControllerProvider(drawing.id));
        final markupController = ref.read(markupControllerProvider(drawing.id).notifier);
        final file = File(drawing.filePath);
        final fileExists = file.existsSync();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: viewerState.isFullscreen
              ? null
              : AppBar(
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  elevation: 1,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/drawings');
                      }
                    },
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            drawing.drawingNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: drawing.drawingType.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              drawing.drawingType.code,
                              style: TextStyle(
                                color: drawing.drawingType.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              drawing.revision,
                              style: const TextStyle(
                                color: AppColors.safetyOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Autosave Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: viewerState.isAutosaving
                                  ? Colors.amber.withOpacity(0.15)
                                  : AppColors.online.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  viewerState.isAutosaving
                                      ? Icons.sync_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 12,
                                  color: viewerState.isAutosaving ? Colors.amber : AppColors.online,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  viewerState.isAutosaving
                                      ? 'Autosaving...'
                                      : (viewerState.hasUnsavedChanges ? 'Edited' : 'Saved Offline'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: viewerState.isAutosaving ? Colors.amber : AppColors.online,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Sheet ${viewerState.currentPage} of ${drawing.pageCount} • ${drawing.title}',
                        style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  actions: [
                    // Sheet Selector Button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text('Sheet ${viewerState.currentPage}/${drawing.pageCount}'),
                      onPressed: () {
                        setState(() {
                          _showThumbnailDrawer = !_showThumbnailDrawer;
                          _showLayerPanel = false;
                        });
                      },
                    ),
                    const SizedBox(width: 6),

                    // Layer Panel Toggle
                    IconButton(
                      icon: const Icon(Icons.layers_rounded, color: AppColors.safetyOrange),
                      tooltip: 'Drawing Layers',
                      onPressed: () {
                        setState(() {
                          _showLayerPanel = !_showLayerPanel;
                          _showThumbnailDrawer = false;
                        });
                      },
                    ),

                    // Clear Page Markups
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (action) {
                        if (action == 'clear') {
                          _confirmClearPage(context, markupController);
                        } else if (action == 'print') {
                          if (fileExists) {
                            file.readAsBytes().then((bytes) {
                              Printing.layoutPdf(onLayout: (format) => bytes, name: '${drawing.drawingNumber}.pdf');
                            });
                          }
                        } else if (action == 'inspector') {
                          setState(() => _showInspector = !_showInspector);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'inspector',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Engineering Inspector'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Print / Export PDF'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Clear Sheet Markups', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
          body: Stack(
            children: [
              // Main Drawing Canvas Stack
              Row(
                children: [
                  Expanded(
                    flex: _showInspector ? 7 : 10,
                    child: Container(
                      color: isDark ? const Color(0xFF0F1218) : const Color(0xFFDDE3EA),
                      child: DrawingCanvasView(
                        drawing: drawing,
                        viewerState: viewerState,
                        controller: markupController,
                        transformationController: _transformationController,
                        onDoubleTapReset: _resetZoom,
                      ),
                    ),
                  ),

                  // Optional Engineering Inspector Sidebar Panel
                  if (_showInspector && !viewerState.isFullscreen)
                    Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        border: Border(
                          left: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1,
                          ),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: AppColors.safetyOrange, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Blueprint Inspector',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => setState(() => _showInspector = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInspectorCard(
                            title: 'DRAWING PARAMETERS',
                            children: [
                              _buildDetailRow('Drawing Number', drawing.drawingNumber),
                              _buildDetailRow('Discipline', '${drawing.drawingType.displayName} (${drawing.drawingType.code})'),
                              _buildDetailRow('Active Sheet', 'Sheet ${viewerState.currentPage} of ${drawing.pageCount}'),
                              _buildDetailRow('Revision', drawing.revision),
                              _buildDetailRow('File Size', StorageUsage.formatBytes(drawing.fileSize)),
                              _buildDetailRow('Offline Storage', 'SQLite + Vector PDF Engine'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildInspectorCard(
                            title: 'SCALE & CALIBRATION',
                            children: [
                              _buildDetailRow(
                                'Status',
                                viewerState.calibration != null ? 'Calibrated ✓' : 'Uncalibrated',
                              ),
                              if (viewerState.calibration != null) ...[
                                _buildDetailRow(
                                  'Known Dimension',
                                  '${viewerState.calibration!.knownDistance} ${viewerState.calibration!.unit.symbol}',
                                ),
                                _buildDetailRow(
                                  'Scale Unit',
                                  viewerState.calibration!.unit.displayName,
                                ),
                              ],
                              _buildDetailRow(
                                'Measurements on Sheet',
                                '${viewerState.measurements.where((m) => m.type.name != 'count').length}',
                              ),
                              _buildDetailRow(
                                'Count Pins on Sheet',
                                '${viewerState.measurements.where((m) => m.type.name == 'count').length}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildInspectorCard(
                            title: 'MARKUP LAYER STATISTICS',
                            children: [
                              _buildDetailRow('Total Markups on Sheet', '${viewerState.activePageMarkups.length} items'),
                              _buildDetailRow('Revision Clouds', '${viewerState.activePageMarkups.where((m) => m.type == MarkupType.revisionCloud).length}'),
                              _buildDetailRow('Dimensions & Rulers', '${viewerState.getLayerCount(DrawingLayer.measurement)}'),
                              _buildDetailRow('Punchlist Pins', '${viewerState.getLayerCount(DrawingLayer.issue)}'),
                              _buildDetailRow('Site Photo Callouts', '${viewerState.getLayerCount(DrawingLayer.photo)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Top Floating Markup Toolbar
              Positioned(
                top: 16,
                left: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MarkupToolbar(
                      viewerState: viewerState,
                      controller: markupController,
                      onToggleLayers: () {
                        setState(() {
                          _showLayerPanel = !_showLayerPanel;
                          _showThumbnailDrawer = false;
                        });
                      },
                      onFitToScreen: _fitToScreen,
                      onAddText: () => _showAddTextDialog(markupController),
                      onAddIssue: () => _showAddIssueDialog(markupController),
                      onAddPhoto: () => _showAddPhotoDialog(markupController),
                      onAddStamp: () => _showAddStampDialog(markupController),
                      onCalibrate: () => _handleCalibration(markupController, viewerState),
                      onOpenCountTool: () => CountToolDialog.show(
                        context,
                        controller: markupController,
                        viewerState: viewerState,
                      ),
                    ),
                    if (viewerState.isCalibrating) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.safetyOrange,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.straighten_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              viewerState.calibrationPoints.length < 2
                                  ? 'Calibration: Tap Point ${viewerState.calibrationPoints.length + 1} of 2 on Drawing'
                                  : '2 Points Selected! Enter dimension to finish.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (viewerState.calibrationPoints.length >= 2)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.safetyOrange,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => CalibrationDialog.show(
                                  context,
                                  controller: markupController,
                                  viewerState: viewerState,
                                ),
                                child: const Text('Set Distance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: markupController.cancelCalibration,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Layer Management Panel (Floating Flyout)
              if (_showLayerPanel)
                Positioned(
                  top: 76,
                  right: 24,
                  child: LayerManagementPanel(
                    viewerState: viewerState,
                    controller: markupController,
                    onClose: () => setState(() => _showLayerPanel = false),
                  ),
                ),

              // Thumbnail Navigation Drawer (Floating Flyout)
              if (_showThumbnailDrawer)
                Positioned(
                  top: 76,
                  left: 24,
                  child: ThumbnailNavigationDrawer(
                    drawing: drawing,
                    viewerState: viewerState,
                    controller: markupController,
                    onClose: () => setState(() => _showThumbnailDrawer = false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInspectorCard({required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.darkTextMuted),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
          SelectableText(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _confirmClearPage(BuildContext context, MarkupController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Sheet Markups?'),
          content: const Text('This will remove all annotations, revision clouds, and measurements from this sheet. The original PDF will remain unchanged.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                controller.clearCurrentPageMarkups();
                Navigator.of(context).pop();
              },
              child: const Text('Clear Sheet', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
