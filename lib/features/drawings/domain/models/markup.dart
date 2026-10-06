import 'dart:convert';
import 'package:flutter/material.dart';

enum MarkupType {
  pen,
  highlighter,
  line,
  arrow,
  circle,
  rectangle,
  polygon,
  revisionCloud,
  text,
  measurement,
  issuePin,
  photoPin,
  stamp,
  eraser,
}

extension MarkupTypeExtension on MarkupType {
  String get displayName {
    switch (this) {
      case MarkupType.pen:
        return 'Pen';
      case MarkupType.highlighter:
        return 'Highlighter';
      case MarkupType.line:
        return 'Line';
      case MarkupType.arrow:
        return 'Arrow Leader';
      case MarkupType.circle:
        return 'Circle / Ellipse';
      case MarkupType.rectangle:
        return 'Rectangle';
      case MarkupType.polygon:
        return 'Polygon';
      case MarkupType.revisionCloud:
        return 'Revision Cloud';
      case MarkupType.text:
        return 'Text Callout';
      case MarkupType.measurement:
        return 'Dimension Ruler';
      case MarkupType.issuePin:
        return 'Punchlist Pin';
      case MarkupType.photoPin:
        return 'Photo Callout';
      case MarkupType.stamp:
        return 'Field Stamp';
      case MarkupType.eraser:
        return 'Eraser';
    }
  }

  IconData get icon {
    switch (this) {
      case MarkupType.pen:
        return Icons.edit_rounded;
      case MarkupType.highlighter:
        return Icons.brush_rounded;
      case MarkupType.line:
        return Icons.horizontal_rule_rounded;
      case MarkupType.arrow:
        return Icons.arrow_right_alt_rounded;
      case MarkupType.circle:
        return Icons.circle_outlined;
      case MarkupType.rectangle:
        return Icons.crop_square_rounded;
      case MarkupType.polygon:
        return Icons.polyline_rounded;
      case MarkupType.revisionCloud:
        return Icons.cloud_outlined;
      case MarkupType.text:
        return Icons.text_fields_rounded;
      case MarkupType.measurement:
        return Icons.straighten_rounded;
      case MarkupType.issuePin:
        return Icons.report_problem_rounded;
      case MarkupType.photoPin:
        return Icons.photo_camera_rounded;
      case MarkupType.stamp:
        return Icons.verified_outlined;
      case MarkupType.eraser:
        return Icons.auto_fix_high_rounded;
    }
  }
}

enum DrawingLayer {
  original,
  markup,
  measurement,
  issue,
  photo,
  inspection,
  previousRevision,
}

extension DrawingLayerExtension on DrawingLayer {
  String get displayName {
    switch (this) {
      case DrawingLayer.original:
        return 'Original Drawing';
      case DrawingLayer.markup:
        return 'Markups & Clouds';
      case DrawingLayer.measurement:
        return 'Measurements & Dimensions';
      case DrawingLayer.issue:
        return 'Punchlist Issues';
      case DrawingLayer.photo:
        return 'Site Inspection Photos';
      case DrawingLayer.inspection:
        return 'QA/QC Inspection Stamps';
      case DrawingLayer.previousRevision:
        return 'Previous Revision Overlay';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawingLayer.original:
        return Icons.picture_as_pdf_rounded;
      case DrawingLayer.markup:
        return Icons.draw_rounded;
      case DrawingLayer.measurement:
        return Icons.square_foot_rounded;
      case DrawingLayer.issue:
        return Icons.warning_amber_rounded;
      case DrawingLayer.photo:
        return Icons.camera_alt_outlined;
      case DrawingLayer.inspection:
        return Icons.approval_rounded;
      case DrawingLayer.previousRevision:
        return Icons.compare_rounded;
    }
  }
}

/// Normalized 2D point [0.0 - 1.0] relative to original engineering page dimensions
class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  factory Point2D.fromMap(Map<String, dynamic> map) => Point2D(
        (map['x'] as num).toDouble(),
        (map['y'] as num).toDouble(),
      );

  Offset toOffset(Size pageSize) => Offset(x * pageSize.width, y * pageSize.height);

  static Point2D fromOffset(Offset offset, Size pageSize) => Point2D(
        offset.dx / pageSize.width,
        offset.dy / pageSize.height,
      );
}

