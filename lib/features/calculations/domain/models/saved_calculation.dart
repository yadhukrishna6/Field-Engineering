import 'dart:convert';

class SavedCalculation {
  final String id;
  final String? projectId;
  final String? drawingId;
  final String calcType;
  final String title;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> results;
  final String? engineerNotes;
  final DateTime createdAt;

  const SavedCalculation({
    required this.id,
    this.projectId,
    this.drawingId,
    required this.calcType,
    required this.title,
    required this.inputs,
    required this.results,
    this.engineerNotes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'drawing_id': drawingId,
      'calc_type': calcType,
      'title': title,
      'inputs_json': jsonEncode(inputs),
      'results_json': jsonEncode(results),
      'engineer_notes': engineerNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedCalculation.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> inMap = {};
    if (map['inputs_json'] != null) {
      try {
        inMap = jsonDecode(map['inputs_json'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    Map<String, dynamic> resMap = {};
    if (map['results_json'] != null) {
      try {
        resMap = jsonDecode(map['results_json'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return SavedCalculation(
      id: map['id'] as String,
      projectId: map['project_id'] as String?,
      drawingId: map['drawing_id'] as String?,
      calcType: map['calc_type'] as String? ?? 'General',
      title: map['title'] as String? ?? 'Calculation',
      inputs: inMap,
      results: resMap,
      engineerNotes: map['engineer_notes'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
