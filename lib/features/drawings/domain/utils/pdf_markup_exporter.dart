import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/models/drawing.dart';
import '../../domain/models/markup.dart';
import '../../domain/models/measurement.dart';

/// Flattened PDF Export Engine (Phase 3 PDF Review Export)
/// Burns digital markups, uniform typography, and measurements into client-ready PDF.
class PdfMarkupExporter {
  /// Generates a standardized A3 Landscape flattened PDF with vector markup overlay
  static Future<Uint8List> exportFlattenedDrawingPdf({
    required Drawing drawing,
    required List<Markup> markups,
    required List<Measurement> measurements,
    int pageNumber = 1,
  }) async {
    final pdf = pw.Document();

    final pageMarkups = markups.where((m) => m.pageNumber == pageNumber && !m.deleted).toList();
    final pageMeasurements = measurements.where((m) => m.pageNumber == pageNumber).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. Engineering Border & Title Block
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
              ),

              // Title Block (Bottom Right)
              pw.Positioned(
                right: 0,
                bottom: 0,
                child: pw.Container(
                  width: 260,
                  height: 90,
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
                        'PROJECT: EPC PIPING & INSTRUMENTATION',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                      ),
                      pw.Text(
                        'TITLE: ${drawing.title}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.Text(
                        'DWG NO: ${drawing.drawingNumber}  |  REV: ${drawing.revision}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        'MARKUP STATUS: REVIEW COPY (${pageMarkups.length} Annotations)',
                        style: pw.TextStyle(
                          color: PdfColors.orange800,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Markups & Text Overlay (Vector)
              ...pageMarkups.map((m) {
                if (m.points.isEmpty) return pw.Container();
                final p0 = m.points.first;

                if (m.type == MarkupType.text && m.text != null) {
                  return pw.Positioned(
                    left: p0.x * 1100,
                    top: p0.y * 780,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blueGrey900,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        border: pw.Border.all(color: PdfColors.redAccent, width: 1),
                      ),
                      child: pw.Text(
                        m.text!,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                if (m.type == MarkupType.stamp && m.text != null) {
                  return pw.Positioned(
                    left: p0.x * 1100,
                    top: p0.y * 780,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        border: pw.Border.all(color: PdfColors.green700, width: 1.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        m.text!,
                        style: pw.TextStyle(
                          color: PdfColors.green900,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                return pw.Container();
              }).toList(),

              // 3. Measurements Overlay
              ...pageMeasurements.map((meas) {
                if (meas.points.isEmpty) return pw.Container();
                final p = meas.points.first;
                return pw.Positioned(
                  left: p.x * 1100,
                  top: p.y * 780,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.cyan50,
                      border: pw.Border.all(color: PdfColors.cyan700, width: 0.8),
                    ),
                    child: pw.Text(
                      meas.formattedDisplay,
                      style: pw.TextStyle(color: PdfColors.cyan900, fontSize: 7, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }
}
