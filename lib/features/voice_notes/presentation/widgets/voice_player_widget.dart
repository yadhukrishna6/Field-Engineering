import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/models/voice_note.dart';

class VoicePlayerWidget extends StatefulWidget {
  final VoiceNote voiceNote;
  final VoidCallback? onDelete;
  final bool readOnly;

  const VoicePlayerWidget({
    super.key,
    required this.voiceNote,
    this.onDelete,
    this.readOnly = false,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  bool _isPlaying = false;
  int _currentSecond = 0;
  Timer? _playTimer;

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _playTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() {
        _isPlaying = true;
        if (_currentSecond >= widget.voiceNote.durationSeconds) {
          _currentSecond = 0;
        }
      });

      _playTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_currentSecond < widget.voiceNote.durationSeconds) {
          setState(() => _currentSecond++);
        } else {
          _playTimer?.cancel();
          setState(() {
            _isPlaying = false;
            _currentSecond = 0;
          });
        }
      });
    }
  }

  String _formatSeconds(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxSec = widget.voiceNote.durationSeconds > 0 ? widget.voiceNote.durationSeconds : 1;
    final progress = (_currentSecond / maxSec).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          // Play / Pause Circle Button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.safetyOrange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.voiceNote.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${_formatSeconds(_currentSecond)} / ${widget.voiceNote.formattedDuration}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.darkTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.black26 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.safetyOrange),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),

          // Delete Button
          if (!widget.readOnly && widget.onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: widget.onDelete,
              tooltip: 'Delete Voice Note',
            ),
          ],
        ],
      ),
    );
  }
}
