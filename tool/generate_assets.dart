import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  stdout.writeln('Generating sample PDF engineering drawings and asset images...');

  final drawingsDir = Directory('assets/sample_drawings');
  if (!drawingsDir.existsSync()) {
    drawingsDir.createSync(recursive: true);
  }

  final imagesDir = Directory('assets/images');
  if (!imagesDir.existsSync()) {
    imagesDir.createSync(recursive: true);
  }

  // 1. Generate PID drawing PDF
  await _generateDrawingPdf(
    path: 'assets/sample_drawings/pid_drawing_sample.pdf',
    title: 'Process & Instrumentation Diagram - Separator Train & Gas Compression',
    drawingNumber: 'PID-102-REV-03',
    discipline: 'P&ID / Process',
    rev: 'Rev 03',
    color: PdfColors.blue900,
  );

  // 2. Generate Isometric drawing PDF
  await _generateDrawingPdf(
    path: 'assets/sample_drawings/isometric_sample.pdf',
    title: 'Piping Isometric - 6" High Pressure Gas Line to Scrubber',
    drawingNumber: 'ISO-204-REV-02',
    discipline: 'Piping Isometric',
    rev: 'Rev 02',
    color: PdfColors.purple900,
  );

  // 3. Generate Piping Plan drawing PDF
  await _generateDrawingPdf(
    path: 'assets/sample_drawings/piping_sample.pdf',
    title: 'Piping General Arrangement Plan - Battery Limit Area A',
    drawingNumber: 'PIP-305-REV-01',
    discipline: 'Piping GA',
    rev: 'Rev 01',
    color: PdfColors.teal900,
  );

  // 4. Generate Structural drawing PDF
  await _generateDrawingPdf(
    path: 'assets/sample_drawings/structural_sample.pdf',
    title: 'Structural Steelwork & Pipe Rack Elevation - Unit 100',
    drawingNumber: 'STR-401-REV-04',
    discipline: 'Structural Steel',
    rev: 'Rev 04',
    color: PdfColors.blueGrey900,
  );

  // 5. Generate sample images (Valid minimal PNG files with colored headers/placeholders)
  _generateMinimalPng('assets/images/engineer_avatar.png', 128, 128, 0x1E, 0x88, 0xE5);
  _generateMinimalPng('assets/images/refinery_banner.jpg', 800, 300, 0x0F, 0x17, 0x2A);
  _generateMinimalPng('assets/images/piping_photo_1.jpg', 640, 480, 0x33, 0x41, 0x55);
  _generateMinimalPng('assets/images/piping_photo_2.jpg', 640, 480, 0x1E, 0x29, 0x3B);
  _generateMinimalPng('assets/images/piping_photo_3.jpg', 640, 480, 0x47, 0x55, 0x69);

  stdout.writeln('Sample assets generated successfully.');
}

Future<void> _generateDrawingPdf({
  required String path,
  required String title,
  required String drawingNumber,
  required String discipline,
  required String rev,
  required PdfColor color,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a3.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // Outer Border
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
              ),
            ),
            // Content
            pw.Positioned(
              left: 15,
              top: 15,
              right: 15,
              bottom: 15,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600, width: 1),
                ),
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'FIELD ENGINEERING TABLET PLATFORM - OFFLINE VERIFIED SCHEMATIC',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 25),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          color: PdfColors.grey100,
                        ),
                        padding: const pw.EdgeInsets.all(20),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SCHEMATIC DIAGRAM: $drawingNumber',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                                color: color,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text('Discipline: $discipline | Scale: 1:50 | Format: A3 Landscape | Status: Approved For Construction'),
                            pw.SizedBox(height: 15),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                              children: [
                                pw.Container(
                                  width: 140,
                                  height: 90,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: color, width: 2),
                                    borderRadius: pw.BorderRadius.circular(6),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text('EQUIPMENT UNIT A\nV-101 SEPARATOR', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                  ),
                                ),
                                pw.Text('==== [6" SCH40 CS] ====>', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                pw.Container(
                                  width: 140,
                                  height: 90,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: color, width: 2),
                                    borderRadius: pw.BorderRadius.circular(6),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text('EQUIPMENT UNIT B\nK-101 COMPRESSOR', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title Block (Bottom Right)
            pw.Positioned(
              right: 15,
              bottom: 15,
              child: pw.Container(
                width: 280,
                height: 100,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1.5),
                  color: PdfColors.white,
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PROJECT: Field Engineering Operations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('DWG: $drawingNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('REV: $rev | SHEET 1 OF 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red800)),
                    pw.Text('STAMP: ★ APPROVED FOR CONSTRUCTION ★', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: PdfColors.green900)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  final bytes = await pdf.save();
  final file = File(path);
  await file.writeAsBytes(bytes);
}

void _generateMinimalPng(String path, int width, int height, int r, int g, int b) {
  // Generate a valid uncompressed PNG file using basic PNG chunks (IHDR, IDAT, IEND)
  final pngBytes = _createSolidColorPng(width, height, r, g, b);
  File(path).writeAsBytesSync(pngBytes);
}

Uint8List _createSolidColorPng(int width, int height, int r, int g, int b) {
  // Simple PNG encoder for solid color image
  final rawData = BytesBuilder();
  for (int y = 0; y < height; y++) {
    rawData.addByte(0); // Filter type None
    for (int x = 0; x < width; x++) {
      rawData.addByte(r);
      rawData.addByte(g);
      rawData.addByte(b);
      rawData.addByte(255); // Alpha
    }
  }

  final uncompressed = rawData.toBytes();
  final compressed = zlibDeflate(uncompressed);

  final png = BytesBuilder();
  // Signature
  png.add([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR
  final ihdr = BytesBuilder();
  ihdr.add(_uint32(width));
  ihdr.add(_uint32(height));
  ihdr.addByte(8); // Bit depth: 8
  ihdr.addByte(6); // Color type: RGBA (6)
  ihdr.addByte(0); // Compression method: 0
  ihdr.addByte(0); // Filter method: 0
  ihdr.addByte(0); // Interlace method: 0
  _addChunk(png, 'IHDR', ihdr.toBytes());

  // IDAT
  _addChunk(png, 'IDAT', compressed);

  // IEND
  _addChunk(png, 'IEND', Uint8List(0));

  return png.toBytes();
}

void _addChunk(BytesBuilder png, String type, Uint8List data) {
  png.add(_uint32(data.length));
  final typeBytes = type.codeUnits;
  png.add(typeBytes);
  png.add(data);
  final crcData = Uint8List(typeBytes.length + data.length);
  crcData.setRange(0, typeBytes.length, typeBytes);
  crcData.setRange(typeBytes.length, crcData.length, data);
  png.add(_uint32(_calculateCrc32(crcData)));
}

Uint8List _uint32(int value) {
  return Uint8List(4)
    ..[0] = (value >> 24) & 0xFF
    ..[1] = (value >> 16) & 0xFF
    ..[2] = (value >> 8) & 0xFF
    ..[3] = value & 0xFF;
}

Uint8List zlibDeflate(Uint8List data) {
  return Uint8List.fromList(zlib.encode(data));
}

int _calculateCrc32(Uint8List data) {
  int crc = 0xFFFFFFFF;
  for (int byte in data) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
