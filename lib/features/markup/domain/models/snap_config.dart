enum SnapAxisSet {
  isometric('Isometric 30°/90°', [0, 30, 90, 150]),
  orthogonal('Orthogonal 0°/90°', [0, 90]);

  final String label;
  final List<int> allowedAngles;
  const SnapAxisSet(this.label, this.allowedAngles);
}

class SnapConfig {
  final bool isEnabled;
  final SnapAxisSet axisSet;
  final double angleToleranceDegrees; // default 8.0 degrees
  final double endpointTolerancePixels; // default 12.0 px at 100% zoom

  const SnapConfig({
    this.isEnabled = true,
    this.axisSet = SnapAxisSet.isometric,
    this.angleToleranceDegrees = 8.0,
    this.endpointTolerancePixels = 12.0,
  });

  SnapConfig copyWith({
    bool? isEnabled,
    SnapAxisSet? axisSet,
    double? angleToleranceDegrees,
    double? endpointTolerancePixels,
  }) {
    return SnapConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      axisSet: axisSet ?? this.axisSet,
      angleToleranceDegrees: angleToleranceDegrees ?? this.angleToleranceDegrees,
      endpointTolerancePixels: endpointTolerancePixels ?? this.endpointTolerancePixels,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'axisSet': axisSet.name,
    'angleToleranceDegrees': angleToleranceDegrees,
    'endpointTolerancePixels': endpointTolerancePixels,
  };

  factory SnapConfig.fromJson(Map<String, dynamic> json) {
    return SnapConfig(
      isEnabled: json['isEnabled'] as bool? ?? true,
      axisSet: json['axisSet'] == 'orthogonal' ? SnapAxisSet.orthogonal : SnapAxisSet.isometric,
      angleToleranceDegrees: (json['angleToleranceDegrees'] as num?)?.toDouble() ?? 8.0,
      endpointTolerancePixels: (json['endpointTolerancePixels'] as num?)?.toDouble() ?? 12.0,
    );
  }
}
