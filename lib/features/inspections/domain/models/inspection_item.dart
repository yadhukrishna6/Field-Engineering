import 'dart:convert';
import 'package:flutter/material.dart';

enum ChecklistStatus {
  pending('PENDING', Icons.hourglass_empty_rounded, Color(0xFFFF9800)),
  pass('PASS', Icons.check_circle_rounded, Color(0xFF4CAF50)),
  fail('FAIL', Icons.cancel_rounded, Color(0xFFD32F2F)),
  na('N/A', Icons.block_rounded, Color(0xFF9E9E9E));

  final String label;
  final IconData icon;
  final Color color;
  const ChecklistStatus(this.label, this.icon, this.color);

  static ChecklistStatus fromString(String? val) {
    if (val == null) return ChecklistStatus.pending;
    final normalized = val.toUpperCase().trim();
    return ChecklistStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == normalized || e.label == normalized,
      orElse: () => ChecklistStatus.pending,
    );
  }
}

class InspectionItem {
  final String id;
  final String inspectionId;
  final String category;
  final String description;
  final ChecklistStatus status;
  final String? comments;
  final List<String> photoIds;
  final int orderIndex;

  const InspectionItem({
    required this.id,
    required this.inspectionId,
    required this.category,
    required this.description,
    this.status = ChecklistStatus.pending,
    this.comments,
    this.photoIds = const [],
    this.orderIndex = 0,
  });

  InspectionItem copyWith({
    String? id,
    String? inspectionId,
    String? category,
    String? description,
    ChecklistStatus? status,
    String? comments,
    List<String>? photoIds,
    int? orderIndex,
  }) {
    return InspectionItem(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      photoIds: photoIds ?? this.photoIds,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'category': category,
      'description': description,
      'status': status.label,
      'comments': comments,
      'photo_ids_json': jsonEncode(photoIds),
      'order_index': orderIndex,
    };
  }

  factory InspectionItem.fromMap(Map<String, dynamic> map) {
    List<String> photos = [];
    final jsonStr = map['photo_ids_json'] as String?;
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        photos = (jsonDecode(jsonStr) as List).map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return InspectionItem(
      id: map['id'] as String,
      inspectionId: (map['inspection_id'] ?? map['inspectionId']) as String,
      category: (map['category'] ?? 'General') as String,
      description: (map['description'] ?? '') as String,
      status: ChecklistStatus.fromString(map['status'] as String?),
      comments: map['comments'] as String?,
      photoIds: photos,
      orderIndex: (map['order_index'] ?? map['orderIndex'] ?? 0) as int,
    );
  }
}
