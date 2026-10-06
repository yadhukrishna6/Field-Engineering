import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:field_engineering/core/theme/app_typography.dart';
import 'package:field_engineering/features/drawings/domain/models/drawing.dart';
import 'package:field_engineering/features/drawings/domain/models/drawing_type.dart';
import 'package:field_engineering/features/drawings/domain/models/markup.dart';
import 'package:field_engineering/features/drawings/domain/models/measurement.dart';
import 'package:field_engineering/features/drawings/domain/models/drawing_calibration.dart';
import 'package:field_engineering/features/drawings/domain/utils/stroke_smoother.dart';
import 'package:field_engineering/features/drawings/domain/utils/measurement_calculator.dart';
import 'package:field_engineering/features/drawings/domain/utils/pdf_markup_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Drawing Markup — Full Phase Suite Tests', () {
    test('Phase 1: Strict uniform typography & smoothing algorithms', () {
      expect(AppTypography.engineeringFontFamily, equals('EngineeringFont'));

      final rawPoints = [
        const Point2D(0.1, 0.1),
        const Point2D(0.3, 0.6),
        const Point2D(0.6, 0.3),
        const Point2D(0.9, 0.9),
      ];
      final smoothed = StrokeSmoother.smoothPoints(rawPoints, subdivisions: 3);
      expect(smoothed.length, greaterThan(rawPoints.length));

      final simplified = StrokeSmoother.simplifyRDP(rawPoints, epsilon: 0.05);
      expect(simplified.length, lessThanOrEqualTo(rawPoints.length));
    });

    test('Phase 2: Shape geometry and revision cloud bounds calculation', () {
      final cloudMarkup = Markup(
        id: 'cloud-01',
        drawingId: 'dwg-101',
        type: MarkupType.revisionCloud,
        color: Colors.red,
        bounds: const Rect.fromLTWH(0.1, 0.1, 0.3, 0.2),
        createdBy: 'Lead Engineer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(cloudMarkup.type, equals(MarkupType.revisionCloud));
      expect(cloudMarkup.bounds!.width, closeTo(0.3, 0.001));
      expect(cloudMarkup.bounds!.height, closeTo(0.2, 0.001));
    });

    test('Phase 3: Review workflow status transitions & PDF export', () async {
      final markup = Markup(
        id: 'm-rev-01',
        drawingId: 'dwg-101',
        type: MarkupType.text,
        color: Colors.orange,
        text: 'RELOCATE VALVE 200MM EAST',
        status: 'Open',
        points: const [Point2D(0.2, 0.3)],
        createdBy: 'Field Reviewer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final addressed = markup.copyWith(status: 'Addressed');
      expect(addressed.status, equals('Addressed'));

      final closed = addressed.copyWith(status: 'Closed');
      expect(closed.status, equals('Closed'));

      final drawing = Drawing(
        id: 'dwg-101',
        projectId: 'proj-01',
        drawingNumber: '10-P&ID-001',
        title: 'Crude Distillation Unit P&ID',
        drawingType: DrawingType.pid,
        revision: 'Rev C',
        filePath: 'assets/sample_drawings/pid_drawing_sample.pdf',
        pageCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pdfBytes = await PdfMarkupExporter.exportFlattenedDrawingPdf(
        drawing: drawing,
        markups: [closed],
        measurements: [],
        pageNumber: 1,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
    });

    test('Phase 4: Calibration scaling and measurement computation', () {
      final cal = DrawingCalibration.fromPoints(
        id: 'cal-01',
        drawingId: 'dwg-101',
        point1: const Point2D(0.0, 0.0),
        point2: const Point2D(1.0, 0.0),
        knownDistance: 10000.0, // 10,000 mm across page
        unit: CalibrationUnit.mm,
      );

      expect(cal.scaleFactor, closeTo(10000.0, 0.1));

      final dist = MeasurementCalculator.calculateValue(
        type: MeasurementType.distance,
        points: const [Point2D(0.1, 0.1), Point2D(0.6, 0.1)],
        calibration: cal,
      );

      expect(dist, closeTo(5000.0, 0.1)); // 0.5 * 10000 = 5000mm
    });
  });
}
