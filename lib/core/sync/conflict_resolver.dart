import 'dart:convert';
import 'package:uuid/uuid.dart';

enum ConflictResolution {
  keepLocal,
  keepServer,
  merge,
  unresolved,
}

class SyncConflictRecord {
  final String id;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> serverPayload;
  final int localVersion;
  final int serverVersion;
  final ConflictResolution resolution;
  final DateTime createdAt;

  const SyncConflictRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localPayload,
    required this.serverPayload,
    required this.localVersion,
    required this.serverVersion,
    this.resolution = ConflictResolution.unresolved,
    required this.createdAt,
  });

  factory SyncConflictRecord.create({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverPayload,
    required int localVersion,
    required int serverVersion,
  }) {
    return SyncConflictRecord(
      id: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      localPayload: localPayload,
      serverPayload: serverPayload,
      localVersion: localVersion,
      serverVersion: serverVersion,
      resolution: ConflictResolution.unresolved,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'local_payload_json': jsonEncode(localPayload),
      'server_payload_json': jsonEncode(serverPayload),
      'local_version': localVersion,
      'server_version': serverVersion,
      'resolution_status': resolution.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SyncConflictRecord.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> localMap = {};
    Map<String, dynamic> serverMap = {};
    try {
      localMap = jsonDecode(map['local_payload_json'] as String? ?? '{}') as Map<String, dynamic>;
    } catch (_) {}
    try {
      serverMap = jsonDecode(map['server_payload_json'] as String? ?? '{}') as Map<String, dynamic>;
    } catch (_) {}

    ConflictResolution res = ConflictResolution.unresolved;
    final resStr = map['resolution_status'] as String? ?? 'unresolved';
    if (resStr == 'keepLocal') res = ConflictResolution.keepLocal;
    if (resStr == 'keepServer') res = ConflictResolution.keepServer;
    if (resStr == 'merge') res = ConflictResolution.merge;

    return SyncConflictRecord(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      localPayload: localMap,
      serverPayload: serverMap,
      localVersion: (map['local_version'] as num?)?.toInt() ?? 1,
      serverVersion: (map['server_version'] as num?)?.toInt() ?? 1,
      resolution: res,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Performs a field-by-field merge where non-null, updated local values take precedence
  /// while preserving server metadata and bumping version number.
  Map<String, dynamic> mergePayloads() {
    final merged = Map<String, dynamic>.from(serverPayload);
    localPayload.forEach((key, value) {
      if (value != null && key != 'version' && key != 'created_at') {
        merged[key] = value;
      }
    });
    // Bump version for optimistic locking
    final nextVersion = ((serverVersion > localVersion ? serverVersion : localVersion) + 1);
    merged['version'] = nextVersion;
    merged['updated_at'] = DateTime.now().toIso8601String();
    return merged;
  }
}
