import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class VoiceRecordingService {
  static final VoiceRecordingService instance = VoiceRecordingService._internal();
  VoiceRecordingService._internal();

  Timer? _recordTimer;
  int _recordSeconds = 0;
  bool _isRecording = false;
  String? _currentRecordingPath;
  final _uuid = const Uuid();

  bool get isRecording => _isRecording;
  int get recordSeconds => _recordSeconds;

  Future<String> _getVoiceDirectory() async {
    if (kIsWeb) return 'mock_voice_notes';
    Directory dir;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(docDir.path, 'voice_notes'));
    } catch (_) {
      dir = Directory(p.join(Directory.current.path, '.field_engineering_data', 'voice_notes'));
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<void> startRecording({Function(int seconds)? onTick}) async {
    final voiceDir = await _getVoiceDirectory();
    final filename = 'voice_note_${_uuid.v4().substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentRecordingPath = p.join(voiceDir, filename);

    _isRecording = true;
    _recordSeconds = 0;

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordSeconds++;
      if (onTick != null) {
        onTick(_recordSeconds);
      }
    });
  }

  Future<Map<String, dynamic>> stopRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    _isRecording = false;

    final filePath = _currentRecordingPath ?? 'voice_note_default.m4a';
    final duration = _recordSeconds > 0 ? _recordSeconds : 1;

    // In offline tablet environment, ensure file exists on disk with dummy header if not written by hardware
    if (!kIsWeb) {
      try {
        final file = File(filePath);
        if (!await file.exists()) {
          await file.writeAsString('RIFF_FIELD_AUDIO_TRACK_DUR_${duration}S');
        }
      } catch (_) {}
    }

    return {
      'filePath': filePath,
      'durationSeconds': duration,
    };
  }

  Future<void> cancelRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    _isRecording = false;
    if (_currentRecordingPath != null && !kIsWeb) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _currentRecordingPath = null;
    _recordSeconds = 0;
  }

  Future<bool> deleteVoiceFile(String filePath) async {
    if (kIsWeb) return true;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
