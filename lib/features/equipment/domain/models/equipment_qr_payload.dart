import 'dart:convert';

class EquipmentQrPayload {
  final String tagNumber;
  final String equipmentNumber;
  final String name;
  final String projectId;
  final String? drawingId;
  final String discipline;

  const EquipmentQrPayload({
    required this.tagNumber,
    required this.equipmentNumber,
    required this.name,
    required this.projectId,
    this.drawingId,
    required this.discipline,
  });

  String toQrString() {
    return jsonEncode({
      'tag': tagNumber,
      'eqNo': equipmentNumber,
      'name': name,
      'prj': projectId,
      'dwg': drawingId,
      'disc': discipline,
    });
  }

  static EquipmentQrPayload? parse(String rawContent) {
    try {
      if (rawContent.startsWith('{')) {
        final map = jsonDecode(rawContent) as Map<String, dynamic>;
        return EquipmentQrPayload(
          tagNumber: map['tag'] as String? ?? 'TAG-UNKNOWN',
          equipmentNumber: map['eqNo'] as String? ?? 'EQ-UNKNOWN',
          name: map['name'] as String? ?? 'Field Equipment',
          projectId: map['prj'] as String? ?? 'PRJ-101',
          drawingId: map['dwg'] as String?,
          discipline: map['disc'] as String? ?? 'Mechanical',
        );
      } else {
        // Plain text tag (e.g. "P-102A" or "V-101" or "FCV-101")
        final trimmed = rawContent.trim().toUpperCase();
        return EquipmentQrPayload(
          tagNumber: trimmed,
          equipmentNumber: 'EQ-$trimmed',
          name: 'Equipment Item ($trimmed)',
          projectId: 'PRJ-101',
          discipline: trimmed.startsWith('P') ? 'Pumps' : (trimmed.startsWith('V') ? 'Vessels' : 'Instrumentation'),
        );
      }
    } catch (_) {
      return null;
    }
  }
}
