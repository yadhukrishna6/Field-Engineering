import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';

class ActiveDrawingSessionState {
  final String drawingId;
  final int pageNumber;
  final double zoomScale;
  final double panOffsetX;
  final double panOffsetY;
  final String activeTool;
  final DateTime timestamp;

  ActiveDrawingSessionState({
    required this.drawingId,
    required this.pageNumber,
    required this.zoomScale,
    required this.panOffsetX,
    required this.panOffsetY,
    required this.activeTool,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'drawingId': drawingId,
      'pageNumber': pageNumber,
      'zoomScale': zoomScale,
      'panOffsetX': panOffsetX,
      'panOffsetY': panOffsetY,
      'activeTool': activeTool,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActiveDrawingSessionState.fromMap(Map<String, dynamic> map) {
    return ActiveDrawingSessionState(
      drawingId: map['drawingId'] as String? ?? '',
      pageNumber: map['pageNumber'] as int? ?? 0,
      zoomScale: (map['zoomScale'] as num?)?.toDouble() ?? 1.0,
      panOffsetX: (map['panOffsetX'] as num?)?.toDouble() ?? 0.0,
      panOffsetY: (map['panOffsetY'] as num?)?.toDouble() ?? 0.0,
      activeTool: map['activeTool'] as String? ?? 'select',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class CrashRecoveryService {
  static final CrashRecoveryService _instance = CrashRecoveryService._internal();
  factory CrashRecoveryService() => _instance;
  CrashRecoveryService._internal();

  ActiveDrawingSessionState? _lastSession;
  ActiveDrawingSessionState? get lastSession => _lastSession;

  /// Autosave the current active canvas state
  Future<void> autosaveDrawingSession({
    required String drawingId,
    required int pageNumber,
    required double zoomScale,
    required double panOffsetX,
    required double panOffsetY,
    required String activeTool,
  }) async {
    _lastSession = ActiveDrawingSessionState(
      drawingId: drawingId,
      pageNumber: pageNumber,
      zoomScale: zoomScale,
      panOffsetX: panOffsetX,
      panOffsetY: panOffsetY,
      activeTool: activeTool,
      timestamp: DateTime.now(),
    );

    try {
      final db = await AppDatabase.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_recovery (
          id TEXT PRIMARY KEY,
          payload TEXT,
          updatedAt TEXT
        )
      ''');

      await db.rawInsert('''
        INSERT OR REPLACE INTO session_recovery (id, payload, updatedAt)
        VALUES (?, ?, ?)
      ''', [
        'last_active_session',
        jsonEncode(_lastSession!.toMap()),
        DateTime.now().toIso8601String(),
      ]);
    } catch (e) {
      debugPrint('[CrashRecoveryService] Autosave error: $e');
    }
  }

  /// Restore last saved session after application restart
  Future<ActiveDrawingSessionState?> restoreLastSession() async {
    try {
      final db = await AppDatabase.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_recovery (
          id TEXT PRIMARY KEY,
          payload TEXT,
          updatedAt TEXT
        )
      ''');

      final results = await db.query(
        'session_recovery',
        where: 'id = ?',
        whereArgs: ['last_active_session'],
      );

      if (results.isNotEmpty) {
        final payload = jsonDecode(results.first['payload'] as String) as Map<String, dynamic>;
        _lastSession = ActiveDrawingSessionState.fromMap(payload);
        return _lastSession;
      }
    } catch (e) {
      debugPrint('[CrashRecoveryService] Restore error: $e');
    }
    return _lastSession;
  }

  /// Clear crash recovery state upon clean close
  Future<void> clearSession() async {
    _lastSession = null;
    try {
      final db = await AppDatabase.instance.database;
      await db.delete('session_recovery', where: 'id = ?', whereArgs: ['last_active_session']);
    } catch (e) {
      debugPrint('[CrashRecoveryService] Clear error: $e');
    }
  }
}
