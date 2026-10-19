import 'dart:math' as math;
import '../models/annotation_item.dart';

class PipeSpec {
  final String nps;
  final double odMm;
  final double odInch;
  final double sch40WallMm;
  final double sch80WallMm;
  final double sch160WallMm;

  const PipeSpec({
    required this.nps,
    required this.odMm,
    required this.odInch,
    required this.sch40WallMm,
    required this.sch80WallMm,
    this.sch160WallMm = 0.0,
  });

  double getInsideDiameterMm(String schedule) {
    double wall = sch40WallMm;
    if (schedule.contains('80') || schedule.toUpperCase().contains('XS')) wall = sch80WallMm;
    if (schedule.contains('160')) wall = sch160WallMm > 0 ? sch160WallMm : sch80WallMm * 1.8;
    return math.max(0.0, odMm - (2 * wall));
  }
}

class DimensionLineSum {
  final String lineTag;
  final double totalMm;
  final int segmentCount;
  final List<double> segmentsMm;

  const DimensionLineSum({
    required this.lineTag,
    required this.totalMm,
    required this.segmentCount,
    required this.segmentsMm,
  });

  double get totalMeters => totalMm / 1000.0;
  double get totalFeet => totalMm / 304.8;
  double get totalInches => totalMm / 25.4;
}

class QuantitiesTally {
  final int totalMarkups;
  final int deletionsCount;
  final int additionsCount;
  final int replacementsCount;
  final int relocationsCount;
  final int verificationsCount;
  final int photoPinsCount;
  final int officialStampsCount;
  final int dimensionsCount;
  final double totalCutLengthMeters;
  final Map<String, int> componentsByTag;

  const QuantitiesTally({
    required this.totalMarkups,
    required this.deletionsCount,
    required this.additionsCount,
    required this.replacementsCount,
    required this.relocationsCount,
    required this.verificationsCount,
    required this.photoPinsCount,
    required this.officialStampsCount,
    required this.dimensionsCount,
    required this.totalCutLengthMeters,
    required this.componentsByTag,
  });
}

class PipeVolumeResult {
  final double internalVolumeLiters;
  final double internalVolumeM3;
  final double waterWeightKg;
  final double crudeOilWeightKg;
  final double pipeSteelWeightKg;
  final double totalHydrotestWeightTonnes;

  const PipeVolumeResult({
    required this.internalVolumeLiters,
    required this.internalVolumeM3,
    required this.waterWeightKg,
    required this.crudeOilWeightKg,
    required this.pipeSteelWeightKg,
    required this.totalHydrotestWeightTonnes,
  });
}

class FieldCalculator {
  static const String disclaimer = 'ESTIMATE, VERIFY BEFORE FABRICATION';

  // --- 1. Length Conversions ---

  static double mmToMeters(double mm) => mm / 1000.0;
  static double metersToMm(double m) => m * 1000.0;
  static double mmToInches(double mm) => mm / 25.4;
  static double inchesToMm(double inches) => inches * 25.4;
  static double mmToFeet(double mm) => mm / 304.8;
  static double feetToMm(double feet) => feet * 304.8;

  static String formatFeetInches(double mm) {
    final totalInches = mm / 25.4;
    final feet = (totalInches / 12).floor();
    final remainingInches = totalInches - (feet * 12);
    final wholeInches = remainingInches.floor();
    final frac = remainingInches - wholeInches;

    String fracStr = '';
    if (frac >= 0.875) {
      return "$feet'-${wholeInches + 1}\"";
    } else if (frac >= 0.625) {
      fracStr = ' 3/4"';
    } else if (frac >= 0.375) {
      fracStr = ' 1/2"';
    } else if (frac >= 0.125) {
      fracStr = ' 1/4"';
    } else {
      fracStr = '"';
    }

    return "$feet'-$wholeInches$fracStr";
  }

  // --- 2. Pressure Conversions ---

  static double psiToBar(double psi) => psi * 0.0689476;
  static double barToPsi(double bar) => bar * 14.5038;
  static double psiToKPa(double psi) => psi * 6.89476;
  static double kPaToPsi(double kPa) => kPa / 6.89476;
  static double psiToMPa(double psi) => psi * 0.00689476;
  static double mpaToPsi(double mpa) => mpa / 0.00689476;
  static double barToMPa(double bar) => bar * 0.1;
  static double mpaToBar(double mpa) => mpa * 10.0;

  // --- 3. Standard Piping ASME/ANSI B36.10 Pipe Dimensions ---

