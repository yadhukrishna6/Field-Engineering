import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/markup/domain/models/annotation_item.dart';
import 'package:field_engineering/features/markup/domain/models/point_2d.dart';
import 'package:field_engineering/features/markup/domain/utils/field_calculator.dart';

void main() {
  group('Phase F - Item 21: Unit Conversions & Pipe Schedules', () {
    test('Length conversions (mm -> m, in, ft, ft-in)', () {
      expect(FieldCalculator.mmToMeters(1000), closeTo(1.0, 0.001));
      expect(FieldCalculator.mmToMeters(3500), closeTo(3.5, 0.001));

      expect(FieldCalculator.mmToInches(25.4), closeTo(1.0, 0.001));
      expect(FieldCalculator.mmToInches(254), closeTo(10.0, 0.001));

      expect(FieldCalculator.mmToFeet(304.8), closeTo(1.0, 0.001));
      expect(FieldCalculator.mmToFeet(3048), closeTo(10.0, 0.001));

      // Feet & Inches formatting
      final ftIn1 = FieldCalculator.formatFeetInches(3048);
      expect(ftIn1, contains("10'"));

      final ftIn2 = FieldCalculator.formatFeetInches(1000);
      expect(ftIn2, contains("3'"));
      expect(ftIn2, contains('"'));
    });

    test('Pressure conversions (psi -> bar, kPa, MPa)', () {
      // 145.038 psi = 10 bar
      expect(FieldCalculator.psiToBar(145.038), closeTo(10.0, 0.05));
      expect(FieldCalculator.psiToKPa(145.038), closeTo(1000.0, 1.0));
      expect(FieldCalculator.psiToMPa(145.038), closeTo(1.0, 0.01));

      // Standard Class 150 hydrotest: 285 psi -> ~19.65 bar -> ~1.965 MPa
      final bar285 = FieldCalculator.psiToBar(285);
      expect(bar285, closeTo(19.65, 0.1));
      expect(FieldCalculator.psiToMPa(285), closeTo(1.965, 0.02));
    });

    test('ASME B36.10 Pipe NPS Table and Schedule Wall Thickness', () {
      expect(FieldCalculator.standardPipes.isNotEmpty, isTrue);

      // Find 10" pipe (10 NPS = 273.0 mm OD)
      final pipe10 = FieldCalculator.findPipeSpec('10"');
      expect(pipe10, isNotNull);
      expect(pipe10!.odMm, closeTo(273.0, 0.5));
      expect(pipe10.sch40WallMm, closeTo(9.27, 0.05));
      expect(pipe10.sch80WallMm, closeTo(15.09, 0.05));

      // Calculate ID = OD - 2 * wall
      final idSch40 = pipe10.getInsideDiameterMm('SCH 40');
      expect(idSch40, closeTo(273.0 - 2 * 9.27, 0.1));

      final idSch80 = pipe10.getInsideDiameterMm('SCH 80');
      expect(idSch80, closeTo(273.0 - 2 * 15.09, 0.1));

      // 2" pipe
      final pipe2 = FieldCalculator.findPipeSpec('2"');
      expect(pipe2, isNotNull);
      expect(pipe2!.odMm, closeTo(60.3, 0.5));
    });
  });

  group('Phase F - Item 22: Dimension Auto-Sum Per Line Tag & Sheet', () {
    test('Sums dimensions accurately per attached line tag', () {
      final annotations = [
        AnnotationItem(
          id: 'dim1',
          type: AnnotationType.dimension,
          points: [const Point2D(100, 100), const Point2D(200, 100)],
          color: const Color(0xFF08605B),
          strokeWidth: 2,
          attachedTag: const AttachedTag(text: '10"-HC-3001-A1'),
          text: '3500 mm',
        ),
        AnnotationItem(
          id: 'dim2',
          type: AnnotationType.dimension,
          points: [const Point2D(200, 100), const Point2D(350, 100)],
          color: const Color(0xFF08605B),
          strokeWidth: 2,
          attachedTag: const AttachedTag(text: '10"-HC-3001-A1'),
          text: '4200 mm',
        ),
        AnnotationItem(
          id: 'dim3',
          type: AnnotationType.dimension,
          points: [const Point2D(50, 50), const Point2D(100, 50)],
          color: const Color(0xFF08605B),
          strokeWidth: 2,
          attachedTag: const AttachedTag(text: '2"-DR-1002-CS'),
          text: '1200 mm',
        ),
        AnnotationItem(
          id: 'dim4',
          type: AnnotationType.dimension,
          points: [const Point2D(10, 10), const Point2D(20, 10)],
          color: const Color(0xFF08605B),
          strokeWidth: 2,
          text: '800 mm', // Unassigned tag
        ),
      ];

      final sumMap = FieldCalculator.sumDimensionsByLineTag(annotations);

      expect(sumMap.containsKey('10"-HC-3001-A1'), isTrue);
      final hc3001 = sumMap['10"-HC-3001-A1']!;
      expect(hc3001.segmentCount, equals(2));
      expect(hc3001.totalMm, closeTo(7700.0, 0.1));
      expect(hc3001.totalMeters, closeTo(7.7, 0.01));

      expect(sumMap.containsKey('2"-DR-1002-CS'), isTrue);
      final dr1002 = sumMap['2"-DR-1002-CS']!;
      expect(dr1002.segmentCount, equals(1));
      expect(dr1002.totalMm, closeTo(1200.0, 0.1));

      expect(sumMap.containsKey('GENERAL / UNTAGGED'), isTrue);
      final unassigned = sumMap['GENERAL / UNTAGGED']!;
      expect(unassigned.segmentCount, equals(1));
      expect(unassigned.totalMm, closeTo(800.0, 0.1));
    });
  });

  group('Phase F - Item 23: Quantities & BOM Tally Calculation', () {
    test('Tallies change types, photo pins, and stamps', () {
      final annotations = [
        AnnotationItem(
          id: '1',
          type: AnnotationType.stroke,
          points: [const Point2D(10, 10)],
          color: const Color(0xFFD03A33),
          strokeWidth: 4,
          changeType: 'delete',
        ),
        AnnotationItem(
          id: '2',
          type: AnnotationType.stroke,
          points: [const Point2D(20, 20)],
          color: const Color(0xFF08605B),
          strokeWidth: 4,
          changeType: 'add',
        ),
        AnnotationItem(
          id: '3',
          type: AnnotationType.rectangle,
          points: [const Point2D(30, 30), const Point2D(40, 40)],
          color: const Color(0xFFC25E00),
          strokeWidth: 4,
          changeType: 'replace',
        ),
        AnnotationItem(
          id: '4',
          type: AnnotationType.text,
          points: [const Point2D(50, 50)],
          color: const Color(0xFF185FA5),
          strokeWidth: 2,
          changeType: 'relocate',
        ),
        AnnotationItem(
          id: '5',
          type: AnnotationType.text,
          points: [const Point2D(60, 60)],
          color: const Color(0xFF00695C),
          strokeWidth: 2,
          changeType: 'verify',
        ),
        AnnotationItem(
          id: '6',
          type: AnnotationType.photoPin,
          points: [const Point2D(70, 70)],
          color: const Color(0xFF283593),
          strokeWidth: 2,
          photoIds: ['/photos/spool_weld.jpg'],
          gps: const GpsCoord(lat: 24.1234, lng: 55.4321),
        ),
        AnnotationItem(
          id: '7',
          type: AnnotationType.stamp,
          points: [const Point2D(80, 80)],
          color: const Color(0xFF4A148C),
          strokeWidth: 2,
          text: 'FIELD VERIFIED',
        ),
        AnnotationItem(
          id: '8',
          type: AnnotationType.dimension,
          points: [const Point2D(90, 90), const Point2D(190, 90)],
          color: const Color(0xFF08605B),
          strokeWidth: 2,
          text: '5000 mm',
        ),
      ];

      final tally = FieldCalculator.calculateQuantitiesTally(annotations);

      expect(tally.totalMarkups, equals(8));
      expect(tally.deletionsCount, equals(1));
      expect(tally.additionsCount, equals(1));
      expect(tally.replacementsCount, equals(1));
      expect(tally.relocationsCount, equals(1));
      expect(tally.verificationsCount, equals(1));
      expect(tally.photoPinsCount, equals(1));
      expect(tally.officialStampsCount, equals(1));
      expect(tally.totalCutLengthMeters, closeTo(5.0, 0.01));
    });
  });

  group('Phase F - Item 24: Piping Engineering Formulas & Disclaimer', () {
    test('ASME B31.3 Hydrotest Pressure (1.5x)', () {
      expect(FieldCalculator.calculateHydrotestPressure(100.0), closeTo(150.0, 0.001));
      expect(FieldCalculator.calculateHydrotestPressure(285.0), closeTo(427.5, 0.001));
      expect(FieldCalculator.calculateHydrotestPressure(600.0), closeTo(900.0, 0.001));
    });

    test('Pipe Internal Volume and Weights (Water, Oil, Steel, Hydrotest)', () {
      // 10" SCH 40 pipe (OD = 273.0 mm, Wall = 9.27 mm -> ID = 254.46 mm = 0.25446 m)
      // Radius = 0.12723 m
      // Area = pi * r^2 = 0.05085 m^2
      // For 10 meters length: Volume = 0.5085 m^3 = 508.5 Liters
      final calc = FieldCalculator.calculatePipeVolumeAndWeight(
        outerDiameterMm: 273.0,
        wallThicknessMm: 9.27,
        lengthMeters: 10.0,
      );

      expect(calc.internalVolumeM3, closeTo(0.5085, 0.01));
      expect(calc.internalVolumeLiters, closeTo(508.5, 10.0));
      expect(calc.waterWeightKg, closeTo(508.5, 10.0));
      expect(calc.crudeOilWeightKg, closeTo(508.5 * 0.85, 10.0));

      // Steel cross sectional area = pi/4 * (0.273^2 - 0.25446^2) = 0.00768 m^2
      // Steel Volume for 10m = 0.0768 m^3
      // Steel Weight = 0.0768 * 7850 = ~603 kg
      expect(calc.pipeSteelWeightKg, closeTo(603.0, 20.0));

      // Total hydrotest weight = Steel weight + Water weight = 603 + 508.5 = ~1111.5 kg = ~1.11 Tonnes
      expect(calc.totalHydrotestWeightTonnes, closeTo(1.11, 0.05));
    });

    test('Thermal Expansion calculation (Delta L = alpha * L * Delta T)', () {
      // Carbon steel alpha = 1.2e-5 / deg C
      // 100 meters, 50 deg C swing
      // Delta L = 1.2e-5 * 100 * 50 * 1000 = 60 mm
      final deltaL = FieldCalculator.calculateThermalExpansionMm(
        lengthMeters: 100.0,
        deltaTempCelsius: 50.0,
      );
      expect(deltaL, closeTo(60.0, 0.01));

      // 24 meters, 45 deg C swing
      // Delta L = 1.2e-5 * 24 * 45 * 1000 = 12.96 mm
      final deltaL2 = FieldCalculator.calculateThermalExpansionMm(
        lengthMeters: 24.0,
        deltaTempCelsius: 45.0,
      );
      expect(deltaL2, closeTo(12.96, 0.01));
    });

    test('Engineering Disclaimer is strictly present', () {
      expect(FieldCalculator.disclaimer, contains('ESTIMATE, VERIFY BEFORE FABRICATION'));
    });
  });
}
