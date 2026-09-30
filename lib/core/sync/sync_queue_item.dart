import 'dart:convert';
import 'package:uuid/uuid.dart';

enum SyncOperation {
  create,
  update,
  delete,
  uploadFile,
}

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
}

class SyncQueueItem {
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final String payloadJson;
  final int retryCount;
  final SyncStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SyncQueueItem.create({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) {
    final now = DateTime.now();
    return SyncQueueItem(
      id: const Uuid().v4(),
      entityType: entityType.toLowerCase(),
      entityId: entityId,
      operation: operation,
      payloadJson: jsonEncode(payload),
      retryCount: 0,
      status: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.name.toUpperCase(),
      'payload_json': payloadJson,
      'retry_count': retryCount,
      'sync_status': status.name,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    SyncOperation op;
    final opStr = (map['operation'] as String? ?? 'CREATE').toUpperCase();
    if (opStr == 'UPDATE') {
      op = SyncOperation.update;
    } else if (opStr == 'DELETE') {
      op = SyncOperation.delete;
    } else if (opStr == 'UPLOAD_FILE') {
      op = SyncOperation.uploadFile;
    } else {
      op = SyncOperation.create;
    }

    SyncStatus st;
    final stStr = (map['sync_status'] as String? ?? 'pending').toLowerCase();
    if (stStr == 'syncing') {
      st = SyncStatus.syncing;
    } else if (stStr == 'synced') {
      st = SyncStatus.synced;
    } else if (stStr == 'failed') {
      st = SyncStatus.failed;
    } else if (stStr == 'conflict') {
      st = SyncStatus.conflict;
    } else {
      st = SyncStatus.pending;
    }

    return SyncQueueItem(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      operation: op,
      payloadJson: map['payload_json'] as String? ?? '{}',
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
      status: st,
      errorMessage: map['error_message'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  SyncQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    String? payloadJson,
    int? retryCount,
    SyncStatus? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
