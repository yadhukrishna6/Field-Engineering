import 'package:flutter/material.dart';

enum AsBuiltStage {
  issuedDrawing,
  fieldMarkup,
  fieldVerification,
  engineerReview,
  approved,
  asBuiltRecord,
}

extension AsBuiltStageExtension on AsBuiltStage {
  String get displayName {
    switch (this) {
      case AsBuiltStage.issuedDrawing:
        return '1. Issued Drawing (IFC)';
      case AsBuiltStage.fieldMarkup:
        return '2. Field Markup (Redline)';
      case AsBuiltStage.fieldVerification:
        return '3. Field Verification';
      case AsBuiltStage.engineerReview:
        return '4. Engineer Review';
      case AsBuiltStage.approved:
        return '5. Approved';
      case AsBuiltStage.asBuiltRecord:
        return '6. As-Built Record';
    }
  }

  String get shortCode {
    switch (this) {
      case AsBuiltStage.issuedDrawing:
        return 'IFC';
      case AsBuiltStage.fieldMarkup:
        return 'REDLINE';
      case AsBuiltStage.fieldVerification:
        return 'VERIFIED';
      case AsBuiltStage.engineerReview:
        return 'REVIEW';
      case AsBuiltStage.approved:
        return 'APPROVED';
      case AsBuiltStage.asBuiltRecord:
        return 'AS-BUILT';
    }
  }

  Color get color {
    switch (this) {
      case AsBuiltStage.issuedDrawing:
        return Colors.blueAccent;
      case AsBuiltStage.fieldMarkup:
        return Colors.orangeAccent;
      case AsBuiltStage.fieldVerification:
        return Colors.amberAccent;
      case AsBuiltStage.engineerReview:
        return Colors.purpleAccent;
      case AsBuiltStage.approved:
        return Colors.tealAccent;
      case AsBuiltStage.asBuiltRecord:
        return Colors.greenAccent;
    }
  }

  IconData get icon {
    switch (this) {
      case AsBuiltStage.issuedDrawing:
        return Icons.assignment_outlined;
      case AsBuiltStage.fieldMarkup:
        return Icons.edit_note_rounded;
      case AsBuiltStage.fieldVerification:
        return Icons.fact_check_outlined;
      case AsBuiltStage.engineerReview:
        return Icons.rate_review_outlined;
      case AsBuiltStage.approved:
        return Icons.check_circle_outline_rounded;
      case AsBuiltStage.asBuiltRecord:
        return Icons.verified_user_rounded;
    }
  }

  AsBuiltStage? get nextStage {
    final index = AsBuiltStage.values.indexOf(this);
    if (index < AsBuiltStage.values.length - 1) {
      return AsBuiltStage.values[index + 1];
    }
    return null;
  }
}

class AsBuiltRecordMeta {
  final String drawingId;
  final AsBuiltStage stage;
  final String engineerName;
  final String comments;
  final bool includeInAsBuiltReport;
  final DateTime updatedAt;

  const AsBuiltRecordMeta({
    required this.drawingId,
    required this.stage,
    required this.engineerName,
    this.comments = '',
    this.includeInAsBuiltReport = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'drawing_id': drawingId,
      'stage': stage.name,
      'engineer_name': engineerName,
      'comments': comments,
      'include_in_as_built_report': includeInAsBuiltReport ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AsBuiltRecordMeta.fromMap(Map<String, dynamic> map) {
    AsBuiltStage st = AsBuiltStage.issuedDrawing;
    final stStr = map['stage'] as String? ?? 'issuedDrawing';
    for (final s in AsBuiltStage.values) {
      if (s.name == stStr) st = s;
    }

    return AsBuiltRecordMeta(
      drawingId: map['drawing_id'] as String,
      stage: st,
      engineerName: map['engineer_name'] as String? ?? 'Lead Field Engineer',
      comments: map['comments'] as String? ?? '',
      includeInAsBuiltReport: (map['include_in_as_built_report'] as num?)?.toInt() == 1,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
