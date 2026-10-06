import 'dart:convert';
import 'stroke.dart';
import 'text_label.dart';

class PageMarkup {
  final String drawingId;
  final int pageNumber;
  final List<Stroke> strokes;
  final List<TextLabel> labels;
  final int version;
  final DateTime? updatedAt;

  const PageMarkup({
    required this.drawingId,
    required this.pageNumber,
    required this.strokes,
    this.labels = const [],
    this.version = 1,
    this.updatedAt,
  });

  PageMarkup copyWith({
    String? drawingId,
    int? pageNumber,
    List<Stroke>? strokes,
    List<TextLabel>? labels,
    int? version,
    DateTime? updatedAt,
  }) {
    return PageMarkup(
      drawingId: drawingId ?? this.drawingId,
      pageNumber: pageNumber ?? this.pageNumber,
      strokes: strokes ?? this.strokes,
      labels: labels ?? this.labels,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'drawingId': drawingId,
    'pageNumber': pageNumber,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'labels': labels.map((l) => l.toJson()).toList(),
    'version': version,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  String toPayloadJson() {
    return jsonEncode({
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'labels': labels.map((l) => l.toJson()).toList(),
    });
  }

  factory PageMarkup.fromJson(Map<String, dynamic> json) {
    List<Stroke> parsedStrokes = [];
    List<TextLabel> parsedLabels = [];

    if (json['strokes'] is List) {
      parsedStrokes = (json['strokes'] as List)
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    if (json['labels'] is List) {
      parsedLabels = (json['labels'] as List)
          .map((l) => TextLabel.fromJson(l as Map<String, dynamic>))
          .toList();
    }

    if (json['payload'] is String) {
      try {
        final payloadMap = jsonDecode(json['payload'] as String);
        if (payloadMap['strokes'] is List) {
          parsedStrokes = (payloadMap['strokes'] as List)
              .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
              .toList();
        }
        if (payloadMap['labels'] is List) {
          parsedLabels = (payloadMap['labels'] as List)
              .map((l) => TextLabel.fromJson(l as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return PageMarkup(
      drawingId: json['drawingId'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      strokes: parsedStrokes,
      labels: parsedLabels,
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
