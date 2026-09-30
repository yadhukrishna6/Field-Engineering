import 'package:uuid/uuid.dart';

class DrawingBookmark {
  final String id;
  final String drawingId;
  final String drawingNumber;
  final String title;
  final int pageNumber;
  final String label;
  final String notes;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastViewedAt;

  const DrawingBookmark({
    required this.id,
    required this.drawingId,
    required this.drawingNumber,
    required this.title,
    this.pageNumber = 1,
    required this.label,
    this.notes = '',
    this.isFavorite = false,
    required this.createdAt,
    this.lastViewedAt,
  });

  factory DrawingBookmark.create({
    required String drawingId,
    required String drawingNumber,
    required String title,
    int pageNumber = 1,
    required String label,
    String notes = '',
    bool isFavorite = false,
  }) {
    return DrawingBookmark(
      id: const Uuid().v4(),
      drawingId: drawingId,
      drawingNumber: drawingNumber,
      title: title,
      pageNumber: pageNumber,
      label: label,
      notes: notes,
      isFavorite: isFavorite,
      createdAt: DateTime.now(),
      lastViewedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drawing_id': drawingId,
      'drawing_number': drawingNumber,
      'title': title,
      'page_number': pageNumber,
      'label': label,
      'notes': notes,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_viewed_at': lastViewedAt?.toIso8601String(),
    };
  }

  factory DrawingBookmark.fromMap(Map<String, dynamic> map) {
    return DrawingBookmark(
      id: map['id'] as String,
      drawingId: map['drawing_id'] as String,
      drawingNumber: map['drawing_number'] as String? ?? '',
      title: map['title'] as String? ?? '',
      pageNumber: (map['page_number'] as num?)?.toInt() ?? 1,
      label: map['label'] as String? ?? 'Bookmark',
      notes: map['notes'] as String? ?? '',
      isFavorite: (map['is_favorite'] as num?)?.toInt() == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      lastViewedAt: map['last_viewed_at'] != null ? DateTime.tryParse(map['last_viewed_at'] as String) : null,
    );
  }
}
