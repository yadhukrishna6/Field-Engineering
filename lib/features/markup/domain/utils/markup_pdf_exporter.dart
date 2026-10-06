import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/drawing_file.dart';
import '../models/stroke.dart';
import '../models/text_label.dart';
import '../repositories/markup_repository.dart';

/// PDF / PNG Flatten Export Engine (Phase 2 Deliverable)
/// Burns digital markups and uniform engineering text labels into client-ready vector PDF.
class MarkupPdfExporter {
  /// Exports a complete multi-page flattened PDF document with burned-in vector markups and labels
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

    final totalPages = drawing.pageCount;

    for (int pageNum = 1; pageNum <= totalPages; pageNum++) {
      final markup = await repository.getPageMarkup(drawing.id, pageNum);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // 1. Technical Drawing Border Frame
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                ),

                // 2. Title Block Header / Footer
                pw.Positioned(
                  right: 0,
                  bottom: 0,
                  child: pw.Container(
                    width: 280,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: PdfColors.black, width: 1.5),
                    ),
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'ENGINEERING DRAWING MARKUP',
                          style: pw.TextStyle(font: customFont, fontWeight: pw.FontWeight.bold, fontSize: 8),
                        ),
                        pw.Text(
                          drawing.name,
                          style: pw.TextStyle(font: customFont, fontWeight: pw.FontWeight.bold, fontSize: 10),
                          maxLines: 1,
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('SHEET: $pageNum OF $totalPages', style: pw.TextStyle(font: customFont, fontSize: 8)),
                            pw.Text('REV: CLIENT REVIEW', style: pw.TextStyle(font: customFont, fontSize: 8)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Render Vector Strokes
                ...markup.strokes.map((stroke) => _buildPdfStrokeWidget(stroke)),

                // 4. Render Uniform Text Labels with White Box
                ...markup.labels.map((label) => _buildPdfLabelWidget(label, customFont)),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
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
}
