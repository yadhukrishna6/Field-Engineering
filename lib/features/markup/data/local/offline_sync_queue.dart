import '../../domain/models/annotation_item.dart';

enum SyncQueueAction {
  create('create'),
  update('update'),
  delete('delete');

  final String code;
  const SyncQueueAction(this.code);

  static SyncQueueAction fromCode(String code) {
    return SyncQueueAction.values.firstWhere(
      (a) => a.code == code || a.name == code,
      orElse: () => SyncQueueAction.update,
    );
  }
}

enum SyncEntityType {
  drawing('drawing'),
  pageMarkup('pageMarkup');

  final String code;
  const SyncEntityType(this.code);

  static SyncEntityType fromCode(String code) {
    return SyncEntityType.values.firstWhere(
      (e) => e.code == code || e.name == code,
      orElse: () => SyncEntityType.pageMarkup,
    );
  }
}

class SyncQueueItem {
  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncQueueAction action;
  final String payloadJson;
  final DateTime timestamp;
  final int retryCount;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payloadJson,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType.code,
    'entityId': entityId,
    'action': action.code,
    'payloadJson': payloadJson,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      entityType: SyncEntityType.fromCode(json['entityType'] as String? ?? 'pageMarkup'),
      entityId: json['entityId'] as String,
      action: SyncQueueAction.fromCode(json['action'] as String? ?? 'update'),
      payloadJson: json['payloadJson'] as String? ?? '{}',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnnotationConflictResolver {
  static List<AnnotationItem> resolveConflicts({
    required List<AnnotationItem> localAnnotations,
    required List<AnnotationItem> remoteAnnotations,
  }) {
    final Map<String, AnnotationItem> localMap = {
      for (final a in localAnnotations.where((item) => !item.isConflictCopy)) a.id: a
    };
    final Map<String, AnnotationItem> remoteMap = {
      for (final a in remoteAnnotations.where((item) => !item.isConflictCopy)) a.id: a
    };

    final List<AnnotationItem> result = [];
    final Set<String> processedIds = {};

    for (final entry in localMap.entries) {
      final id = entry.key;
      final local = entry.value;
      processedIds.add(id);

      if (!remoteMap.containsKey(id)) {
        result.add(local);
      } else {
        final remote = remoteMap[id]!;
        if (local.updatedAt.isAfter(remote.updatedAt) || local.updatedAt.isAtSameMomentAs(remote.updatedAt)) {
          result.add(local);
          result.add(remote.copyWith(
            id: 'conflict-${remote.id}-${remote.updatedAt.millisecondsSinceEpoch}',
            isConflictCopy: true,
            conflictOriginalId: local.id,
          ));
        } else {
          result.add(remote);
          result.add(local.copyWith(
            id: 'conflict-${local.id}-${local.updatedAt.millisecondsSinceEpoch}',
            isConflictCopy: true,
            conflictOriginalId: remote.id,
          ));
        }
      }
    }

    for (final entry in remoteMap.entries) {
      final id = entry.key;
      final remote = entry.value;
      if (!processedIds.contains(id)) {
        result.add(remote);
      }
    }

    final existingConflictCopies = [
      ...localAnnotations.where((a) => a.isConflictCopy),
      ...remoteAnnotations.where((a) => a.isConflictCopy),
    ];
    final Set<String> conflictIds = result.map((a) => a.id).toSet();
    for (final c in existingConflictCopies) {
      if (!conflictIds.contains(c.id)) {
        result.add(c);
        conflictIds.add(c.id);
      }
    }

    return result;
  }

  static List<AnnotationItem> restoreConflictCopy({
    required List<AnnotationItem> annotations,
    required String conflictCopyId,
  }) {
    final conflictIndex = annotations.indexWhere((a) => a.id == conflictCopyId && a.isConflictCopy);
    if (conflictIndex == -1) return List.from(annotations);

    final conflictCopy = annotations[conflictIndex];
    final originalId = conflictCopy.conflictOriginalId ?? conflictCopy.id.replaceFirst(RegExp(r'^conflict-'), '');

    final list = List<AnnotationItem>.from(annotations);
    list.removeAt(conflictIndex);

    final activeIndex = list.indexWhere((a) => a.id == originalId && !a.isConflictCopy);
    if (activeIndex != -1) {
      final oldActive = list[activeIndex];
      list[activeIndex] = oldActive.copyWith(
        id: 'conflict-${oldActive.id}-${DateTime.now().millisecondsSinceEpoch}',
        isConflictCopy: true,
        conflictOriginalId: originalId,
      );
    }

    list.add(conflictCopy.copyWith(
      id: originalId,
      isConflictCopy: false,
      conflictOriginalId: null,
      updatedAt: DateTime.now(),
    ));

    return list;
  }
}
