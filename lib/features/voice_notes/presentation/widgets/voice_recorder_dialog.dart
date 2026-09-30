import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/services/voice_recording_service.dart';
import '../../domain/models/voice_note.dart';

class VoiceRecorderDialog extends StatefulWidget {
  final String? issueId;
  final String? inspectionId;
  final String? drawingId;
  final int pageNumber;
  final double? positionX;
  final double? positionY;

  const VoiceRecorderDialog({
    super.key,
    this.issueId,
    this.inspectionId,
    this.drawingId,
    this.pageNumber = 1,
    this.positionX,
    this.positionY,
  });

  @override
  State<VoiceRecorderDialog> createState() => _VoiceRecorderDialogState();
}

class _VoiceRecorderDialogState extends State<VoiceRecorderDialog> {
  final TextEditingController _titleController = TextEditingController();
  final VoiceRecordingService _recordingService = VoiceRecordingService.instance;
  final _uuid = const Uuid();

  bool _isRecording = false;
  int _seconds = 0;
  Timer? _waveTimer;
  List<double> _waveBars = List.filled(24, 0.2);

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Field Audio Note #${DateTime.now().minute}${DateTime.now().second}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _waveTimer?.cancel();
    if (_isRecording) {
      _recordingService.cancelRecording();
    }
    super.dispose();
  }

  void _startRecording() async {
    setState(() {
      _isRecording = true;
      _seconds = 0;
    });

    await _recordingService.startRecording(onTick: (sec) {
      if (mounted) setState(() => _seconds = sec);
    });

    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        final rand = math.Random();
        setState(() {
          _waveBars = List.generate(24, (_) => 0.15 + rand.nextDouble() * 0.85);
        });
      }
    });
  }

  void _stopAndSave() async {
    _waveTimer?.cancel();
    final result = await _recordingService.stopRecording();
    final filePath = result['filePath'] as String;
    final duration = result['durationSeconds'] as int;

    final note = VoiceNote(
      id: _uuid.v4(),
      filePath: filePath,
      title: _titleController.text.trim().isEmpty ? 'Voice Note' : _titleController.text.trim(),
      durationSeconds: duration,
      drawingId: widget.drawingId,
      pageNumber: widget.pageNumber,
      positionX: widget.positionX,
      positionY: widget.positionY,
      issueId: widget.issueId,
      inspectionId: widget.inspectionId,
      createdBy: 'Lead Field Engineer',
      createdAt: DateTime.now(),
    );

    if (mounted) {
      Navigator.pop(context, note);
    }
  }

  void _cancel() async {
    _waveTimer?.cancel();
    if (_isRecording) {
      await _recordingService.cancelRecording();
    }
    if (mounted) {
      Navigator.pop(context, null);
    }
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.safetyOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mic_rounded, color: AppColors.safetyOrange, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Record Field Voice Memo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancel,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Voice Note Title',
                hintText: 'e.g., Flange Leak Observation / Unit 102 Noise',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 24),

            // Waveform & Timer Box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isRecording ? Colors.redAccent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: _isRecording ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _formatTime(_seconds),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: _isRecording ? Colors.redAccent : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording ? 'RECORDING AUDIO IN DESERT / FIELD OFFLINE' : 'Tap record button below to start capture',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isRecording ? Colors.redAccent : AppColors.darkTextMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Animated Waveform Bars
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _waveBars.map((heightFactor) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 6,
                          height: _isRecording ? math.max(6.0, 40.0 * heightFactor) : 6.0,
                          decoration: BoxDecoration(
                            color: _isRecording ? AppColors.safetyOrange : Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Controls
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopAndSave : _startRecording,
                    icon: Icon(_isRecording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded),
                    label: Text(_isRecording ? 'Stop & Attach Note' : 'Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.redAccent : AppColors.safetyOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
