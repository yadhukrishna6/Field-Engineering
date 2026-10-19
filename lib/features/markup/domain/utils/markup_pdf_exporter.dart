import '../models/point_2d.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/annotation_item.dart';
import '../models/drawing_file.dart';
import '../models/field_change_item.dart';
import '../models/stroke.dart';
import '../models/text_label.dart';
import '../repositories/markup_repository.dart';

/// PDF / Vector Redline Export Engine (Phase E Deliverable)
/// Burns digital markups, numbered callout badges (#1, #2, #3...), engineering title blocks,
/// and a structured Change List Appendix table into client-ready vector PDF.
class MarkupPdfExporter {
  /// Exports a complete multi-page flattened PDF document with burned-in vector markups,
  /// numbered callout badges, engineering title-block footer, and Change List Appendix.
  static Future<Uint8List> exportFlattenedPdf({
    required DrawingFile drawing,
    required MarkupRepository repository,
  }) async {
    final pdf = pw.Document();

    // Load standard monospace / technical drawing font bytes
    pw.Font? customFont;
    try {
      customFont = await PdfGoogleFonts.jetBrainsMonoBold();
    } catch (_) {
      customFont = pw.Font.courierBold();
    }

    final totalDrawingPages = drawing.pageCount;
    final allChangesAcrossPages = <FieldChangeItem>[];
    int globalChangeCount = 1;

    // 1. Render all drawing sheets with vector markups, callouts & title blocks
    for (int pageNum = 1; pageNum <= totalDrawingPages; pageNum++) {
      final markup = await repository.getPageMarkup(drawing.id, pageNum);

      // Extract changes on this page
      final pageChanges = <FieldChangeItem>[];
      for (final ann in markup.annotations) {
        if (ann.isConflictCopy) continue;
        if (ann.type == AnnotationType.stroke && ann.attachedTag == null && ann.changeType == null) {
          continue;
        }
        final item = FieldChangeItem.fromAnnotation(globalChangeCount++, ann, pageNumber: pageNum);
        pageChanges.add(item);
        allChangesAcrossPages.add(item);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Technical Drawing Border Frame
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                ),

                // Base Drawing Blueprint Watermark / Grid Lines
                _buildPdfBlueprintGrid(drawing, pageNum, customFont),

                // Vector Inking Strokes
                ...markup.strokes.map((stroke) => _buildPdfStrokeWidget(stroke)),

                // Uniform Text Labels / Note Boxes
                ...markup.labels.map((label) => _buildPdfLabelWidget(label, customFont)),

                // Stamps & Photo Pins
                ...markup.annotations
                    .where((a) => !a.isConflictCopy && (a.type == AnnotationType.stamp || a.type == AnnotationType.photoPin))
                    .map((ann) => _buildPdfPinOrStampWidget(ann, customFont)),

                // Numbered Callout Badges (#1, #2, #3...) matching the Appendix Table
                ...pageChanges.map((change) => _buildPdfCalloutBadge(change, customFont)),

                // Professional Engineering Title Block Footer
                _buildPdfTitleBlockFooter(drawing, pageNum, totalDrawingPages, customFont),
              ],
            );
          },
        ),
      );
    }

    // 2. Render Appendix Page(s) ("FIELD ENGINEERING REDLINE & CHANGE LIST APPENDIX")
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Appendix Header
              _buildAppendixHeader(drawing, allChangesAcrossPages.length, customFont),
              pw.SizedBox(height: 12),

              // Structured Changes Table
              pw.Expanded(
                child: _buildAppendixTable(allChangesAcrossPages, customFont),
              ),

              pw.SizedBox(height: 8),
              // Appendix Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'STATUS: CLIENT / OFFICE DRAFTING HAND-OFF | ALL VALUES ESTIMATE, VERIFY BEFORE FABRICATION',
                    style: pw.TextStyle(font: customFont, fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'PAGE ${totalDrawingPages + 1} OF ${totalDrawingPages + 1} (APPENDIX)',
                    style: pw.TextStyle(font: customFont, fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfBlueprintGrid(DrawingFile drawing, int pageNum, pw.Font? font) {
    return pw.Positioned.fill(
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'ISOMETRIC PIPING SCHEMATIC [NTS]',
              style: pw.TextStyle(font: font, fontSize: 18, color: PdfColors.grey400, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'DWG: ${drawing.drawingNumber ?? drawing.name} | SHEET $pageNum | ALL DIMENSIONS IN MM, ELEVATIONS IN M',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey400),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfStrokeWidget(Stroke stroke) {
    if (stroke.points.isEmpty) return pw.Container();

    final pdfColor = PdfColor(
      stroke.color.red / 255.0,
      stroke.color.green / 255.0,
      stroke.color.blue / 255.0,
      stroke.color.opacity,
    );

    return pw.CustomPaint(
      size: const PdfPoint(1100, 780),
      painter: (PdfGraphics canvas, PdfPoint size) {
        if (stroke.points.length < 2) return;
        canvas.setStrokeColor(pdfColor);
        canvas.setLineWidth(stroke.strokeWidth * 0.7);

        final p0 = stroke.points.first;
        canvas.moveTo(p0.x * size.x, (1.0 - p0.y) * size.y);

        for (int i = 1; i < stroke.points.length; i++) {
          final p = stroke.points[i];
          canvas.lineTo(p.x * size.x, (1.0 - p.y) * size.y);
        }
        canvas.strokePath();
      },
    );
  }

  static pw.Widget _buildPdfLabelWidget(TextLabel label, pw.Font? font) {
    final pdfColor = PdfColor(
      label.color.red / 255.0,
      label.color.green / 255.0,
      label.color.blue / 255.0,
    );

    return pw.Positioned(
      left: label.x * 1100,
      top: label.y * 780,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: pdfColor, width: 1.2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          label.text,
          style: pw.TextStyle(
            font: font,
            color: pdfColor,
            fontSize: label.fontSize * 0.8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildPdfPinOrStampWidget(AnnotationItem ann, pw.Font? font) {
    final pdfColor = PdfColor(
      ann.color.red / 255.0,
      ann.color.green / 255.0,
      ann.color.blue / 255.0,
    );
    final origin = ann.points.isNotEmpty ? ann.points.first : const Point2D(0.5, 0.5);

    if (ann.type == AnnotationType.photoPin) {
      return pw.Positioned(
        left: origin.x * 1100,
        top: origin.y * 780,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            'PHOTO PIN [GPS]',
            style: pw.TextStyle(font: font, color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    return pw.Positioned(
      left: origin.x * 1100,
      top: origin.y * 780,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: pdfColor, width: 2),
        ),
        child: pw.Text(
          ann.text?.toUpperCase() ?? 'OFFICIAL STAMP',
          style: pw.TextStyle(font: font, color: pdfColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _buildPdfCalloutBadge(FieldChangeItem change, pw.Font? font) {
    PdfColor badgeColor = PdfColors.red800;
    if (change.changeType == 'ADD') badgeColor = PdfColors.teal800;
    if (change.changeType == 'REPLACE') badgeColor = PdfColors.orange800;
    if (change.changeType == 'VERIFY') badgeColor = PdfColors.blue800;
    if (change.changeType == 'PHOTO') badgeColor = PdfColors.indigo800;

    return pw.Positioned(
      left: change.x * 1100 - 12,
      top: change.y * 780 - 12,
      child: pw.Container(
        width: 18,
        height: 18,
        decoration: pw.BoxDecoration(
          color: badgeColor,
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: PdfColors.white, width: 1.5),
        ),
        child: pw.Center(
          child: pw.Text(
            '${change.itemNumber}',
            style: pw.TextStyle(font: font, color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildPdfTitleBlockFooter(
    DrawingFile drawing,
    int pageNum,
    int totalPages,
    pw.Font? font,
  ) {
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return pw.Positioned(
      right: 0,
      bottom: 0,
      child: pw.Container(
        width: 360,
        height: 85,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.black, width: 1.5),
        ),
        padding: const pw.EdgeInsets.all(6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PROJECT: ${drawing.projectName ?? "DESERT PIPELINE EXPANSION"}',
                    style: pw.TextStyle(font: font, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                pw.Text('JOB: ${drawing.jobNumber ?? "JOB-4500-DESERT"}',
                    style: pw.TextStyle(font: font, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Divider(thickness: 0.5, color: PdfColors.black),
            pw.Text(
              'TITLE: ${drawing.title ?? drawing.name}',
              style: pw.TextStyle(font: font, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
              maxLines: 1,
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('DWG NO: ${drawing.drawingNumber ?? "ISO-3001-HC"}',
                    style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('REV: ${drawing.revision ?? "REV 1"}',
                    style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Divider(thickness: 0.5, color: PdfColors.black),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FIELD ENG: Antigravity Drafter', style: pw.TextStyle(font: font, fontSize: 7.5)),
                pw.Text('DATE: $nowStr', style: pw.TextStyle(font: font, fontSize: 7.5)),
                pw.Text('SHEET: $pageNum OF $totalPages',
                    style: pw.TextStyle(font: font, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildAppendixHeader(DrawingFile drawing, int totalItems, pw.Font? font) {
    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FIELD ENGINEERING REDLINE & CHANGE LIST APPENDIX',
                style: pw.TextStyle(font: font, fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'DRAWING: ${drawing.drawingNumber ?? drawing.name} (${drawing.revision ?? "REV 0"}) | JOB: ${drawing.jobNumber ?? "JOB-4500"} | PROJECT: ${drawing.projectName ?? "Desert Facility"}',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('TOTAL ITEMS: $totalItems', style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('EXPORT DATE: $nowStr', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAppendixTable(List<FieldChangeItem> changes, pw.Font? font) {
    if (changes.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No actionable field redlines or change notes recorded on this drawing.',
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(45), // Callout #
        1: pw.FixedColumnWidth(80), // Change Type
        2: pw.FixedColumnWidth(120), // Attached Tag
        3: pw.FlexColumnWidth(3), // Description
        4: pw.FixedColumnWidth(110), // GPS
        5: pw.FixedColumnWidth(95), // Author
        6: pw.FixedColumnWidth(85), // Status
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          children: [
            _buildTableHeaderCell('CALLOUT', font),
            _buildTableHeaderCell('TYPE', font),
            _buildTableHeaderCell('TAG / LOCATION', font),
            _buildTableHeaderCell('FIELD DIRECTIVE / INSTRUCTION', font),
            _buildTableHeaderCell('GPS COORD', font),
            _buildTableHeaderCell('AUTHOR', font),
            _buildTableHeaderCell('STATUS', font),
          ],
        ),

        // Data rows
        ...changes.map((c) {
          final isEven = c.itemNumber % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey100 : PdfColors.white),
            children: [
              _buildTableCell('#${c.itemNumber}', font, isBold: true, align: pw.TextAlign.center),
              _buildTableCell(c.changeType, font, isBold: true),
              _buildTableCell(c.attachedTag ?? 'N/A', font),
              _buildTableCell(c.description, font),
              _buildTableCell(c.gps != null ? '${c.gps!.lat.toStringAsFixed(4)}, ${c.gps!.lng.toStringAsFixed(4)}' : '-', font),
              _buildTableCell(c.author, font),
              _buildTableCell(c.status, font, align: pw.TextAlign.center),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, pw.Font? font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font? font, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}
