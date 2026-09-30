import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_tables.dart';
import 'secure_storage_service.dart';
import 'rbac_manager.dart';

class AuditLogEntry {
  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String userEmail;
  final String userRole;
  final String details;
  final String ipAddress;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.userEmail,
    required this.userRole,
    required this.details,
    required this.ipAddress,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.colId: id,
      DatabaseTables.colAction: action,
      DatabaseTables.colEntityType: entityType,
      DatabaseTables.colEntityId: entityId,
      DatabaseTables.colUserEmail: userEmail,
      DatabaseTables.colUserRole: userRole,
      DatabaseTables.colDetails: details,
      DatabaseTables.colIpAddress: ipAddress,
      DatabaseTables.colCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map[DatabaseTables.colId] as String,
      action: map[DatabaseTables.colAction] as String,
      entityType: map[DatabaseTables.colEntityType] as String? ?? 'SYSTEM',
      entityId: map[DatabaseTables.colEntityId] as String? ?? '',
      userEmail: map[DatabaseTables.colUserEmail] as String? ?? 'unknown',
      userRole: map[DatabaseTables.colUserRole] as String? ?? 'Lead Engineer',
      details: map[DatabaseTables.colDetails] as String? ?? '',
      ipAddress: map[DatabaseTables.colIpAddress] as String? ?? '127.0.0.1 (Offline)',
      createdAt: DateTime.tryParse(map[DatabaseTables.colCreatedAt] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class AuditLogger {
  static final AuditLogger _instance = AuditLogger._internal();
  factory AuditLogger() => _instance;
  AuditLogger._internal();

  Future<void> log({
    required String action,
    String entityType = 'SYSTEM',
    String entityId = '',
    String details = '',
  }) async {
    try {
      final user = SecureStorageService().currentUser;
      final entry = AuditLogEntry(
        id: const Uuid().v4(),
        action: action,
        entityType: entityType,
        entityId: entityId,
        userEmail: user.email,
        userRole: user.role.displayName,
        details: details,
        ipAddress: '192.168.1.100 (Field Tablet)',
        createdAt: DateTime.now(),
      );

      final db = await AppDatabase.instance.database;
      await db.insert(DatabaseTables.auditLogs, entry.toMap());
    } catch (_) {
      // Non-blocking audit logger
    }
  }

  Future<List<AuditLogEntry>> getRecentLogs({int limit = 100}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      DatabaseTables.auditLogs,
      orderBy: '${DatabaseTables.colCreatedAt} DESC',
      limit: limit,
    );
    return rows.map((r) => AuditLogEntry.fromMap(r)).toList();
  }
}