  static const List<PipeSpec> standardPipes = [
    PipeSpec(nps: '1/2"', odMm: 21.3, odInch: 0.840, sch40WallMm: 2.77, sch80WallMm: 3.73, sch160WallMm: 4.78),
    PipeSpec(nps: '3/4"', odMm: 26.7, odInch: 1.050, sch40WallMm: 2.87, sch80WallMm: 3.91, sch160WallMm: 5.56),
    PipeSpec(nps: '1"', odMm: 33.4, odInch: 1.315, sch40WallMm: 3.38, sch80WallMm: 4.55, sch160WallMm: 6.35),
    PipeSpec(nps: '1-1/2"', odMm: 48.3, odInch: 1.900, sch40WallMm: 3.68, sch80WallMm: 5.08, sch160WallMm: 7.14),
    PipeSpec(nps: '2"', odMm: 60.3, odInch: 2.375, sch40WallMm: 3.91, sch80WallMm: 5.54, sch160WallMm: 8.74),
    PipeSpec(nps: '3"', odMm: 88.9, odInch: 3.500, sch40WallMm: 5.49, sch80WallMm: 7.62, sch160WallMm: 11.13),
    PipeSpec(nps: '4"', odMm: 114.3, odInch: 4.500, sch40WallMm: 6.02, sch80WallMm: 8.56, sch160WallMm: 13.49),
    PipeSpec(nps: '6"', odMm: 168.3, odInch: 6.625, sch40WallMm: 7.11, sch80WallMm: 10.97, sch160WallMm: 18.26),
    PipeSpec(nps: '8"', odMm: 219.1, odInch: 8.625, sch40WallMm: 8.18, sch80WallMm: 12.70, sch160WallMm: 23.01),
    PipeSpec(nps: '10"', odMm: 273.0, odInch: 10.750, sch40WallMm: 9.27, sch80WallMm: 15.09, sch160WallMm: 28.58),
    PipeSpec(nps: '12"', odMm: 323.8, odInch: 12.750, sch40WallMm: 10.31, sch80WallMm: 17.48, sch160WallMm: 33.32),
    PipeSpec(nps: '14"', odMm: 355.6, odInch: 14.000, sch40WallMm: 11.13, sch80WallMm: 19.05, sch160WallMm: 35.71),
    PipeSpec(nps: '16"', odMm: 406.4, odInch: 16.000, sch40WallMm: 12.70, sch80WallMm: 21.44, sch160WallMm: 40.49),
    PipeSpec(nps: '20"', odMm: 508.0, odInch: 20.000, sch40WallMm: 15.09, sch80WallMm: 26.19, sch160WallMm: 50.01),
    PipeSpec(nps: '24"', odMm: 609.6, odInch: 24.000, sch40WallMm: 17.48, sch80WallMm: 30.96, sch160WallMm: 59.54),
  ];

  static PipeSpec? findPipeSpec(String npsOrSize) {
    final clean = npsOrSize.replaceAll('"', '').trim();
    for (final spec in standardPipes) {
      if (spec.nps.replaceAll('"', '').trim() == clean || spec.nps == npsOrSize) {
        return spec;
      }
    }
    return null;
  }

  // --- 4. Piping Formulas: Volume, Weight & Hydrotest ---

  /// Calculates internal pipe volume, fill weight (water/oil), steel weight, and hydrotest lift weight.
  static PipeVolumeResult calculatePipeVolumeAndWeight({
    required double outerDiameterMm,
    required double wallThicknessMm,
    required double lengthMeters,
  }) {
    final innerDiameterMm = math.max(0.0, outerDiameterMm - (2 * wallThicknessMm));
    final innerRadiusM = (innerDiameterMm / 2000.0);
    final outerRadiusM = (outerDiameterMm / 2000.0);

    // Volume = PI * r^2 * L (m^3)
    final internalVolumeM3 = math.pi * (innerRadiusM * innerRadiusM) * lengthMeters;
    final internalVolumeLiters = internalVolumeM3 * 1000.0;

    // Density of water = 1000 kg/m^3
    final waterWeightKg = internalVolumeM3 * 1000.0;
    // Density of crude oil ~= 850 kg/m^3
    final crudeOilWeightKg = internalVolumeM3 * 850.0;

    // Carbon steel density ~= 7850 kg/m^3
    final steelCrossSectionM2 = math.pi * ((outerRadiusM * outerRadiusM) - (innerRadiusM * innerRadiusM));
    final pipeSteelWeightKg = steelCrossSectionM2 * lengthMeters * 7850.0;

    // Total Hydrotest Rigging Weight = Steel + Water
    final totalHydrotestWeightTonnes = (pipeSteelWeightKg + waterWeightKg) / 1000.0;

    return PipeVolumeResult(
      internalVolumeLiters: internalVolumeLiters,
      internalVolumeM3: internalVolumeM3,
      waterWeightKg: waterWeightKg,
      crudeOilWeightKg: crudeOilWeightKg,
      pipeSteelWeightKg: pipeSteelWeightKg,
      totalHydrotestWeightTonnes: totalHydrotestWeightTonnes,
    );
  }

