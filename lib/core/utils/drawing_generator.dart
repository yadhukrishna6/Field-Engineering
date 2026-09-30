import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/drawings/domain/models/drawing_type.dart';
import '../storage/offline_storage_manager.dart';

class DrawingGenerator {
  static Future<File> generateSampleEngineeringPdf({
    required String drawingNumber,
    required String title,
    required String projectName,
    required String clientName,
    required DrawingType drawingType,
    required String revision,
    int pageCount = 1,
  }) async {
    final pdf = pw.Document();

    for (int pageIndex = 1; pageIndex <= pageCount; pageIndex++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Outer Border & Grid Coordinates
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                ),
                // Inner Content Border
                pw.Positioned(
                  left: 10,
                  top: 10,
                  right: 10,
                  bottom: 10,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey700, width: 1),
                    ),
                    padding: const pw.EdgeInsets.all(15),
                    child: _buildDiagramContent(
                      drawingType: drawingType,
                      drawingNumber: drawingNumber,
                      pageIndex: pageIndex,
                    ),
                  ),
                ),
                // Standard Industrial Title Block (Bottom Right)
                pw.Positioned(
                  right: 10,
                  bottom: 10,
                  child: _buildTitleBlock(
                    drawingNumber: drawingNumber,
                    title: title,
                    projectName: projectName,
                    clientName: clientName,
                    drawingType: drawingType,
                    revision: revision,
                    pageIndex: pageIndex,
                    totalPages: pageCount,
                  ),
                ),
                // Revision Table (Top Right)
                pw.Positioned(
                  right: 10,
                  top: 10,
                  child: _buildRevisionTable(revision),
                ),
                // Stamp (Approved for Construction / Field Inspection)
                pw.Positioned(
                  left: 25,
                  bottom: 25,
                  child: _buildEngineeringStamp(),
                ),
              ],
            );
          },
        ),
      );
    }

    final bytes = await pdf.save();
    final sanitizedFileName = '${drawingNumber.replaceAll(RegExp(r'[^\w\-]'), '_')}.pdf';
    return await OfflineStorageManager.instance.savePdfFile(
      fileName: sanitizedFileName,
      bytes: bytes,
    );
  }

  static pw.Widget _buildDiagramContent({
    required DrawingType drawingType,
    required String drawingNumber,
    required int pageIndex,
  }) {
    switch (drawingType) {
      case DrawingType.pid:
        return _buildPidVisualContent(drawingNumber);
      case DrawingType.isometric:
        return _buildIsoVisualContent(drawingNumber);
      case DrawingType.electrical:
        return _buildElectricalVisualContent(drawingNumber);
      default:
        return _buildGeneralVisualContent(drawingType, drawingNumber);
    }
  }

  static pw.Widget _buildPidVisualContent(String drawingNumber) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PROCESS & INSTRUMENTATION DIAGRAM (P&ID)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue900)),
        pw.SizedBox(height: 5),
        pw.Text('SYSTEM: 3-PHASE PRODUCTION SEPARATOR TRAIN & GAS COMPRESSION',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            // Vessel 1: HP Separator
            pw.Container(
              width: 180,
              height: 110,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue800, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('V-101', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('HP PRODUCTION SEPARATOR', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('DESIGN: 100 BAR @ 120°C', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                    pw.Text('TAG: LT-101 / PT-101 / PSV-101A', style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue700)),
                  ],
                ),
              ),
            ),
            pw.Text('==== 8"-HC-1001-A1A ====>', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            // Vessel 2: Gas Scrubber
            pw.Container(
              width: 160,
              height: 130,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue800, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('V-102', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('GAS SCRUBBER / DEMISTER', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('DESIGN: 95 BAR @ 90°C', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ),
            pw.Text('==== 6"-FG-1004-A2B ====>', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            // Compressor Package
            pw.Container(
              width: 170,
              height: 110,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.deepOrange800, width: 2),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('K-101A/B', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.deepOrange900)),
                    pw.Text('RECIPROCATING GAS COMPRESSOR', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('POWER: 1250 kW / 3300V', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildIsoVisualContent(String drawingNumber) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PIPING ISOMETRIC DRAWING (ISO)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.purple900)),
        pw.SizedBox(height: 5),
        pw.Text('LINE NUMBER: 6"-P-3001-CS300-N | INSULATION: HOT 50mm | TEST PRESSURE: 22.5 BAR',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        pw.SizedBox(height: 15),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Container(
                height: 180,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ISO COORDINATES & ELEVATIONS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('START POINT (TP-01): N 10450.200 | E 8230.150 | EL +104.500 (FLANGE CL-300 WN)', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('CHANGE POINT (CP-01): 90° LR ELBOW UP TO EL +108.200', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('TIE-IN (TP-02): NOZZLE N1 ON DRUM D-201 | EL +108.200', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 10),
                    pw.Text('WELD SUMMARY: 14 BUTTWELDS (BW) | 4 FLANGED JOINTS (FLG) | 100% NDT (RT/UT)', style: pw.TextStyle(fontSize: 8, color: PdfColors.purple800, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 15),
            // Bill of Materials (BOM)
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.TableHelper.fromTextArray(
                  headers: ['ITEM', 'DESCRIPTION', 'QTY', 'SPEC'],
                  data: [
                    ['1', 'PIPE 6" SCH 40 A106-B', '18.4 m', 'CS300'],
                    ['2', 'ELBOW 90° LR BW A234 WPB', '4 EA', 'CS300'],
                    ['3', 'FLANGE 6" 300# WN RF', '3 EA', 'A105'],
                    ['4', 'BALL VALVE 6" CL300 FP', '1 EA', 'API 6D'],
                  ],
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildElectricalVisualContent(String drawingNumber) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ELECTRICAL SINGLE LINE DIAGRAM (SLD)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.amber900)),
        pw.SizedBox(height: 5),
        pw.Text('SUBSTATION-01: 33kV / 6.6kV / 415V POWER DISTRIBUTION NETWORK',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        pw.SizedBox(height: 20),
        pw.Container(
          height: 140,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          padding: const pw.EdgeInsets.all(10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  pw.Text('GRID INCOMER 33kV', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  pw.Container(width: 2, height: 25, color: PdfColors.black),
                  pw.Text('TRANSFORMER 33/6.6kV (10 MVA)', style: const pw.TextStyle(fontSize: 7)),
                  pw.Container(width: 2, height: 25, color: PdfColors.black),
                  pw.Text('MAIN 6.6kV SWITCHBOARD (MSB-01)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.amber800)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('STANDBY GENERATOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.red800)),
                  pw.Container(width: 2, height: 25, color: PdfColors.red800),
                  pw.Text('EDG-01 (1500 kVA)', style: const pw.TextStyle(fontSize: 7)),
                  pw.Container(width: 2, height: 25, color: PdfColors.red800),
                  pw.Text('EMERGENCY BUS 415V (ESB-01)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.red800)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildGeneralVisualContent(DrawingType type, String drawingNumber) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('${type.displayName.toUpperCase()} DIAGRAM',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey900)),
        pw.SizedBox(height: 5),
        pw.Text('FIELD ENGINEERING CERTIFIED OFFLINE DOCUMENT',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 25),
        pw.Container(
          height: 150,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            color: PdfColors.grey100,
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('DETAILED ENGINEERING DRAWING: $drawingNumber',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 5),
                pw.Text('DISCIPLINE: ${type.code} | FORMAT: A3 LANDSCAPE | SCALE: 1:50',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.SizedBox(height: 5),
                pw.Text('APPROVED FOR SITE CONSTRUCTION AND OFFLINE FIELD INSPECTION',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTitleBlock({
    required String drawingNumber,
    required String title,
    required String projectName,
    required String clientName,
    required DrawingType drawingType,
    required String revision,
    required int pageIndex,
    required int totalPages,
  }) {
    return pw.Container(
      width: 320,
      height: 120,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
        color: PdfColors.white,
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
              color: PdfColors.grey100,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('CLIENT: $clientName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text('DISCIPLINE: ${drawingType.code}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PROJECT: $projectName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.SizedBox(height: 2),
                pw.Text('TITLE: $title', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey900)),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
              color: PdfColors.grey200,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('DWG NO: $drawingNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('REV: $revision', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.red900)),
                pw.Text('SHT $pageIndex OF $totalPages', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRevisionTable(String currentRev) {
    return pw.Container(
      width: 250,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        color: PdfColors.white,
      ),
      child: pw.TableHelper.fromTextArray(
        headers: ['REV', 'DATE', 'DESCRIPTION', 'BY', 'APP'],
        data: [
          ['0', '15-JAN-2026', 'Issued for Design', 'YK', 'RH'],
          [currentRev.replaceAll('Rev ', ''), '28-FEB-2026', 'Issued for Construction', 'YK', 'MW'],
        ],
        cellStyle: const pw.TextStyle(fontSize: 6),
        headerStyle: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      ),
    );
  }

  static pw.Widget _buildEngineeringStamp() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red800, width: 2),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('★ APPROVED FOR CONSTRUCTION ★',
              style: pw.TextStyle(color: PdfColors.red800, fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.Text('FIELD CERTIFIED OFFLINE REPLICA',
              style: const pw.TextStyle(color: PdfColors.red800, fontSize: 6)),
          pw.Text('DATE: 2026-09-30 | STATUS: ACTIVE',
              style: const pw.TextStyle(color: PdfColors.red800, fontSize: 6)),
        ],
      ),
    );
  }
}
