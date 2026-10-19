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
  voicePin('voicePin'),
  noteBox('noteBox'),
  stamp('stamp'),
  strikeOut('strikeOut');

  final String code;
  const AnnotationType(this.code);

  static AnnotationType fromCode(String code) {
    return AnnotationType.values.firstWhere(
      (t) => t.code == code || t.name == code,
      orElse: () => AnnotationType.stroke,
    );
  }
}

class AttachedTag {
  final String text;
  final List<double>? bbox;

  const AttachedTag({
    required this.text,
    this.bbox,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    if (bbox != null) 'bbox': bbox,
  };

  factory AttachedTag.fromJson(Map<String, dynamic> json) {
    return AttachedTag(
      text: json['text'] as String? ?? '',
      bbox: (json['bbox'] as List?)?.map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class GpsCoord {
  final double lat;
  final double lng;

  const GpsCoord({required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory GpsCoord.fromJson(Map<String, dynamic> json) {
    return GpsCoord(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
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
  final List<Point2D>? rawPoints;
  final String? text;
  final String? size;
  final Map<String, dynamic>? metadata;

  final String? changeType;
  final int? quantity;
  final String? unit;
  final double? value;
  final AttachedTag? attachedTag;
  final List<String>? photoIds;
  final GpsCoord? gps;
  final String? author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? status;
  final bool isConflictCopy;
  final String? conflictOriginalId;

  AnnotationItem({
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
    this.changeType,
    this.quantity,
    this.unit,
    this.value,
    this.attachedTag,
    this.photoIds,
    this.gps,
    this.author,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status,
    this.isConflictCopy = false,
    this.conflictOriginalId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
    String? changeType,
    int? quantity,
    String? unit,
    double? value,
    AttachedTag? attachedTag,
    List<String>? photoIds,
    GpsCoord? gps,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    bool? isConflictCopy,
    String? conflictOriginalId,
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
      changeType: changeType ?? this.changeType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      value: value ?? this.value,
      attachedTag: attachedTag ?? this.attachedTag,
      photoIds: photoIds ?? this.photoIds,
      gps: gps ?? this.gps,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
      isConflictCopy: isConflictCopy ?? this.isConflictCopy,
      conflictOriginalId: conflictOriginalId ?? this.conflictOriginalId,
    );
  }

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
    if (changeType != null) 'changeType': changeType,
    if (quantity != null) 'quantity': quantity,
    if (unit != null) 'unit': unit,
    if (value != null) 'value': value,
    if (attachedTag != null) 'attachedTag': attachedTag!.toJson(),
    if (photoIds != null) 'photoIds': photoIds,
    if (gps != null) 'gps': gps!.toJson(),
    if (author != null) 'author': author,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (status != null) 'status': status,
    'isConflictCopy': isConflictCopy,
    if (conflictOriginalId != null) 'conflictOriginalId': conflictOriginalId,
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
      changeType: json['changeType'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      attachedTag: json['attachedTag'] != null
          ? AttachedTag.fromJson(json['attachedTag'] as Map<String, dynamic>)
          : null,
      photoIds: (json['photoIds'] as List?)?.map((e) => e.toString()).toList(),
      gps: json['gps'] != null
          ? GpsCoord.fromJson(json['gps'] as Map<String, dynamic>)
          : null,
      author: json['author'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String?,
      isConflictCopy: json['isConflictCopy'] as bool? ?? false,
      conflictOriginalId: json['conflictOriginalId'] as String?,
    );
  }
}
