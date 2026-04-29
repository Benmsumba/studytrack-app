import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class VoiceNotePlayerWidget extends StatefulWidget {
  const VoiceNotePlayerWidget({
    required this.source, super.key,
    this.title = 'Voice note',
    this.subtitle,
  });

  final String source;
  final String title;
  final String? subtitle;

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    if (widget.source.startsWith('http')) {
      await _player.play(UrlSource(widget.source));
    } else {
      await _player.play(DeviceFileSource(widget.source));
    }
    setState(() => _isPlaying = true);
  }

  Future<void> _stop() async {
    await _player.stop();
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _togglePlayback,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            ),
            color: AppColors.accent,
            iconSize: 30,
          ),
          IconButton(
            onPressed: _stop,
            icon: const Icon(Icons.stop_circle_outlined),
            color: AppColors.textSecondary,
            iconSize: 28,
          ),
        ],
      ),
    );
}
