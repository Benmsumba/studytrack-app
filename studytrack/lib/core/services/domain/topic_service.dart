import 'dart:async';
import '../../utils/app_logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';
import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class TopicService extends DomainServiceBase {
  TopicService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;

// ---------------------------------------------------------------------------
// TOPICS
// ---------------------------------------------------------------------------

Future<List<TopicModel>?> getTopics(String moduleId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('topics')
          .select()
          .eq('module_id', moduleId)
          .isFilter('deleted_at', null)
          .order('created_at');
      final rows = activeRows(response as List<dynamic>);
      await cacheList('topics', moduleId, rows);
      return rows.map(TopicModel.fromJson).toList();
    }

    final cached = await cachedList('topics', moduleId);
    return activeRows(
      cached ?? const [],
    ).map(TopicModel.fromJson).toList(growable: false);
  } on Object catch (error) {
    AppLogger.warning('getTopics error', error: error);
    final cached = await cachedList('topics', moduleId);
    return activeRows(
      cached ?? const [],
    ).map(TopicModel.fromJson).toList(growable: false);
  }
}

/// Fetch all topics for multiple modules in a single query.
/// Returns a flat list — callers group by [TopicModel.moduleId].
Future<List<TopicModel>> getTopicsByModuleIds(List<String> moduleIds) async {
  if (moduleIds.isEmpty) return const [];
  try {
    if (await isOnline()) {
      final response = await client
          .from('topics')
          .select()
          .inFilter('module_id', moduleIds)
          .order('created_at');
      final rows = (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      final activeRows = activeRows(rows);
      // Group by module then cache each bucket — keeps per-module cache keys
      // consistent with getTopics() so offline reads find them correctly.
      final rowsByModule = <String, List<Map<String, dynamic>>>{};
      for (final row in activeRows) {
        final moduleId = row['module_id']?.toString() ?? '';
        rowsByModule.putIfAbsent(moduleId, () => []).add(row);
      }
      for (final entry in rowsByModule.entries) {
        await cacheList('topics', entry.key, entry.value);
      }
      return activeRows.map(TopicModel.fromJson).toList();
    }

    // Offline: aggregate from per-module caches.
    final all = <TopicModel>[];
    for (final moduleId in moduleIds) {
      final cached = await cachedList('topics', moduleId);
      if (cached != null) all.addAll(cached.map(TopicModel.fromJson));
    }
    return all;
  } on Object catch (error) {
    AppLogger.warning('getTopicsByModuleIds error', error: error);
    final all = <TopicModel>[];
    for (final moduleId in moduleIds) {
      final cached = await cachedList('topics', moduleId);
      if (cached != null) all.addAll(cached.map(TopicModel.fromJson));
    }
    return all;
  }
}

Future<TopicModel?> getTopicById(String topicId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('topics')
          .select()
          .eq('id', topicId)
          .maybeSingle();

      if (response == null || response['deleted_at'] != null) {
        return null;
      }

      await cacheRecord('topics', topicId, response);
      return TopicModel.fromJson(response);
    }

    final cached = await cachedRecord('topics', topicId);
    return activeRow(cached) == null ? null : TopicModel.fromJson(cached!);
  } on Object catch (error) {
    AppLogger.warning('getTopicById error', error: error);
    final cached = await cachedRecord('topics', topicId);
    return activeRow(cached) == null ? null : TopicModel.fromJson(cached!);
  }
}

Future<List<Map<String, dynamic>>?> getTopicRatingHistory(
  String topicId, {
  int limit = 5,
}) async {
  try {
    final queryKey = 'topic_ratings_history:$topicId:$limit';
    if (await isOnline()) {
      final response = await client
          .from('topic_ratings_history')
          .select()
          .eq('topic_id', topicId)
          .order('rated_at', ascending: false)
          .limit(limit);

      final values = (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      await cacheList('topic_ratings_history', queryKey, values);
      return values.reversed.toList();
    }

    final cached = await cachedList('topic_ratings_history', queryKey);
    return cached?.reversed.toList();
  } catch (error) {
    AppLogger.warning('getTopicRatingHistory error', error: error);
    final queryKey = 'topic_ratings_history:$topicId:$limit';
    final cached = await cachedList('topic_ratings_history', queryKey);
    return cached?.reversed.toList();
  }
}

Future<Map<String, dynamic>?> addTopic(
  String moduleId,
  String userId,
  String name,
) async {
  try {
    final topicId = newId();
    final payload = {
      'id': topicId,
      'module_id': moduleId,
      'user_id': userId,
      'name': name,
      'is_studied': false,
      'study_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (await isOnline()) {
      final response = await client
          .from('topics')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('topics', response['id'].toString(), response);
      }
      return response;
    }

    await queueChange('topics', 'insert', payload, recordId: topicId);
    await cacheRecord('topics', topicId, payload);
    return payload;
  } catch (error) {
    AppLogger.warning('addTopic error', error: error);
    return null;
  }
}

