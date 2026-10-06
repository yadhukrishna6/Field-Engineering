import 'dart:ui';
import 'package:flutter/material.dart';

class TextLabel {
  final String id;
  final String text;
  final double x; // Normalized 0.0 - 1.0
  final double y; // Normalized 0.0 - 1.0
  final String size; // 'S' | 'M' | 'L'
  final Color color;

  const TextLabel({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.size = 'M',
    this.color = const Color(0xFFFF3B30),
  });

  double get fontSize {
    switch (size.toUpperCase()) {
      case 'S':
        return 11.0;
      case 'L':
        return 18.0;
      case 'M':
      default:
        return 14.0;
    }
  }

  TextLabel copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    String? size,
    Color? color,
  }) {
    return TextLabel(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'x': x,
    'y': y,
    'size': size,
    'color': color.value,
  };

  factory TextLabel.fromJson(Map<String, dynamic> json) {
    return TextLabel(
      id: json['id'] as String? ?? 'lbl-${DateTime.now().millisecondsSinceEpoch}',
      text: json['text'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      size: json['size'] as String? ?? 'M',
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFF3B30),
    );
  }
}
