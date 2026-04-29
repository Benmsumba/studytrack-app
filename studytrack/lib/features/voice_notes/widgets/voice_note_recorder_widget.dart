import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/voice_note_service.dart';
import 'voice_note_player_widget.dart';

class VoiceNoteRecorderWidget extends StatefulWidget {
  const VoiceNoteRecorderWidget({
    required this.topicId,
    super.key,
    this.onSaved,
    this.allowUpload = true,
    this.title = 'Voice Notes',
    this.subtitle = 'Record, transcribe and save a study note',
  });

  final String? topicId;
  final Future<void> Function(VoiceNoteResult result)? onSaved;
  final bool allowUpload;
  final String title;
  final String subtitle;

  @override
  State<VoiceNoteRecorderWidget> createState() =>
      _VoiceNoteRecorderWidgetState();
}

class _VoiceNoteRecorderWidgetState extends State<VoiceNoteRecorderWidget> {
  final VoiceNoteService _service = VoiceNoteService(
    geminiApiKey: AppConstants.resolvedGeminiApiKey,
  );
  final SupabaseService _supabaseService = SupabaseService();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordingPath;
  VoiceNoteResult? _result;
  String? _status;

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    final user = _supabaseService.getCurrentUser();
    if (user == null) {
      setState(() => _status = 'Please login first.');
      return;
    }

    final topicId = widget.topicId;
    if (!_isRecording) {
      final path = await _service.createRecordingPath(
        userId: user.id,
        topicId: topicId == null || topicId.isEmpty ? 'chat' : topicId,
      );
      final started = await _service.startRecording(path);
      if (started == null) {
        setState(() => _status = 'Microphone permission is required.');
        return;
      }
      setState(() {
        _isRecording = true;
        _recordingPath = started;
        _status = 'Recording... tap stop when you are done.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Transcribing your voice note...';
    });

    final stopped = await _service.stopRecording();
    if (stopped == null) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
        _status = 'Recording stopped, but no file was saved.';
      });
      return;
    }

    final result = widget.allowUpload && topicId != null && topicId.isNotEmpty
        ? await _service.transcribeAndUploadRecording(
            topicId: topicId,
            userId: user.id,
            localPath: stopped,
            isSharedWithGroup: false,
          )
        : VoiceNoteResult(
            transcription:
                await _service.transcribeAudio(File(stopped)) ?? 'Voice note',
            localPath: stopped,
          );

    setState(() {
      _isRecording = false;
      _isProcessing = false;
      _recordingPath = stopped;
      _result = result;
      _status = result == null
          ? 'Could not upload the voice note.'
          : 'Voice note saved successfully.';
    });

    if (result != null) {
      await widget.onSaved?.call(result);
    }
  }

  Future<void> _discard() async {
    await _service.stopPlayback();
    setState(() {
      _isRecording = false;
      _isProcessing = false;
      _recordingPath = null;
      _result = null;
      _status = 'Voice note discarded.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final canShowPreview =
        _recordingPath != null && File(_recordingPath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_status != null) ...[
            Text(
              _status!,
              style: GoogleFonts.inter(
                color: _result == null
                    ? AppColors.textSecondary
                    : AppColors.success,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_result != null) ...[
            VoiceNotePlayerWidget(
              source: _result!.localPath,
              title: 'Recorded voice note',
              subtitle: _result!.transcription,
            ),
            const SizedBox(height: 12),
          ] else if (canShowPreview) ...[
            VoiceNotePlayerWidget(
              source: _recordingPath!,
              title: 'Preview recording',
              subtitle: 'Listen before uploading',
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: _isProcessing ? null : _toggleRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isRecording ? 'Stop recording' : 'Start recording',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(onPressed: _discard, child: const Text('Discard')),
            ],
          ),
        ],
      ),
    );
  }
}
