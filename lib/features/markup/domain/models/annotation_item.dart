import 'dart:ui';
import 'package:flutter/material.dart';
import 'markup_layer.dart';
import 'point_2d.dart';
import 'stroke.dart';
import 'text_label.dart';

enum AnnotationType {
  stroke('stroke'),
  marker('marker'),
  highlighter('highlighter'),
  line('line'),
  arrow('arrow'),
  rectangle('rectangle'),
  cloud('cloud'),
  circle('circle'),
  callout('callout'),
  text('text'),
  dimension('dimension'),
  photoPin('photoPin'),
  voicePin('voicePin');

  final String code;
  const AnnotationType(this.code);

  static AnnotationType fromCode(String code) {
    return AnnotationType.values.firstWhere(
      (t) => t.code == code || t.name == code,
      orElse: () => AnnotationType.stroke,
    );
  }
}

class AnnotationItem {
  final String id;
  final AnnotationType type;
  final MarkupLayer layer;
  final Color color;
  final double strokeWidth;
  final List<Point2D> points;
  final List<Point2D>? rawPoints; // original raw stroke for single-tap "Undo snap"
  final String? text;
  final String? size; // 'S', 'M', 'L'
  final Map<String, dynamic>? metadata; // scale, dimensions, photo path, audio path, etc.

  const AnnotationItem({
    required this.id,
    required this.type,
    this.layer = MarkupLayer.markups,
    required this.color,
    required this.strokeWidth,
    required this.points,
    this.rawPoints,
    this.text,
    this.size,
    this.metadata,
  });

  double get fontSize {
    switch ((size ?? 'M').toUpperCase()) {
      case 'S':
        return 11.0;
      case 'L':
        return 18.0;
      case 'M':
      default:
        return 14.0;
    }
  }

  AnnotationItem copyWith({
    String? id,
    AnnotationType? type,
    MarkupLayer? layer,
    Color? color,
    double? strokeWidth,
    List<Point2D>? points,
    List<Point2D>? rawPoints,
    bool clearRawPoints = false,
    String? text,
    String? size,
    Map<String, dynamic>? metadata,
  }) {
    return AnnotationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      layer: layer ?? this.layer,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      points: points ?? this.points,
      rawPoints: clearRawPoints ? null : (rawPoints ?? this.rawPoints),
      text: text ?? this.text,
      size: size ?? this.size,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert legacy Stroke into AnnotationItem
  static AnnotationItem fromStroke(Stroke stroke, {MarkupLayer layer = MarkupLayer.markups}) {
    return AnnotationItem(
      id: 'strk-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.stroke,
      layer: layer,
      color: stroke.color,
      strokeWidth: stroke.strokeWidth,
      points: stroke.points,
    );
  }

  // Convert legacy TextLabel into AnnotationItem
  static AnnotationItem fromTextLabel(TextLabel label, {MarkupLayer layer = MarkupLayer.markups}) {
    return AnnotationItem(
      id: label.id,
      type: AnnotationType.text,
      layer: layer,
      color: label.color,
      strokeWidth: 1.5,
      points: [Point2D(label.x, label.y)],
      text: label.text,
      size: label.size,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.code,
    'layer': layer.name,
    'color': color.value,
    'strokeWidth': strokeWidth,
    'points': points.map((p) => p.toJson()).toList(),
    if (rawPoints != null) 'rawPoints': rawPoints!.map((p) => p.toJson()).toList(),
    if (text != null) 'text': text,
    if (size != null) 'size': size,
    if (metadata != null) 'metadata': metadata,
  };

  factory AnnotationItem.fromJson(Map<String, dynamic> json) {
    return AnnotationItem(
      id: json['id'] as String? ?? 'ann-${DateTime.now().microsecondsSinceEpoch}',
      type: AnnotationType.fromCode(json['type'] as String? ?? 'stroke'),
      layer: MarkupLayer.fromString(json['layer'] as String?),
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFD03A33),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      points: (json['points'] as List? ?? [])
          .map((p) => Point2D.fromJson(p as Map<String, dynamic>))
          .toList(),
      rawPoints: json['rawPoints'] != null
          ? (json['rawPoints'] as List)
              .map((p) => Point2D.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
      text: json['text'] as String?,
      size: json['size'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
