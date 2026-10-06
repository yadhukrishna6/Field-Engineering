import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/page_markup.dart';
import '../../domain/utils/markup_pdf_exporter.dart';
import '../controllers/drawings_list_controller.dart';
import '../widgets/drawing_canvas_painter.dart';

class DrawingDetailScreen extends ConsumerStatefulWidget {
  final String drawingId;
  final DrawingFile? initialDrawing;

  const DrawingDetailScreen({
    super.key,
    required this.drawingId,
    this.initialDrawing,
  });

  @override
  ConsumerState<DrawingDetailScreen> createState() => _DrawingDetailScreenState();
}

class _DrawingDetailScreenState extends ConsumerState<DrawingDetailScreen> {
  PageMarkup? _pageMarkup;
  bool _isLoadingMarkup = true;

  @override
  void initState() {
    super.initState();
    _loadMarkup();
  }

  Future<void> _loadMarkup() async {
    final repo = ref.read(markupRepositoryProvider);
    final markup = await repo.getPageMarkup(widget.drawingId, 1);
    if (mounted) {
      setState(() {
        _pageMarkup = markup;
        _isLoadingMarkup = false;
      });
    }
  }

  Future<void> _exportPdf(DrawingFile drawing) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating client-ready Vector PDF with engineering font...'),
          duration: Duration(seconds: 1),
        ),
      );
      final repo = ref.read(markupRepositoryProvider);
      final pdfBytes = await MarkupPdfExporter.exportFlattenedPdf(
        drawing: drawing,
        repository: repo,
      );
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${drawing.name}_markup.pdf',
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

  void _confirmDelete(BuildContext context, DrawingFile drawing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Drawing'),
        content: Text('Are you sure you want to delete "${drawing.name}" and all associated markups?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(drawingsListControllerProvider.notifier).deleteDrawing(drawing.id);
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(drawingsListControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final drawing = widget.initialDrawing ??
        state.drawings.where((d) => d.id == widget.drawingId).firstOrNull ??
        DrawingFile(
          id: widget.drawingId,
          name: 'Drawing ${widget.drawingId}',
          fileType: 'PDF',
          pageCount: 1,
          localPath: '',
          createdAt: DateTime.now(),
        );

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final outlineColor = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final chipColor = isDark ? AppColors.darkChip : AppColors.lightChip;

    final formattedCreated = DateFormat('MMM dd, yyyy • HH:mm').format(drawing.createdAt);
    final formattedUpdated = _pageMarkup?.updatedAt != null
        ? DateFormat('MMM dd, yyyy • HH:mm').format(_pageMarkup!.updatedAt!)
        : formattedCreated;

    final strokesCount = _pageMarkup?.strokes.length ?? 0;
    final labelsCount = _pageMarkup?.labels.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(drawing.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete drawing',
            onPressed: () => _confirmDelete(context, drawing),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Large Preview Container with White Paper Canvas
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.canvasPaper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: outlineColor, width: 1.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBaseLayer(drawing),
                        if (_pageMarkup != null)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);
                              return CustomPaint(
                                size: size,
                                painter: DrawingCanvasPainter(
                                  annotations: _pageMarkup!.annotations,
                                  activeStrokePoints: const [],
                                  activeColor: AppColors.inkRed,
                                  activeStrokeWidth: 4.0,
                                  canvasSize: size,
                                ),
                              );
                            },
                          ),
                        if (_isLoadingMarkup)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tags Row (Type, Pages, Size)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(drawing.fileType.toUpperCase(), chipColor, primaryColor),
                      _buildBadge('${drawing.pageCount} ${drawing.pageCount == 1 ? "page" : "pages"}', chipColor, secondaryTextColor),
                      _buildBadge('Sheet 1 Preview', chipColor, secondaryTextColor),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Metadata Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: outlineColor, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        _buildMetadataRow('Uploaded', formattedCreated, textColor, secondaryTextColor),
                        Divider(color: outlineColor, height: 20),
                        _buildMetadataRow('Last edited', formattedUpdated, textColor, secondaryTextColor),
                        Divider(color: outlineColor, height: 20),
                        _buildMetadataRow(
                          'Markups',
                          '$strokesCount strokes, $labelsCount labels',
                          textColor,
                          secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions: ONE Primary Button ("Open editor") & Secondary Actions
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Open editor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: () {
                      context.push('/drawings/${drawing.id}/edit', extra: drawing);
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: outlineColor),
                          ),
                          icon: Icon(Icons.picture_as_pdf_rounded, color: primaryColor, size: 18),
                          label: Text('Export', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          onPressed: () => _exportPdf(drawing),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: outlineColor),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          onPressed: () => _confirmDelete(context, drawing),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color chipColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, Color textColor, Color secondaryTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: secondaryTextColor, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold)),
      ],
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
        maxPageWidth: 800,
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
              const Icon(Icons.architecture_rounded, size: 48, color: AppColors.lightPrimary),
              const SizedBox(height: 8),
              Text(drawing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            ],
          ),
        );
      }
    }
  }
}
