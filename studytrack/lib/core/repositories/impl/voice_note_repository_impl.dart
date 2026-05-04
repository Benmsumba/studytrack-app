import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/voice_note_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../voice_note_repository.dart';

class VoiceNoteRepositoryImpl implements VoiceNoteRepository {
  VoiceNoteRepositoryImpl(this._voiceNoteService);

  final VoiceNoteService _voiceNoteService;

  @override
  Future<Result<String>> requestMicrophonePermissions() async {
    try {
      final hasPermission = await _voiceNoteService.requestPermissions();
      if (!hasPermission) {
        return Failure(
          DataException(
            message: 'Microphone permission denied',
            code: 'PERMISSION_DENIED',
          ),
        );
      }
      return const Success('Microphone permission granted');
    } catch (e) {
      debugPrint('requestMicrophonePermissions error: $e');
      return Failure(
        DataException(
          message: 'Failed to request microphone permissions: $e',
          code: 'PERMISSION_REQUEST_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<String>> createRecordingPath({
    required String topicId,
    required String userId,
  }) async {
    try {
      final path = await _voiceNoteService.createRecordingPath(
        topicId: topicId,
        userId: userId,
      );
      return Success(path);
    } catch (e) {
      debugPrint('createRecordingPath error: $e');
      return Failure(
        DataException(
          message: 'Failed to create recording path: $e',
          code: 'PATH_CREATION_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<String>> startRecording(String outputPath) async {
    try {
      final path = await _voiceNoteService.startRecording(outputPath);
      if (path == null) {
        return Failure(
          DataException(
            message: 'Failed to start recording',
            code: 'RECORDING_START_FAILED',
          ),
        );
      }
      return Success(path);
    } catch (e) {
      debugPrint('startRecording error: $e');
      return Failure(
        DataException(
          message: 'Failed to start recording: $e',
          code: 'RECORDING_START_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<String>> stopRecording() async {
    try {
      final path = await _voiceNoteService.stopRecording();
      if (path == null) {
        return Failure(
          DataException(
            message: 'Failed to stop recording',
            code: 'RECORDING_STOP_FAILED',
          ),
        );
      }
      return Success(path);
    } catch (e) {
      debugPrint('stopRecording error: $e');
      return Failure(
        DataException(
          message: 'Failed to stop recording: $e',
          code: 'RECORDING_STOP_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<String>> transcribeAudio(File audioFile) async {
    try {
      final transcription = await _voiceNoteService.transcribeAudio(audioFile);
      if (transcription == null || transcription.isEmpty) {
        return Failure(
          DataException(
            message: 'Failed to transcribe audio',
            code: 'TRANSCRIPTION_FAILED',
          ),
        );
      }
      return Success(transcription);
    } catch (e) {
      debugPrint('transcribeAudio error: $e');
      return Failure(
        DataException(
          message: 'Failed to transcribe audio: $e',
          code: 'TRANSCRIPTION_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<VoiceNote>> uploadVoiceNote({
    required String topicId,
    required String userId,
    required File audioFile,
    required String transcription,
    bool isSharedWithGroup = false,
  }) async {
    try {
      final result = await _voiceNoteService.uploadVoiceNote(
        topicId: topicId,
        userId: userId,
        audioFile: audioFile,
        transcription: transcription,
        isSharedWithGroup: isSharedWithGroup,
      );

      if (result == null) {
        return Failure(
          DataException(
            message: 'Failed to upload voice note',
            code: 'UPLOAD_FAILED',
          ),
        );
      }

      return Success(
        VoiceNote(
          id: result.noteId ?? '',
          topicId: topicId,
          userId: userId,
          transcription: result.transcription,
          fileUrl: result.fileUrl ?? '',
          localPath: result.localPath,
          fileName: audioFile.path.split('/').last,
          createdAt: DateTime.now(),
          isSharedWithGroup: isSharedWithGroup,
        ),
      );
    } catch (e) {
      debugPrint('uploadVoiceNote error: $e');
      return Failure(
        DataException(
          message: 'Failed to upload voice note: $e',
          code: 'UPLOAD_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<VoiceNote>> transcribeAndUploadRecording({
    required String topicId,
    required String userId,
    required String localPath,
    bool isSharedWithGroup = false,
  }) async {
    try {
      final audioFile = File(localPath);

      // Transcribe the audio
      final transcription = await _voiceNoteService.transcribeAudio(audioFile);
      if (transcription == null || transcription.isEmpty) {
        return Failure(
          DataException(
            message: 'Failed to transcribe recording',
            code: 'TRANSCRIPTION_FAILED',
          ),
        );
      }

      // Upload the voice note
      final result = await _voiceNoteService.uploadVoiceNote(
        topicId: topicId,
        userId: userId,
        audioFile: audioFile,
        transcription: transcription,
        isSharedWithGroup: isSharedWithGroup,
      );

      if (result == null) {
        return Failure(
          DataException(
            message: 'Failed to upload transcribed recording',
            code: 'UPLOAD_FAILED',
          ),
        );
      }

      return Success(
        VoiceNote(
          id: result.noteId ?? '',
          topicId: topicId,
          userId: userId,
          transcription: result.transcription,
          fileUrl: result.fileUrl ?? '',
          localPath: result.localPath,
          fileName: audioFile.path.split('/').last,
          createdAt: DateTime.now(),
          isSharedWithGroup: isSharedWithGroup,
        ),
      );
    } catch (e) {
      debugPrint('transcribeAndUploadRecording error: $e');
      return Failure(
        DataException(
          message: 'Failed to transcribe and upload recording: $e',
          code: 'TRANSCRIPTION_UPLOAD_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<void>> playAudio(String pathOrUrl) async {
    try {
      await _voiceNoteService.play(pathOrUrl);
      return const Success(null);
    } catch (e) {
      debugPrint('playAudio error: $e');
      return Failure(
        DataException(
          message: 'Failed to play audio: $e',
          code: 'PLAYBACK_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<void>> pauseAudio() async {
    try {
      await _voiceNoteService.pause();
      return const Success(null);
    } catch (e) {
      debugPrint('pauseAudio error: $e');
      return Failure(
        DataException(
          message: 'Failed to pause audio: $e',
          code: 'PAUSE_FAILED',
        ),
      );
    }
  }

  @override
  Future<Result<void>> stopAudio() async {
    try {
      await _voiceNoteService.stopPlayback();
      return const Success(null);
    } catch (e) {
      debugPrint('stopAudio error: $e');
      return Failure(
        DataException(message: 'Failed to stop audio: $e', code: 'STOP_FAILED'),
      );
    }
  }
}
