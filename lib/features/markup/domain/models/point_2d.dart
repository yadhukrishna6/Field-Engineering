import 'dart:ui';

class Point2D {
  final double x; // Normalized 0.0 - 1.0
  final double y; // Normalized 0.0 - 1.0

  const Point2D(this.x, this.y);

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);

  static Point2D fromOffset(Offset offset, Size size) {
    return Point2D(
      (offset.dx / size.width).clamp(0.0, 1.0),
      (offset.dy / size.height).clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory Point2D.fromJson(Map<String, dynamic> json) {
    return Point2D(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}