  /// Hydrostatic test pressure estimation per ASME B31.3: P_test = 1.5 * P_design
  static double calculateHydrotestPressure(double designPressurePsi, {double factor = 1.5}) {
    return designPressurePsi * factor;
  }

  /// Thermal expansion calculation: deltaL (mm) = alpha * L (m) * deltaT (C) * 1000
  /// Carbon Steel alpha ~= 12.0 x 10^-6 m/m/C
  static double calculateThermalExpansionMm({
    required double lengthMeters,
    required double deltaTempCelsius,
    double alpha = 12.0e-6,
  }) {
    return alpha * lengthMeters * deltaTempCelsius * 1000.0;
  }

  // --- 5. Dimension Auto-Sum Aggregator ---

  static Map<String, DimensionLineSum> sumDimensionsByLineTag(List<AnnotationItem> annotations) {
    final Map<String, List<double>> grouped = {};

    for (final ann in annotations) {
      if (ann.isConflictCopy) continue;
      double? parsedValue = ann.value;

      if (parsedValue == null && ann.text != null) {
        parsedValue = _extractDimensionValueMm(ann.text!);
      }

      if (parsedValue != null && parsedValue > 0) {
        final tag = ann.attachedTag?.text ?? 'GENERAL / UNTAGGED';
        grouped.putIfAbsent(tag, () => []).add(parsedValue);
      }
    }

    final Map<String, DimensionLineSum> results = {};
    grouped.forEach((tag, values) {
      final total = values.fold<double>(0.0, (sum, val) => sum + val);
      results[tag] = DimensionLineSum(
        lineTag: tag,
        totalMm: total,
        segmentCount: values.length,
        segmentsMm: values,
      );
    });

    return results;
  }

  static double? _extractDimensionValueMm(String text) {
    // Matches patterns like "DIM 1450mm", "1450 mm", "DIM 2500", "3.2m", "1500"
    final matchM = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*m\b', caseSensitive: false).firstMatch(text);
    if (matchM != null) {
      final val = double.tryParse(matchM.group(1) ?? '');
      if (val != null) return val * 1000.0;
    }

    final matchMm = RegExp(r'(?:DIM\s*)?([0-9]+(?:\.[0-9]+)?)\s*(?:mm)?', caseSensitive: false).firstMatch(text);
    if (matchMm != null) {
      return double.tryParse(matchMm.group(1) ?? '');
    }

    return null;
  }

  // --- 6. Quantities & BOM Tally ---

  static QuantitiesTally calculateQuantitiesTally(List<AnnotationItem> annotations) {
    int total = 0;
    int del = 0;
    int add = 0;
    int rep = 0;
    int rel = 0;
    int ver = 0;
    int photo = 0;
    int stamp = 0;
    int dim = 0;
    final Map<String, int> tags = {};

    final dimSums = sumDimensionsByLineTag(annotations);
    double totalMm = 0.0;
    dimSums.forEach((_, sum) => totalMm += sum.totalMm);

    for (final ann in annotations) {
      if (ann.isConflictCopy) continue;
      total++;

      final cType = ann.changeType?.toLowerCase();
      if (cType == 'delete' || ann.type == AnnotationType.strikeOut) {
        del++;
      } else if (cType == 'add') {
        add++;
      } else if (cType == 'replace') {
        rep++;
      } else if (cType == 'relocate') {
        rel++;
      } else if (cType == 'verify') {
        ver++;
      }

      if (ann.type == AnnotationType.photoPin) photo++;
      if (ann.type == AnnotationType.stamp) stamp++;
      if (ann.type == AnnotationType.dimension || ann.value != null) dim++;

      if (ann.attachedTag != null) {
        tags[ann.attachedTag!.text] = (tags[ann.attachedTag!.text] ?? 0) + 1;
      }
    }

    return QuantitiesTally(
      totalMarkups: total,
      deletionsCount: del,
      additionsCount: add,
      replacementsCount: rep,
      relocationsCount: rel,
      verificationsCount: ver,
      photoPinsCount: photo,
      officialStampsCount: stamp,
      dimensionsCount: dim,
      totalCutLengthMeters: totalMm / 1000.0,
      componentsByTag: tags,
    );
  }
}
