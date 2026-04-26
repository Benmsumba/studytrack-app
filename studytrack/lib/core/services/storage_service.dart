import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

class UploadResult {
  const UploadResult({
    required this.noteId,
    required this.fileUrl,
    required this.chunksCount,
  });

  final String noteId;
  final String fileUrl;
  final int chunksCount;
}

class StorageService {
  StorageService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  static const String _defaultBackendUrl = String.fromEnvironment(
    'DOCUMENT_BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  final SupabaseService _supabaseService;
  final ValueNotifier<double> uploadProgress = ValueNotifier<double>(0);

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

    final uri = Uri.parse('$_defaultBackendUrl/process-document');
    final boundary = 'studytrack-${DateTime.now().millisecondsSinceEpoch}';

    final bodyBuilder = BytesBuilder();
    void addField(String name, String value) {
      bodyBuilder
        ..add(utf8.encode('--$boundary\r\n'))
        ..add(
          utf8.encode(
            'Content-Disposition: form-data; name="$name"\r\n\r\n',
          ),
        )
        ..add(utf8.encode(value))
        ..add(utf8.encode('\r\n'));
    }

    addField('topic_id', topicId);
    addField('user_id', userId);
    addField('is_shared', isSharedWithGroup ? 'true' : 'false');

    final mimeType = ext == 'pdf'
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

    bodyBuilder
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(
        utf8.encode(
          'Content-Disposition: form-data; name="file"; filename="$filename"\r\n',
        ),
      )
      ..add(utf8.encode('Content-Type: $mimeType\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));

    final payload = bodyBuilder.takeBytes();

    try {
      final client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      request.headers.set(HttpHeaders.contentLengthHeader, payload.length);

      const chunkSize = 16 * 1024;
      var sent = 0;
      while (sent < payload.length) {
        final end = (sent + chunkSize > payload.length)
            ? payload.length
            : sent + chunkSize;
        request.add(payload.sublist(sent, end));
        sent = end;
        uploadProgress.value = sent / payload.length;
      }

      final response = await request.close();
      final responseText = await utf8.decoder.bind(response).join();
      client.close();

      if (response.statusCode < 200 || response.statusCode > 299) {
        return null;
      }

      final json = jsonDecode(responseText) as Map<String, dynamic>;
      final noteId = (json['note_id'] ?? '').toString();
      final fileUrl = (json['file_url'] ?? '').toString();
      final chunksCount = (json['chunks_count'] as num?)?.toInt() ?? 0;
      if (noteId.isEmpty || fileUrl.isEmpty) {
        return null;
      }

      final ready = await _waitForProcessingReady(noteId);
      if (!ready) {
        return null;
      }

      uploadProgress.value = 1;
      return UploadResult(
        noteId: noteId,
        fileUrl: fileUrl,
        chunksCount: chunksCount,
      );
    } catch (_) {
      return null;
    }
  }

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

  Future<bool> _waitForProcessingReady(String noteId) async {
    for (var i = 0; i < 40; i++) {
      final row = await _supabaseService.client
          .from('uploaded_notes')
          .select('processing_status')
          .eq('id', noteId)
          .maybeSingle();

      final status = (row?['processing_status'] as String?) ?? '';
      if (status == 'ready') {
        return true;
      }
      if (status == 'failed') {
        return false;
      }

      await Future<void>.delayed(const Duration(seconds: 3));
    }

    return false;
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
