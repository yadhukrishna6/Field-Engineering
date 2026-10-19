import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/field_change_item.dart';
import '../../domain/repositories/markup_repository.dart';
import '../../domain/utils/change_list_csv_exporter.dart';
import '../../domain/utils/markup_pdf_exporter.dart';
import 'change_list_sheet.dart';

class ExportShareHubSheet extends StatelessWidget {
  final DrawingFile drawing;
  final List<AnnotationItem> annotations;
  final MarkupRepository repository;
  final bool isOutdoor;
  final bool isDark;

  const ExportShareHubSheet({
    super.key,
    required this.drawing,
    required this.annotations,
    required this.repository,
    required this.isOutdoor,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required DrawingFile drawing,
    required List<AnnotationItem> annotations,
    required MarkupRepository repository,
    required bool isOutdoor,
    required bool isDark,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExportShareHubSheet(
        drawing: drawing,
        annotations: annotations,
        repository: repository,
        isOutdoor: isOutdoor,
        isDark: isDark,
      ),
    );
  }

  Future<void> _shareRedlinePdf(BuildContext context) async {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating Redline PDF with Title Blocks & Appendix...')),
    );

    try {
      final bytes = await MarkupPdfExporter.exportFlattenedPdf(
        drawing: drawing,
        repository: repository,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${drawing.name}_redline_appendix.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export PDF failed: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _shareCsv(BuildContext context) {
    Navigator.of(context).pop();
    final changes = FieldChangeItem.extractChanges(annotations);
    final csvData = ChangeListCsvExporter.generateCsv(drawing: drawing, changes: changes);

    Clipboard.setData(ClipboardData(text: csvData));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CAD Change List CSV (${changes.length} rows) copied to clipboard! Ready to paste into Excel/CAD.'),
        backgroundColor: const Color(0xFF08605B),
      ),
    );
  }

  void _copySummary(BuildContext context) {
    Navigator.of(context).pop();
    final changes = FieldChangeItem.extractChanges(annotations);
    final summary = ChangeListCsvExporter.generateSummaryMarkdown(drawing: drawing, changes: changes);

    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formatted Markdown summary copied to clipboard!'),
        backgroundColor: Color(0xFF08605B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isOutdoor
        ? AppColors.outdoorSurface
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = isOutdoor
        ? AppColors.outdoorText
        : (isDark ? AppColors.darkText : AppColors.lightText);
    final outlineColor = isOutdoor
        ? AppColors.outdoorOutline
        : (isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final primaryColor = isOutdoor
        ? AppColors.outdoorPrimary
        : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    final changes = FieldChangeItem.extractChanges(annotations);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: outlineColor, width: isOutdoor ? 1.5 : 1.0),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.share_rounded, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Export & Hand-Off Hub',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            'Package field redlines, callouts, and structured data for office drafters & client reviews.',
            style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),

          // Option 1: Redline Vector PDF + Appendix
          _buildHubOption(
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.redAccent,
            title: 'Redline Vector PDF + Appendix',
            subtitle: 'Complete drawing sheets with numbered callouts + formal Change Table Appendix',
            onTap: () => _shareRedlinePdf(context),
            textColor: textColor,
            outlineColor: outlineColor,
          ),
          const SizedBox(height: 10),

          // Option 2: Structured CAD CSV
          _buildHubOption(
            icon: Icons.table_chart_rounded,
            color: const Color(0xFF1E88E5),
            title: 'Structured Changes CSV (${changes.length} Items)',
            subtitle: 'RFC-4180 CAD spreadsheet table with Line Tags, Change Types, GPS & Notes',
            onTap: () => _shareCsv(context),
            textColor: textColor,
            outlineColor: outlineColor,
          ),
          const SizedBox(height: 10),

          // Option 3: Executive Markdown Summary
          _buildHubOption(
            icon: Icons.copy_all_rounded,
            color: const Color(0xFF08605B),
            title: 'Copy Executive Markdown Summary',
            subtitle: '1-tap clipboard copy formatted for email, Slack, or chat hand-off',
            onTap: () => _copySummary(context),
            textColor: textColor,
            outlineColor: outlineColor,
          ),
          const SizedBox(height: 10),

          // Option 4: View Change List Table
          _buildHubOption(
            icon: Icons.format_list_bulleted_rounded,
            color: Colors.amber.shade800,
            title: 'Review Change List Table',
            subtitle: 'Interactive in-app scannable log with item filtering and jump-to-location',
            onTap: () {
              Navigator.of(context).pop();
              ChangeListSheet.show(
                context,
                drawing: drawing,
                annotations: annotations,
                isOutdoor: isOutdoor,
                isDark: isDark,
                onExportPdf: () => _shareRedlinePdf(context),
                onExportCsv: () => _shareCsv(context),
              );
            },
            textColor: textColor,
            outlineColor: outlineColor,
          ),
          const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color outlineColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.65)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
