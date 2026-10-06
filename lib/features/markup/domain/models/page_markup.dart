import 'dart:convert';
import 'stroke.dart';

class PageMarkup {
  final String drawingId;
  final int pageNumber;
  final List<Stroke> strokes;
  final int version;
  final DateTime? updatedAt;

  const PageMarkup({
    required this.drawingId,
    required this.pageNumber,
    required this.strokes,
    this.version = 1,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'drawingId': drawingId,
    'pageNumber': pageNumber,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'version': version,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  String toPayloadJson() {
    return jsonEncode({
      'strokes': strokes.map((s) => s.toJson()).toList(),
    });
  }

  factory PageMarkup.fromJson(Map<String, dynamic> json) {
    List<Stroke> parsedStrokes = [];
    if (json['strokes'] is List) {
      parsedStrokes = (json['strokes'] as List)
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (json['payload'] is String) {
      try {
        final payloadMap = jsonDecode(json['payload'] as String);
        if (payloadMap['strokes'] is List) {
          parsedStrokes = (payloadMap['strokes'] as List)
              .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return PageMarkup(
      drawingId: json['drawingId'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      strokes: parsedStrokes,
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
