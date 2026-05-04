import 'dart:io';

import '../utils/result.dart';

/// Voice note with metadata
class VoiceNote {
  const VoiceNote({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.transcription,
    required this.fileUrl,
    required this.localPath,
    this.fileName,
    this.createdAt,
    this.isSharedWithGroup = false,
  });

  final String id;
  final String topicId;
  final String userId;
  final String transcription;
  final String fileUrl;
  final String localPath;
  final String? fileName;
  final DateTime? createdAt;
  final bool isSharedWithGroup;
}

/// Repository abstraction for voice notes (recording, transcription, upload)
abstract class VoiceNoteRepository {
  Future<Result<String>> requestMicrophonePermissions();

  Future<Result<String>> createRecordingPath({
    required String topicId,
    required String userId,
  });

  Future<Result<String>> startRecording(String outputPath);

  Future<Result<String>> stopRecording();

  Future<Result<String>> transcribeAudio(File audioFile);

  Future<Result<VoiceNote>> uploadVoiceNote({
    required String topicId,
    required String userId,
    required File audioFile,
    required String transcription,
    bool isSharedWithGroup = false,
  });

  Future<Result<VoiceNote>> transcribeAndUploadRecording({
    required String topicId,
    required String userId,
    required String localPath,
    bool isSharedWithGroup = false,
  });

  Future<Result<void>> playAudio(String pathOrUrl);

  Future<Result<void>> pauseAudio();

  Future<Result<void>> stopAudio();
}
