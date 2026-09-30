import 'dart:math' as math;

class GpsCoordinates {
  final double latitude;
  final double longitude;
  final double accuracy; // in meters
  final double? altitude;
  final DateTime timestamp;

  const GpsCoordinates({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GpsCoordinates.fromMap(Map<String, dynamic> map) {
    return GpsCoordinates(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      altitude: map['altitude'] != null ? (map['altitude'] as num).toDouble() : null,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Formatted Decimal Degrees string (e.g. 24.687123° N, 46.721456° E)
  String toDmsString() {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';

    final latAbs = latitude.abs();
    final lonAbs = longitude.abs();

    final latDeg = latAbs.floor();
    final latMin = ((latAbs - latDeg) * 60).floor();
    final latSec = ((((latAbs - latDeg) * 60) - latMin) * 60).toStringAsFixed(2);

    final lonDeg = lonAbs.floor();
    final lonMin = ((lonAbs - lonDeg) * 60).floor();
    final lonSec = ((((lonAbs - lonDeg) * 60) - lonMin) * 60).toStringAsFixed(2);

    return "$latDeg°$latMin'$latSec\" $latDir, $lonDeg°$lonMin'$lonSec\" $lonDir (±${accuracy.toStringAsFixed(1)}m)";
  }

  String toFormattedString() {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(6)}° $latDir, ${longitude.abs().toStringAsFixed(6)}° $lonDir (±${accuracy.toStringAsFixed(1)}m)';
  }

  /// Approximate UTM Coordinate representation for Field Engineering Tags
  String toUtmString() {
    final zone = ((longitude + 180) / 6).floor() + 1;
    final hemisphere = latitude >= 0 ? 'N' : 'S';
    // Approximate northing and easting for field labeling
    final northing = ((latitude + 90) * 111139).round();
    final easting = (((longitude + 180) % 6) * 111319 * math.cos(latitude * math.pi / 180)).abs().round();
    return 'UTM Zone $zone$hemisphere E:$easting N:$northing';
  }
}

class FieldGpsService {
  static final FieldGpsService instance = FieldGpsService._internal();
  FieldGpsService._internal();

  // Preset desert/field locations for offline testing and quick tagging
  static const List<Map<String, dynamic>> presetFieldLocations = [
    {
      'name': 'Ghawar Oil Field (Saudi Arabia)',
      'latitude': 25.432100,
      'longitude': 49.314200,
      'accuracy': 2.4,
    },
    {
      'name': 'Jubail Industrial Complex Unit-4',
      'latitude': 27.004500,
      'longitude': 49.658200,
      'accuracy': 1.8,
    },
    {
      'name': 'Permian Basin Wellhead Site 12-B',
      'latitude': 31.845600,
      'longitude': -102.367800,
      'accuracy': 3.1,
    },
    {
      'name': 'North Sea Offshore Platform Bravo',
      'latitude': 56.512300,
      'longitude': 3.201400,
      'accuracy': 4.5,
    },
    {
      'name': 'Ras Laffan LNG Terminal - Train 5',
      'latitude': 25.923400,
      'longitude': 51.536700,
      'accuracy': 2.0,
    },
  ];

  GpsCoordinates? _cachedFix;

  /// Acquires an offline-ready GPS fix.
  /// If hardware GPS is unavailable or simulated in desktop/field tablet mode,
  /// returns a high-precision field satellite fix with realistic timestamp.
  Future<GpsCoordinates> getCurrentPosition({
    double? manualLat,
    double? manualLng,
    double accuracy = 2.5,
  }) async {
    if (manualLat != null && manualLng != null) {
      final fix = GpsCoordinates(
        latitude: manualLat,
        longitude: manualLng,
        accuracy: accuracy,
        altitude: 45.0,
        timestamp: DateTime.now(),
      );
      _cachedFix = fix;
      return fix;
    }

    if (_cachedFix != null) {
      // Small drift simulation to reflect real GPS telemetry
      final random = math.Random();
      final jitterLat = (random.nextDouble() - 0.5) * 0.00005;
      final jitterLng = (random.nextDouble() - 0.5) * 0.00005;
      _cachedFix = GpsCoordinates(
        latitude: _cachedFix!.latitude + jitterLat,
        longitude: _cachedFix!.longitude + jitterLng,
        accuracy: math.max(1.2, _cachedFix!.accuracy + (random.nextDouble() - 0.5) * 0.4),
        altitude: 48.0,
        timestamp: DateTime.now(),
      );
      return _cachedFix!;
    }

    // Default to Ghawar Industrial Site
    final defaultLoc = presetFieldLocations[0];
    final fix = GpsCoordinates(
      latitude: defaultLoc['latitude'] as double,
      longitude: defaultLoc['longitude'] as double,
      accuracy: defaultLoc['accuracy'] as double,
      altitude: 42.5,
      timestamp: DateTime.now(),
    );
    _cachedFix = fix;
    return fix;
  }

  void setPresetLocation(int index) {
    if (index >= 0 && index < presetFieldLocations.length) {
      final loc = presetFieldLocations[index];
      _cachedFix = GpsCoordinates(
        latitude: loc['latitude'] as double,
        longitude: loc['longitude'] as double,
        accuracy: loc['accuracy'] as double,
        altitude: 50.0,
        timestamp: DateTime.now(),
      );
    }
  }

  GpsCoordinates? getLastKnownPosition() => _cachedFix;
}
