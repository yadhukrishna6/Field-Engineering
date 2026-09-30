import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/features/drawings/domain/models/markup.dart';
import 'package:field_engineering/features/drawings/domain/models/drawing_calibration.dart';
import 'package:field_engineering/features/drawings/domain/models/measurement.dart';
import 'package:field_engineering/features/drawings/domain/utils/measurement_calculator.dart';
import 'package:field_engineering/features/takeoff/domain/models/takeoff_item.dart';
import 'package:field_engineering/features/calculations/domain/models/saved_calculation.dart';

void main() {
  group('Part 1: Drawing Scale Calibration Tests', () {
    test('Calculates drawing scale from 2 normalized points and known dimension', () {
      // Point 1 at (0.1, 0.2), Point 2 at (0.5, 0.2) -> normalized dx = 0.4, dy = 0 -> distance = 0.4
      // Known distance: 1000 mm -> scaleFactor = 1000 / 0.4 = 2500.0 mm
      const p1 = Point2D(0.1, 0.2);
      const p2 = Point2D(0.5, 0.2);
      final calibration = DrawingCalibration.fromPoints(
        id: 'calib-001',
        drawingId: 'drawing-101',
        point1: p1,
        point2: p2,
        knownDistance: 1000.0,
        unit: CalibrationUnit.mm,
      );

      expect(calibration.scaleFactor, closeTo(2500.0, 0.001));
      expect(calibration.unit, CalibrationUnit.mm);
      expect(calibration.formatDistance(1000.0), '1000 mm');

      // Test real world distance calculation on 0.2 normalized span
      final realDist = calibration.normalizedToRealDistance(0.2);
      expect(realDist, closeTo(500.0, 0.001));
    });

    test('Supports all 5 engineering units: mm, cm, m, inch, ft', () {
      for (final unit in CalibrationUnit.values) {
        expect(unit.symbol.isNotEmpty, true);
        expect(unit.displayName.isNotEmpty, true);
        expect(unit.areaSymbol.isNotEmpty, true);
        expect(unit.toMmFactor > 0, true);
      }

      final calibMeters = DrawingCalibration(
        id: 'calib-m',
        drawingId: 'dwg-1',
        point1: const Point2D(0.0, 0.0),
        point2: const Point2D(1.0, 0.0),
        knownDistance: 10.0,
        unit: CalibrationUnit.m,
        scaleFactor: 10.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(calibMeters.formatDistance(4.25), '4.25 m');
      expect(calibMeters.formatArea(25.5), '25.50 m²');
    });

    test('Serializes to and from Map for offline SQLite storage', () {
      final calib = DrawingCalibration(
        id: 'calib-test',
        drawingId: 'dwg-p101',
        pageNumber: 2,
        point1: const Point2D(0.15, 0.25),
        point2: const Point2D(0.85, 0.75),
        knownDistance: 4500.0,
        unit: CalibrationUnit.mm,
        scaleFactor: 5200.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = calib.toMap();
      final fromMap = DrawingCalibration.fromMap(map);

      expect(fromMap.id, calib.id);
      expect(fromMap.drawingId, calib.drawingId);
      expect(fromMap.pageNumber, 2);
      expect(fromMap.knownDistance, 4500.0);
      expect(fromMap.unit, CalibrationUnit.mm);
      expect(fromMap.point1.x, closeTo(0.15, 0.0001));
      expect(fromMap.point2.y, closeTo(0.75, 0.0001));
    });
  });

  group('Part 2: Engineering Measurement Engine Tests', () {
    final calibration = DrawingCalibration(
      id: 'calib-test',
      drawingId: 'dwg-01',
      point1: const Point2D(0.0, 0.0),
      point2: const Point2D(1.0, 0.0),
      knownDistance: 1000.0, // 1000 mm full width
      unit: CalibrationUnit.mm,
      scaleFactor: 1000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('1. Distance Measurement', () {
      final val = MeasurementCalculator.calculateValue(
        type: MeasurementType.distance,
        points: [const Point2D(0.1, 0.1), const Point2D(0.5, 0.1)],
        calibration: calibration,
      );
      final unit = MeasurementCalculator.getUnitSymbol(MeasurementType.distance, calibration);

      expect(val, closeTo(400.0, 0.01));
      expect(unit, 'mm');
    });

    test('2. Polyline Distance Measurement (Multi-segment sum)', () {
      final val = MeasurementCalculator.calculateValue(
        type: MeasurementType.polylineDistance,
        points: [
          const Point2D(0.0, 0.0),
          const Point2D(0.3, 0.0), // 300 mm
          const Point2D(0.3, 0.4), // 400 mm
        ],
        calibration: calibration,
      );      final unit = MeasurementCalculator.getUnitSymbol(MeasurementType.polylineDistance, calibration);

      expect(val, closeTo(700.0, 0.01));
      expect(unit, 'mm');
    });

    test('3. Area Measurement (Polygon Shoelace formula)', () {
      // 200mm x 300mm rectangle
      final val = MeasurementCalculator.calculateValue(
        type: MeasurementType.area,
        points: [
          const Point2D(0.1, 0.1),
          const Point2D(0.3, 0.1),
          const Point2D(0.3, 0.4),
          const Point2D(0.1, 0.4),
        ],
        calibration: calibration,
      );
      final unit = MeasurementCalculator.getUnitSymbol(MeasurementType.area, calibration);

      // Area in mm²: 200 * 300 = 60,000 mm²
      expect(val, closeTo(60000.0, 1.0));
      expect(unit, 'mm²');
    });

    test('4. Angle Measurement (3-point vertex in degrees)', () {
      // 90 degree angle
      final val = MeasurementCalculator.calculateValue(
        type: MeasurementType.angle,
        points: [
          const Point2D(0.5, 0.2), // Point A (top)
          const Point2D(0.5, 0.5), // Vertex V (center)
          const Point2D(0.8, 0.5), // Point B (right)
        ],
        calibration: calibration,
      );
      final unit = MeasurementCalculator.getUnitSymbol(MeasurementType.angle, calibration);

      expect(val, closeTo(90.0, 0.5));
      expect(unit, 'deg');
    });

    test('5. Radius & 6. Diameter Measurement', () {
      // Radius: Center at (0.5, 0.5), edge at (0.7, 0.5) -> radius = 0.2 * 1000 = 200 mm
      final radiusVal = MeasurementCalculator.calculateValue(
        type: MeasurementType.radius,
        points: [const Point2D(0.5, 0.5), const Point2D(0.7, 0.5)],
        calibration: calibration,
      );
      expect(radiusVal, closeTo(200.0, 0.01));

      // Diameter: across 200mm span = 200 mm
      final diaVal = MeasurementCalculator.calculateValue(
        type: MeasurementType.diameter,
        points: [const Point2D(0.5, 0.5), const Point2D(0.7, 0.5)],
        calibration: calibration,
      );
      expect(diaVal, closeTo(200.0, 0.01));
    });

    test('7. Count Measurement', () {
      final val = MeasurementCalculator.calculateValue(
        type: MeasurementType.count,
        points: [const Point2D(0.3, 0.3)],
        calibration: calibration,
      );
      final unit = MeasurementCalculator.getUnitSymbol(MeasurementType.count, calibration);

      expect(val, 1.0);
      expect(unit, 'count');
    });

    test('8. Perimeter Measurement (Closed Loop)', () {
      // 200mm x 200mm square perimeter = 800 mm
      final val = MeasurementCalculator.calculateValue(
        type: MeasurementType.perimeter,
        points: [
          const Point2D(0.1, 0.1),
          const Point2D(0.3, 0.1),
          const Point2D(0.3, 0.3),
          const Point2D(0.1, 0.3),
        ],
        calibration: calibration,
      );
      final unit = MeasurementCalculator.getUnitSymbol(MeasurementType.perimeter, calibration);

      expect(val, closeTo(800.0, 0.01));
      expect(unit, 'mm');
    });
  });

  group('Part 3: Engineering Calculations & Data Models', () {
    test('SavedCalculation model serialization', () {
      final calc = SavedCalculation(
        id: 'calc-101',
        projectId: 'p-1',
        drawingId: 'dwg-1',
        calcType: 'Pipe ASME B31.3',
        title: '6" Sch 40 Process Line',
        inputs: {
          'pressureBar': 50.0,
          'diameterMm': 168.3,
          'allowableStressMpa': 137.9,
          'corrosionAllowanceMm': 3.0,
        },
        results: {
          'minThicknessMm': '6.054',
          'mawpBar': '65.20',
          'hydrotestBar': '75.00',
        },
        engineerNotes: 'ASME B31.3 design check passed.',
        createdAt: DateTime.now(),
      );

      final map = calc.toMap();
      final fromMap = SavedCalculation.fromMap(map);

      expect(fromMap.id, calc.id);
      expect(fromMap.calcType, 'Pipe ASME B31.3');
      expect(fromMap.inputs['pressureBar'], 50.0);
      expect(fromMap.results['mawpBar'], '65.20');
      expect(fromMap.engineerNotes, 'ASME B31.3 design check passed.');
    });
  });

  group('Part 4 & 5: Material Takeoff (MTO) & Counts', () {
    test('TakeoffItem calculations for weights and costs', () {
      final item = TakeoffItem(
        id: 'mto-01',
        projectId: 'proj-desert-gas',
        drawingId: 'pid-101',
        pageNumber: 1,
        itemType: TakeoffItemType.valve,
        itemName: '6" Ball Valve Class 300 RF',
        specification: 'ASTM A216 WCB / API 6D',
        size: '6" 300#',
        quantity: 5.0,
        unit: 'pcs',
        unitWeightKg: 85.0,
        unitCost: 1250.0,
        notes: 'Gear operated with locking device',
        linkedCountTag: 'HV-101',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(item.totalWeightKg, 425.0); // 5 * 85
      expect(item.totalCost, 6250.0); // 5 * 1250
      expect(item.itemType.displayName, 'Valve');
    });

    test('TakeoffItem JSON & Map serialization for SQLite', () {
      final item = TakeoffItem(
        id: 'mto-02',
        projectId: 'proj-1',
        itemType: TakeoffItemType.flange,
        itemName: 'WNRF Flange 150#',
        quantity: 12.0,
        unit: 'pcs',
        unitWeightKg: 14.5,
        unitCost: 85.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = item.toMap();
      final fromMap = TakeoffItem.fromMap(map);

      expect(fromMap.id, item.id);
      expect(fromMap.itemType, TakeoffItemType.flange);
      expect(fromMap.quantity, 12.0);
      expect(fromMap.unitWeightKg, 14.5);
      expect(fromMap.totalCost, 1020.0);
    });
  });
}
