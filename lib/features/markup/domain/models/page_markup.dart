import 'dart:convert';
import 'annotation_item.dart';
import 'stroke.dart';
import 'text_label.dart';

class PageMarkup {
  final String drawingId;
  final int pageNumber;
  final List<AnnotationItem> annotations;
  final int version;
  final DateTime? updatedAt;
  final double? scaleRatio; // real meters per normalized unit

  PageMarkup({
    required this.drawingId,
    required this.pageNumber,
    List<AnnotationItem>? annotations,
    List<Stroke>? strokes,
    List<TextLabel>? labels,
    this.version = 2,
    this.updatedAt,
    this.scaleRatio,
  }) : annotations = annotations ?? [
         if (strokes != null) ...strokes.map((s) => AnnotationItem.fromStroke(s)),
         if (labels != null) ...labels.map((l) => AnnotationItem.fromTextLabel(l)),
       ];

  // Legacy backwards compatibility getters
  List<Stroke> get strokes => annotations
      .where((a) => a.type != AnnotationType.text && a.type != AnnotationType.photoPin && a.type != AnnotationType.voicePin)
      .map((a) => Stroke(points: a.points, color: a.color, strokeWidth: a.strokeWidth))
      .toList();

  List<TextLabel> get labels => annotations
      .where((a) => a.type == AnnotationType.text)
      .map((a) => TextLabel(
            id: a.id,
            text: a.text ?? '',
            x: a.points.isNotEmpty ? a.points.first.x : 0.0,
            y: a.points.isNotEmpty ? a.points.first.y : 0.0,
            size: a.size ?? 'M',
            color: a.color,
          ))
      .toList();

  PageMarkup copyWith({
    String? drawingId,
    int? pageNumber,
    List<AnnotationItem>? annotations,
    List<Stroke>? strokes,
    List<TextLabel>? labels,
    int? version,
    DateTime? updatedAt,
    double? scaleRatio,
  }) {
    return PageMarkup(
      drawingId: drawingId ?? this.drawingId,
      pageNumber: pageNumber ?? this.pageNumber,
      annotations: annotations ?? this.annotations,
      strokes: strokes,
      labels: labels,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      scaleRatio: scaleRatio ?? this.scaleRatio,
    );
  }

  Map<String, dynamic> toJson() => {
    'drawingId': drawingId,
    'pageNumber': pageNumber,
    'annotations': annotations.map((a) => a.toJson()).toList(),
    'version': version,
    'updatedAt': updatedAt?.toIso8601String(),
    if (scaleRatio != null) 'scaleRatio': scaleRatio,
    // Keep strokes & labels for Quarkus backward-compatibility
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'labels': labels.map((l) => l.toJson()).toList(),
  };

  String toPayloadJson() {
    return jsonEncode({
      'annotations': annotations.map((a) => a.toJson()).toList(),
      if (scaleRatio != null) 'scaleRatio': scaleRatio,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'labels': labels.map((l) => l.toJson()).toList(),
    });
  }

  factory PageMarkup.fromJson(Map<String, dynamic> json) {
    List<AnnotationItem> parsedAnnotations = [];

    if (json['annotations'] is List) {
      parsedAnnotations = (json['annotations'] as List)
          .map((a) => AnnotationItem.fromJson(a as Map<String, dynamic>))
          .toList();
    } else {
      // Fallback: parse legacy strokes and labels
      if (json['strokes'] is List) {
        for (final s in json['strokes'] as List) {
          parsedAnnotations.add(AnnotationItem.fromStroke(Stroke.fromJson(s as Map<String, dynamic>)));
        }
      }
      if (json['labels'] is List) {
        for (final l in json['labels'] as List) {
          parsedAnnotations.add(AnnotationItem.fromTextLabel(TextLabel.fromJson(l as Map<String, dynamic>)));
        }
      }
    }

    if (json['payload'] is String) {
      try {
        final payloadMap = jsonDecode(json['payload'] as String);
        if (payloadMap['annotations'] is List) {
          parsedAnnotations = (payloadMap['annotations'] as List)
              .map((a) => AnnotationItem.fromJson(a as Map<String, dynamic>))
              .toList();
        } else {
          if (payloadMap['strokes'] is List) {
            for (final s in payloadMap['strokes'] as List) {
              parsedAnnotations.add(AnnotationItem.fromStroke(Stroke.fromJson(s as Map<String, dynamic>)));
            }
          }
          if (payloadMap['labels'] is List) {
            for (final l in payloadMap['labels'] as List) {
              parsedAnnotations.add(AnnotationItem.fromTextLabel(TextLabel.fromJson(l as Map<String, dynamic>)));
            }
          }
        }
      } catch (_) {}
    }

    return PageMarkup(
      drawingId: json['drawingId'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      annotations: parsedAnnotations,
      version: (json['version'] as num?)?.toInt() ?? 2,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      scaleRatio: (json['scaleRatio'] as num?)?.toDouble(),
    );
  }
}