Future<Map<String, dynamic>?> updateTopicRating(
  String topicId,
  int rating,
) async {
  try {
    final topicResponse = await getTopicById(topicId);
    if (topicResponse == null) {
      return null;
    }

    final currentStudyCount = topicResponse.studyCount;
    final nowIso = DateTime.now().toIso8601String();
    final historyPayload = {
      'id': newId(),
      'topic_id': topicId,
      'user_id': topicResponse.userId,
      'rating': rating,
      'rated_at': nowIso,
    };
    final topicPayload = {
      'id': topicId,
      'current_rating': rating,
      'study_count': currentStudyCount + 1,
      'last_studied_at': nowIso,
    };

    if (await isOnline()) {
      await client.from('topic_ratings_history').insert(historyPayload);
      final response = await client
          .from('topics')
          .update({
            'current_rating': rating,
            'study_count': currentStudyCount + 1,
            'last_studied_at': nowIso,
          })
          .eq('id', topicId)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('topics', topicId, response);
      }
      return response;
    }

    await queueChange(
      'topic_ratings_history',
      'insert',
      historyPayload,
      recordId: historyPayload['id']?.toString(),
    );
    await queueChange('topics', 'update', topicPayload, recordId: topicId);
    final optimistic = {...topicResponse.toJson(), ...topicPayload};
    await cacheRecord('topics', topicId, optimistic);
    return optimistic;
  } catch (error) {
    AppLogger.warning('updateTopicRating error', error: error);
    return null;
  }
}

Future<Map<String, dynamic>?> markTopicStudied(String topicId) async {
  try {
    final topic = await getTopicById(topicId);
    if (topic == null) {
      return null;
    }

    final payload = {
      'id': topicId,
      'is_studied': true,
      'study_count': topic.studyCount + 1,
      'last_studied_at': DateTime.now().toIso8601String(),
    };

    if (await isOnline()) {
      final response = await client
          .from('topics')
          .update({
            'is_studied': true,
            'study_count': topic.studyCount + 1,
            'last_studied_at': DateTime.now().toIso8601String(),
          })
          .eq('id', topicId)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('topics', topicId, response);
      }
      return response;
    }

    await queueChange('topics', 'update', payload, recordId: topicId);
    final optimistic = {...topic.toJson(), ...payload};
    await cacheRecord('topics', topicId, optimistic);
    return optimistic;
  } catch (error) {
    AppLogger.warning('markTopicStudied error', error: error);
    return null;
  }
}

Future<Map<String, dynamic>?> updateTopicNotes(
  String topicId,
  String notes,
) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('topics')
          .update({'notes': notes})
          .eq('id', topicId)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('topics', topicId, response);
      }
      return response;
    }

    await queueChange('topics', 'update', {
      'id': topicId,
      'notes': notes,
    }, recordId: topicId);
    final topic = await getTopicById(topicId);
    final optimistic = topic == null
        ? {'id': topicId, 'notes': notes}
        : {...topic.toJson(), 'notes': notes};
    await cacheRecord('topics', topicId, optimistic);
    return optimistic;
  } catch (error) {
    AppLogger.warning('updateTopicNotes error', error: error);
    return null;
  }
}

Future<List<TopicModel>?> getTopicsNeedingReview(String userId) async {
  try {
    final queryKey = 'topics_needing_review:$userId';
    if (await isOnline()) {
      final nowIso = DateTime.now().toIso8601String();
      final response = await client
          .from('topics')
          .select()
          .eq('user_id', userId)
          .lte('next_review_at', nowIso)
          .order('next_review_at');
      final rows = activeRows(response as List<dynamic>);
      await cacheList('topics_needing_review', queryKey, rows);
      return rows.map(TopicModel.fromJson).toList();
    }

    final cached = await cachedList('topics_needing_review', queryKey);
    return activeRows(
      cached ?? const [],
    ).map(TopicModel.fromJson).toList(growable: false);
  } catch (error) {
    AppLogger.warning('getTopicsNeedingReview error', error: error);
    final queryKey = 'topics_needing_review:$userId';
    final cached = await cachedList('topics_needing_review', queryKey);
    return activeRows(
      cached ?? const [],
    ).map(TopicModel.fromJson).toList(growable: false);
  }
}

Future<bool?> deleteTopic(String topicId) async {
  try {
    if (await isOnline()) {
      final topic = await client
          .from('topics')
          .select('id,module_id,user_id')
          .eq('id', topicId)
          .maybeSingle();
      await client
          .from('topics')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', topicId);
      if (topic != null) {
        final moduleId = topic['module_id']?.toString();
        if (moduleId != null && moduleId.isNotEmpty) {
          await clearCachedList('topics', moduleId);
        }
        final userId = topic['user_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          await purgeCachedListItem(
            entity: 'topics_needing_review',
            scope: userId,
            recordId: topicId,
          );
        }
      }
      await purgeCachedRecord('topics', topicId);
      return true;
    }

    await queueChange('topics', 'update', {
      'id': topicId,
      'deleted_at': DateTime.now().toIso8601String(),
    }, recordId: topicId);
    return true;
  } catch (error) {
    AppLogger.warning('deleteTopic error', error: error);
    return null;
  }
}
}
