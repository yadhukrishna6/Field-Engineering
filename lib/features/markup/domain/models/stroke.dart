import 'dart:ui';
import 'point_2d.dart';

class Stroke {
  final List<Point2D> points;
  final Color color;
  final double strokeWidth;

  const Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color.value,
    'strokeWidth': strokeWidth,
  };

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List? ?? [])
          .map((p) => Point2D.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFF3B30),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
    );
  }
}
