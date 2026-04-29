import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'supabase_service.dart';

class VoiceNoteResult {
  const VoiceNoteResult({
    required this.transcription,
    required this.localPath,
    this.noteId,
    this.fileUrl,
  });

  final String transcription;
  final String localPath;
  final String? noteId;
  final String? fileUrl;

  bool get isUploaded => noteId != null && fileUrl != null;
}

class VoiceNoteService {
  VoiceNoteService({SupabaseService? supabaseService, String? geminiApiKey})
    : _supabaseService = supabaseService ?? SupabaseService(),
      _geminiApiKey = geminiApiKey;

  final SupabaseService _supabaseService;
  final String? _geminiApiKey;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool get isRecording => _isRecording;
  bool _isRecording = false;

  Future<bool> requestPermissions() async {
    final mic = await Permission.microphone.request();
    return mic.isGranted && await _recorder.hasPermission();
  }

  Future<String> createRecordingPath({
    required String topicId,
    required String userId,
  }) async {
    final directory = await getTemporaryDirectory();
    final folder = Directory('${directory.path}/voice_notes/$userId/$topicId');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${folder.path}/voice_note_$timestamp.m4a';
  }

  Future<String?> startRecording(String outputPath) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      return null;
    }

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: outputPath,
      );
      _isRecording = true;
      return outputPath;
    } catch (error) {
      debugPrint('startRecording error: $error');
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (error) {
      debugPrint('stopRecording error: $error');
      _isRecording = false;
      return null;
    }
  }

  Future<void> play(String pathOrUrl) async {
    try {
      if (pathOrUrl.startsWith('http')) {
        await _player.play(UrlSource(pathOrUrl));
      } else {
        await _player.play(DeviceFileSource(pathOrUrl));
      }
    } catch (error) {
      debugPrint('play voice note error: $error');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<String?> transcribeAudio(File audioFile) async {
    try {
      final apiKey = _geminiApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }

      final bytes = await audioFile.readAsBytes();
      if (bytes.isEmpty) {
        return null;
      }

      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

      final response = await model.generateContent([
        Content.multi([
          TextPart(
            'Transcribe this voice note clearly. Return only the transcript text.',
          ),
          DataPart('audio/m4a', bytes),
        ]),
      ]);

      return response.text?.trim();
    } catch (error) {
      debugPrint('transcribeAudio error: $error');
      return null;
    }
  }

  Future<VoiceNoteResult?> uploadVoiceNote({
    required String topicId,
    required String userId,
    required File audioFile,
    required String transcription,
    bool isSharedWithGroup = false,
  }) async {
    try {
      final filename = audioFile.path.split(Platform.pathSeparator).last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'voice_notes/$userId/$topicId/$timestamp-$filename';

      final bytes = await audioFile.readAsBytes();
      final uploadResponse = await _supabaseService.client.storage
          .from('uploaded_files')
          .uploadBinary(storagePath, bytes);

      if (uploadResponse.isEmpty) {
        return null;
      }

      final fileUrl = _supabaseService.client.storage
          .from('uploaded_files')
          .getPublicUrl(storagePath);

      final noteResponse = await _supabaseService.client
          .from('uploaded_notes')
          .insert({
            'topic_id': topicId,
            'user_id': userId,
            'file_name': filename,
            'file_url': fileUrl,
            'file_type': 'm4a',
            'is_shared_with_group': isSharedWithGroup,
            'processing_status': 'ready',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final noteId = (noteResponse['id'] ?? '').toString();
      if (noteId.isEmpty) {
        return null;
      }

      final chunks = _splitTranscript(transcription);
      if (chunks.isNotEmpty) {
        await _supabaseService.saveNoteChunks(noteId, chunks);
      }

      return VoiceNoteResult(
        transcription: transcription,
        localPath: audioFile.path,
        noteId: noteId,
        fileUrl: fileUrl,
      );
    } catch (error) {
      debugPrint('uploadVoiceNote error: $error');
      return null;
    }
  }

  Future<VoiceNoteResult?> transcribeAndUploadRecording({
    required String topicId,
    required String userId,
    required String localPath,
    bool isSharedWithGroup = false,
  }) async {
    final audioFile = File(localPath);
    final transcription = await transcribeAudio(audioFile) ?? 'Voice note';
    return uploadVoiceNote(
      topicId: topicId,
      userId: userId,
      audioFile: audioFile,
      transcription: transcription,
      isSharedWithGroup: isSharedWithGroup,
    );
  }

  List<String> _splitTranscript(String transcription) {
    final cleaned = transcription.trim();
    if (cleaned.isEmpty) {
      return const [];
    }

    final words = cleaned.split(RegExp(r'\s+'));
    const chunkSize = 80;
    final chunks = <String>[];
    for (var i = 0; i < words.length; i += chunkSize) {
      final end = (i + chunkSize) > words.length ? words.length : i + chunkSize;
      chunks.add(words.sublist(i, end).join(' '));
    }
    return chunks;
  }
}