class Markup {
  final String id;
  final String drawingId;
  final String? revisionId;
  final int pageNumber;
  final DrawingLayer layer;
  final MarkupType type;
  final Color color;
  final Color? fillColor;
  final double strokeWidth;
  final double opacity;
  final List<Point2D> points;
  final Rect? bounds; // In normalized coordinates
  final String? text;
  final double? fontSize;
  final double? rotation; // in radians
  final Point2D? leaderPoint; // Optional leader arrow target
  final bool hasHalo; // Backdrop halo box for text readability
  final String status; // 'Open', 'Addressed', 'Closed'
  final int version; // Optimistic locking
  final bool deleted;
  final Map<String, dynamic>? metadata;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Markup({
    required this.id,
    required this.drawingId,
    this.revisionId,
    this.pageNumber = 1,
    this.layer = DrawingLayer.markup,
    required this.type,
    required this.color,
    this.fillColor,
    this.strokeWidth = 2.0,
    this.opacity = 1.0,
    this.points = const [],
    this.bounds,
    this.text,
    this.fontSize = 13.0,
    this.rotation = 0.0,
    this.leaderPoint,
    this.hasHalo = true,
    this.status = 'Open',
    this.version = 1,
    this.deleted = false,
    this.metadata,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Markup copyWith({
    String? id,
    String? drawingId,
    String? revisionId,
    int? pageNumber,
    DrawingLayer? layer,
    MarkupType? type,
    Color? color,
    Color? fillColor,
    double? strokeWidth,
    double? opacity,
    List<Point2D>? points,
    Rect? bounds,
    String? text,
    double? fontSize,
    double? rotation,
    Point2D? leaderPoint,
    bool? hasHalo,
    String? status,
    int? version,
    bool? deleted,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Markup(
      id: id ?? this.id,
      drawingId: drawingId ?? this.drawingId,
      revisionId: revisionId ?? this.revisionId,
      pageNumber: pageNumber ?? this.pageNumber,
      layer: layer ?? this.layer,
      type: type ?? this.type,
      color: color ?? this.color,
      fillColor: fillColor ?? this.fillColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      points: points ?? this.points,
      bounds: bounds ?? this.bounds,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      rotation: rotation ?? this.rotation,
      leaderPoint: leaderPoint ?? this.leaderPoint,
      hasHalo: hasHalo ?? this.hasHalo,
      status: status ?? this.status,
      version: version ?? this.version,
      deleted: deleted ?? this.deleted,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final geometryMap = {
      'points': points.map((p) => p.toMap()).toList(),
      if (bounds != null)
        'bounds': {
          'left': bounds!.left,
          'top': bounds!.top,
          'right': bounds!.right,
          'bottom': bounds!.bottom,
        },
      if (fontSize != null) 'fontSize': fontSize,
      if (rotation != null) 'rotation': rotation,
      if (leaderPoint != null) 'leaderPoint': leaderPoint!.toMap(),
      'hasHalo': hasHalo,
    };

    return {
      'id': id,
      'drawing_id': drawingId,
      'revision_id': revisionId,
      'page_number': pageNumber,
      'layer': layer.name,
      'type': type.name,
      'color': color.value,
      'fill_color': fillColor?.value,
      'stroke_width': strokeWidth,
      'opacity': opacity,
      'geometry_data': jsonEncode(geometryMap),
      'text': text,
      'status': status,
      'version': version,
      'deleted': deleted ? 1 : 0,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Markup.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> geometry = {};
    if (map['geometry_data'] != null && map['geometry_data'].toString().isNotEmpty) {
      try {
        geometry = jsonDecode(map['geometry_data'] as String);
      } catch (_) {}
    }

    final pointsList = (geometry['points'] as List<dynamic>?)
            ?.map((p) => Point2D.fromMap(p as Map<String, dynamic>))
            .toList() ??
        [];

    Rect? bounds;
    if (geometry['bounds'] != null) {
      final b = geometry['bounds'] as Map<String, dynamic>;
      bounds = Rect.fromLTRB(
        (b['left'] as num).toDouble(),
        (b['top'] as num).toDouble(),
        (b['right'] as num).toDouble(),
        (b['bottom'] as num).toDouble(),
      );
    }

    Point2D? leaderPoint;
    if (geometry['leaderPoint'] != null) {
      leaderPoint = Point2D.fromMap(geometry['leaderPoint'] as Map<String, dynamic>);
    }

    Map<String, dynamic>? metadata;
    if (map['metadata'] != null && map['metadata'].toString().isNotEmpty) {
      try {
        metadata = jsonDecode(map['metadata'] as String);
      } catch (_) {}
    }

    return Markup(
      id: map['id'] as String,
      drawingId: (map['drawing_id'] ?? map['drawingId']) as String? ?? '',
      revisionId: (map['revision_id'] ?? map['revisionId']) as String?,
      pageNumber: (map['page_number'] ?? map['pageNumber'] as num?)?.toInt() ?? 1,
      layer: DrawingLayer.values.firstWhere(
        (l) => l.name == map['layer'],
        orElse: () => DrawingLayer.markup,
      ),
      type: MarkupType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => MarkupType.pen,
      ),
      color: Color((map['color'] as num?)?.toInt() ?? 0xFFFF0000),
      fillColor: map['fill_color'] != null || map['fillColor'] != null
          ? Color(((map['fill_color'] ?? map['fillColor']) as num).toInt())
          : null,
      strokeWidth: ((map['stroke_width'] ?? map['strokeWidth']) as num?)?.toDouble() ?? 2.0,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      points: pointsList,
      bounds: bounds,
      text: map['text'] as String?,
      fontSize: (geometry['fontSize'] as num?)?.toDouble() ?? 13.0,
      rotation: (geometry['rotation'] as num?)?.toDouble() ?? 0.0,
      leaderPoint: leaderPoint,
      hasHalo: geometry['hasHalo'] as bool? ?? true,
      status: map['status'] as String? ?? 'Open',
      version: (map['version'] as num?)?.toInt() ?? 1,
      deleted: (map['deleted'] == 1 || map['deleted'] == true),
      metadata: metadata,
      createdBy: (map['created_by'] ?? map['createdBy']) as String? ?? 'Engineer',
      createdAt: DateTime.tryParse((map['created_at'] ?? map['createdAt']) as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? map['updatedAt']) as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Convert to JSON format matching Quarkus backend REST API
  Map<String, dynamic> toJson() => toMap();

  factory Markup.fromJson(Map<String, dynamic> json) => Markup.fromMap(json);
}
