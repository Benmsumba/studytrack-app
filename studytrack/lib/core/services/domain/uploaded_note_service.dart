import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_logger.dart';

import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class UploadedNoteService extends DomainServiceBase {
  UploadedNoteService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;

// UPLOADED NOTES
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>?> saveUploadedNote(
  Map<String, dynamic> data,
) async {
  try {
    final id = newId();
    final payload = {
      'id': id,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    };
    final topicId = data['topic_id']?.toString() ?? 'notes';
    if (await isOnline()) {
      final response = await client
          .from('uploaded_notes')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord(
          'uploaded_notes',
          response['id'].toString(),
          response,
        );
      }
      return response;
    }

    await queueChange('uploaded_notes', 'insert', payload, recordId: id);
    await cacheRecord('uploaded_notes', id, payload);
    final cached = await cachedList('uploaded_notes', topicId) ?? [];
    await cacheList('uploaded_notes', topicId, [...cached, payload]);
    return payload;
  } catch (error) {
    AppLogger.warning('saveUploadedNote error', error: error);
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getNotesByTopic(String topicId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('uploaded_notes')
          .select()
          .eq('topic_id', topicId)
          .order('created_at', ascending: false);
      final rows = activeRows(response as List<dynamic>);
      await cacheList('uploaded_notes', topicId, rows);
      return rows;
    }

    return activeRows(
      await cachedList('uploaded_notes', topicId) ?? const [],
    );
  } catch (error) {
    AppLogger.warning('getNotesByTopic error', error: error);
    return activeRows(
      await cachedList('uploaded_notes', topicId) ?? const [],
    );
  }
}

Future<List<Map<String, dynamic>>?> getSharedUploadedNotes({
  int limit = 40,
}) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('uploaded_notes')
          .select()
          .eq('is_shared_with_group', true)
          .order('created_at', ascending: false)
          .limit(limit);
      final rows = activeRows(response as List<dynamic>);
      await cacheList('shared_uploaded_notes', 'all', rows);
      return rows;
    }

    return activeRows(
      await cachedList('shared_uploaded_notes', 'all') ?? const [],
    );
  } catch (error) {
    AppLogger.warning('getSharedUploadedNotes error', error: error);
    return activeRows(
      await cachedList('shared_uploaded_notes', 'all') ?? const [],
    );
  }
}

Future<Map<String, dynamic>?> updateNoteProcessingStatus(
  String noteId,
  String status,
) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('uploaded_notes')
          .update({'processing_status': status})
          .eq('id', noteId)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('uploaded_notes', noteId, response);
      }
      return response;
    }

    final payload = {'id': noteId, 'processing_status': status};
    await queueChange('uploaded_notes', 'update', payload, recordId: noteId);
    final existing =
        await cachedRecord('uploaded_notes', noteId) ?? {'id': noteId};
    final optimistic = {...existing, 'processing_status': status};
    await cacheRecord('uploaded_notes', noteId, optimistic);
    return optimistic;
  } catch (error) {
    AppLogger.warning('updateNoteProcessingStatus error', error: error);
    return null;
  }
}

Future<Map<String, dynamic>?> updateUploadedNoteSharing(
  String noteId,
  bool isShared,
) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('uploaded_notes')
          .update({'is_shared_with_group': isShared})
          .eq('id', noteId)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('uploaded_notes', noteId, response);
      }
      return response;
    }

    final payload = {'id': noteId, 'is_shared_with_group': isShared};
    await queueChange('uploaded_notes', 'update', payload, recordId: noteId);
    final existing =
        await cachedRecord('uploaded_notes', noteId) ?? {'id': noteId};
    final optimistic = {...existing, 'is_shared_with_group': isShared};
    await cacheRecord('uploaded_notes', noteId, optimistic);
    return optimistic;
  } catch (error) {
    AppLogger.warning('updateUploadedNoteSharing error', error: error);
    return null;
  }
}

Future<bool?> deleteUploadedNote(String noteId) async {
  try {
    final existing = await cachedRecord('uploaded_notes', noteId);
    final topicId = existing?['topic_id']?.toString();
    if (await isOnline()) {
      await client
          .from('uploaded_notes')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', noteId);
      if (topicId != null && topicId.isNotEmpty) {
        await purgeCachedListItem(
          entity: 'uploaded_notes',
          scope: topicId,
          recordId: noteId,
        );
      }
      await clearCachedList('shared_uploaded_notes', 'all');
      await purgeCachedRecord('uploaded_notes', noteId);
      return true;
    }

    await queueChange('uploaded_notes', 'update', {
      'id': noteId,
      'deleted_at': DateTime.now().toIso8601String(),
    }, recordId: noteId);
    return true;
  } catch (error) {
    AppLogger.warning('deleteUploadedNote error', error: error);
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getNoteChunks(String noteId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('note_chunks')
          .select()
          .eq('note_id', noteId)
          .order('chunk_index');
      final rows = (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      await cacheList('note_chunks', noteId, rows);
      return rows;
    }

    return cachedList('note_chunks', noteId);
  } catch (error) {
    AppLogger.warning('getNoteChunks error', error: error);
    return cachedList('note_chunks', noteId);
  }
}

Future<List<Map<String, dynamic>>?> saveNoteChunks(
  String noteId,
  List<String> chunks,
) async {
  try {
    final payload = chunks
        .asMap()
        .entries
        .map(
          (entry) => {
            'id': newId(),
            'note_id': noteId,
            'chunk_index': entry.key,
            'content': entry.value,
            'created_at': DateTime.now().toIso8601String(),
          },
        )
        .toList();
}
