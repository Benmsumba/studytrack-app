import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class UploadResult {
  const UploadResult({
    required this.noteId,
    required this.fileUrl,
  });

  final String noteId;
  final String fileUrl;
}

class StorageService {
  StorageService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  final SupabaseService _supabaseService;
  final ValueNotifier<double> uploadProgress = ValueNotifier<double>(0);

  /// Upload a note file directly to Supabase Storage (PDF or PPTX)
  Future<UploadResult?> uploadNoteFile({
    required File file,
    required String topicId,
    required String userId,
    required bool isSharedWithGroup,
  }) async {
    uploadProgress.value = 0;

    final filename = file.path.split(Platform.pathSeparator).last;
    final ext = filename.toLowerCase().split('.').last;
    if (ext != 'pdf' && ext != 'pptx') {
      return null;
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    try {
      // Generate unique file path in Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'notes/$userId/$topicId/$timestamp-$filename';

      // Upload file to Supabase Storage
      final response = await _supabaseService.client.storage
          .from('uploaded_files')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      if (response.isEmpty) {
        return null;
      }

      // Get public URL for the uploaded file
      final fileUrl = _supabaseService.client.storage
          .from('uploaded_files')
          .getPublicUrl(storagePath);

      // Create note record in Supabase database
      final noteResponse = await _supabaseService.client
          .from('uploaded_notes')
          .insert({
            'topic_id': topicId,
            'user_id': userId,
            'file_name': filename,
            'file_url': fileUrl,
            'file_type': ext,
            'is_shared_with_group': isSharedWithGroup,
            'processing_status': 'ready', // Mark as ready immediately
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final noteId = (noteResponse['id'] ?? '').toString();
      if (noteId.isEmpty) {
        return null;
      }

      uploadProgress.value = 1;
      return UploadResult(
        noteId: noteId,
        fileUrl: fileUrl,
      );
    } catch (_) {
      return null;
    }
  }


  /// Get relevant note context from all notes in a topic (ranked by keyword relevance)
  Future<String> getNoteContext({
    required String topicId,
    required String searchQuery,
  }) async {
    final notes =
        await _supabaseService.getNotesByTopic(topicId) ?? <Map<String, dynamic>>[];

    final allChunks = <String>[];
    for (final note in notes) {
      final status = (note['processing_status'] as String?) ?? 'pending';
      if (status != 'ready') {
        continue;
      }

      final noteId = note['id'] as String?;
      if (noteId == null || noteId.isEmpty) {
        continue;
      }

      final chunks =
          await _supabaseService.getNoteChunks(noteId) ?? <Map<String, dynamic>>[];
      for (final chunk in chunks) {
        final content = (chunk['content'] as String?)?.trim();
        if (content != null && content.isNotEmpty) {
          allChunks.add(content);
        }
      }
    }

    if (allChunks.isEmpty) {
      return '';
    }

    final ranked = _rankChunksByKeyword(allChunks, searchQuery, maxChunks: 5);
    return ranked.join('\n\n');
  }

  List<String> _rankChunksByKeyword(
    List<String> chunks,
    String searchQuery, {
    int maxChunks = 5,
  }) {
    final tokens = searchQuery
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return chunks.take(maxChunks).toList();
    }

    final scored = chunks.map((chunk) {
      final haystack = chunk.toLowerCase();
      var score = 0;
      for (final token in tokens) {
        score += token.allMatches(haystack).length;
      }
      return _ChunkScore(content: chunk, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    final top = scored
        .where((item) => item.score > 0)
        .take(maxChunks)
        .map((item) => item.content)
        .toList();

    if (top.isEmpty) {
      return chunks.take(maxChunks).toList();
    }
    return top;
  }
}

class _ChunkScore {
  const _ChunkScore({required this.content, required this.score});

  final String content;
  final int score;
}
