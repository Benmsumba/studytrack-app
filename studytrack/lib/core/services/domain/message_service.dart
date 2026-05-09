import 'dart:async';
import '../../utils/app_logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/group_member_model.dart';
import '../../../models/group_message_model.dart';
import '../../../models/study_session_model.dart';
import '../../../models/study_group_model.dart';
import '../../constants/app_config.dart';
import '../../utils/helpers.dart';
import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class MessageService extends DomainServiceBase {
  MessageService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;

// MESSAGES (REALTIME)
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>?> getTopicMessages(String topicId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('group_messages')
          .select()
          .eq('topic_id', topicId)
          .order('created_at');
      final rows = (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      await cacheList('topic_messages', topicId, rows);
      return rows;
    }

    return cachedList('topic_messages', topicId);
  } catch (error) {
    AppLogger.warning('getTopicMessages error', error: error);
    return cachedList('topic_messages', topicId);
  }
}

Future<List<Map<String, dynamic>>?> getGroupMessages(
  String groupId, {
  int limit = AppConfig.messagesPaginationSize,
  int offset = 0,
}) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('group_messages')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final rows = (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
      // Only cache the first page (offset 0) — subsequent pages are
      // appended in the UI layer and do not replace the cache.
      if (offset == 0) {
        await cacheList('group_messages', groupId, rows);
      }
      return rows;
    }

    final cached = await cachedList('group_messages', groupId);
    if (cached == null) return null;
    return cached.skip(offset).take(limit).toList();
  } catch (error) {
    AppLogger.warning('getGroupMessages error', error: error);
    final cached = await cachedList('group_messages', groupId);
    if (cached == null) return null;
    return cached.skip(offset).take(limit).toList();
  }
}

Future<Map<String, dynamic>?> sendMessage(Map<String, dynamic> data) async {
  try {
    final id = newId();
    final payload = {
      'id': id,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    };
    final scope =
        data['topic_id']?.toString() ??
        data['group_id']?.toString() ??
        'messages';
    if (await isOnline()) {
      final response = await client
          .from('group_messages')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord(
          'group_messages',
          response['id'].toString(),
          response,
        );
      }
      return response;
    }

    await queueChange('group_messages', 'insert', payload, recordId: id);
    await cacheRecord('group_messages', id, payload);
    final cached = await cachedList('group_messages', scope) ?? [];
    await cacheList('group_messages', scope, [...cached, payload]);
    return payload;
  } catch (error) {
    AppLogger.warning('sendMessage error', error: error);
    return null;
  }
}

Future<RealtimeChannel?> subscribeToMessages(
  String topicId,
  void Function(Map<String, dynamic> message) onMessage,
) async {
  try {
    unsubscribeFromMessages();

    _messagesChannel = client.channel('topic_messages_$topicId');
    _messagesChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'topic_id',
            value: topicId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              onMessage(newRecord);
            }
          },
        )
        .subscribe();

    return _messagesChannel;
  } catch (error) {
    AppLogger.warning('subscribeToMessages error', error: error);
    return null;
  }
}

Future<RealtimeChannel?> subscribeToGroupMessages(
  String groupId,
  void Function(Map<String, dynamic> message) onMessage,
) async {
  try {
    unsubscribeFromMessages();

    _messagesChannel = client.channel('group_messages_$groupId');
    _messagesChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              onMessage(newRecord);
            }
          },
        )
        .subscribe();

    return _messagesChannel;
  } catch (error) {
    AppLogger.warning('subscribeToGroupMessages error', error: error);
    return null;
  }
}

// Repository-compatible wrappers returning strong types -------------------------------------------------
Future<List<StudyGroupModel>?> getStudyGroups() async {
  try {
    final currentUser = getCurrentUser();
    if (currentUser == null) return <StudyGroupModel>[];
    final raw = await getMyGroups(currentUser.id);
    if (raw == null) return null;
    return raw.map((membership) {
      final gm =
          membership['study_groups'] as Map<String, dynamic>? ?? membership;
      return StudyGroupModel.fromJson(gm);
    }).toList();
  } catch (e) {
    AppLogger.warning('getStudyGroups wrapper error', error: e);
    return null;
  }
}

Future<StudyGroupModel?> getStudyGroup(String groupId) async {
  try {
    final response = await client
        .from('study_groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();
    if (response == null) return null;
    return StudyGroupModel.fromJson(response);
  } catch (e) {
    AppLogger.warning('getStudyGroup error', error: e);
    return null;
  }
}

Future<StudyGroupModel?> createStudyGroup({
  required String name,
  required String description,
  String? topicId,
}) async {
  try {
    final currentUser = getCurrentUser();
    final createdBy = currentUser?.id ?? newId();
    final res = await createGroup(name, description, createdBy);
    if (res == null) return null;
    return StudyGroupModel.fromJson(res);
  } catch (e) {
    AppLogger.warning('createStudyGroup wrapper error', error: e);
    return null;
  }
}

Future<StudyGroupModel?> updateStudyGroup(StudyGroupModel group) async {
  try {
    final response = await client
        .from('study_groups')
        .update(group.toJson())
        .eq('id', group.id)
        .select()
        .maybeSingle();
    if (response == null) return null;
    return StudyGroupModel.fromJson(response);
  } catch (e) {
    AppLogger.warning('updateStudyGroup error', error: e);
    return null;
  }
}

Future<bool?> deleteStudyGroup(String groupId) async {
  try {
    final resp = await client.from('study_groups').delete().eq('id', groupId);
    return resp != null;
  } catch (e) {
    AppLogger.warning('deleteStudyGroup error', error: e);
    return null;
  }
}

Future<bool?> joinGroupByCode(String inviteCode) async {
  try {
    final currentUser = getCurrentUser();
    if (currentUser == null) return null;
    await joinGroup(inviteCode, currentUser.id);
    return true;
  } catch (e) {
    AppLogger.warning('joinGroupByCode error', error: e);
    return null;
  }
}

Future<bool?> leaveStudyGroup(String groupId) async {
  try {
    final currentUser = getCurrentUser();
    if (currentUser == null) return null;
    await leaveGroup(groupId, currentUser.id);
    return true;
  } catch (e) {
    AppLogger.warning('leaveStudyGroup error', error: e);
    return null;
  }
}

Future<List<GroupMemberModel>?> getGroupMembersTyped(String groupId) async {
  try {
    final rows = await getGroupMembers(groupId);
    if (rows == null) return null;
    return rows.map(GroupMemberModel.fromJson).toList();
  } catch (e) {
    AppLogger.warning('getGroupMembersTyped error', error: e);
    return null;
  }
}

Future<List<GroupMessageModel>?> getGroupMessagesTyped(
  String groupId, {
  int limit = AppConfig.messagesPaginationSize,
  int offset = 0,
}) async {
  try {
    final rows = await getGroupMessages(groupId, limit: limit, offset: offset);
    if (rows == null) return null;
    return rows.map(GroupMessageModel.fromJson).toList();
  } catch (e) {
    AppLogger.warning('getGroupMessagesTyped error', error: e);
    return null;
  }
}

Future<GroupMessageModel?> sendGroupMessage({
  required String groupId,
  required String content,
  String? topicId,
}) async {
  try {
    final payload = {
      'group_id': groupId,
      'content': content,
      'topic_id': topicId,
    };
    final resp = await sendMessage(payload);
    if (resp == null) return null;
    return GroupMessageModel.fromJson(resp);
  } catch (e) {
    AppLogger.warning('sendGroupMessage wrapper error', error: e);
    return null;
  }
}

Stream<List<GroupMessageModel>> subscribeToGroupMessagesStream(
  String groupId,
) {
  final controller = StreamController<List<GroupMessageModel>>.broadcast();
  // Emit initial snapshot
  getGroupMessagesTyped(groupId).then((initial) {
    controller.add(initial ?? []);
  });

  // Subscribe to realtime and push updates
  subscribeToGroupMessages(groupId, (message) async {
    final latest = await getGroupMessagesTyped(groupId) ?? [];
    if (!controller.isClosed) controller.add(latest);
  });

  controller.onCancel = () async {
    await unsubscribeFromMessages();
    if (!controller.isClosed) await controller.close();
  };

  return controller.stream;
}

Future<void> inviteUserToGroup({
  required String groupId,
  required String userEmail,
}) async {
  try {
    await client.from('group_invitations').insert({
      'id': newId(),
      'group_id': groupId,
      'email': userEmail,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    AppLogger.warning('inviteUserToGroup error', error: e);
  }
}

Future<void> removeGroupMemberWrapper({
  required String groupId,
  required String userId,
}) async {
  await removeGroupMember(groupId, userId);
}

Future<void> unsubscribeFromMessages() async {
  try {
    if (_messagesChannel != null) {
      await client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
  } catch (error) {
    AppLogger.warning('unsubscribeFromMessages error', error: error);
  }
}

Future<List<StudySessionModel>> getSessions() async {
  final currentUser = getCurrentUser();
  if (currentUser == null) return const [];
  final response = await client
      .from('study_sessions')
      .select()
      .eq('user_id', currentUser.id)
      .order('scheduled_date', ascending: false);
  return (response as List<dynamic>)
      .map((item) => StudySessionModel.fromJson(item as Map<String, dynamic>))
      .toList();
}

Future<List<StudySessionModel>> getSessionsByDateRange({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final currentUser = getCurrentUser();
  if (currentUser == null) return const [];
  final response = await client
      .from('study_sessions')
      .select()
      .eq('user_id', currentUser.id)
      .gte('scheduled_date', startDate.toIso8601String().split('T').first)
      .lte('scheduled_date', endDate.toIso8601String().split('T').first)
      .order('scheduled_date', ascending: false);
  return (response as List<dynamic>)
      .map((item) => StudySessionModel.fromJson(item as Map<String, dynamic>))
      .toList();
}

Future<List<StudySessionModel>> getSessionsByTopic(String topicId) async {
  final response = await client
      .from('study_sessions')
      .select()
      .eq('topic_id', topicId)
      .order('scheduled_date', ascending: false);
  return (response as List<dynamic>)
      .map((item) => StudySessionModel.fromJson(item as Map<String, dynamic>))
      .toList();
}

Future<StudySessionModel> createSession({
  required String topicId,
  required int duration,
  required String focusArea,
  String? notes,
}) async {
  final currentUser = getCurrentUser();
  if (currentUser == null) {
    throw StateError('No authenticated user available');
  }

  final response = await client
      .from('study_sessions')
      .insert({
        'user_id': currentUser.id,
        'topic_id': topicId,
        'title': focusArea,
        'scheduled_date': DateTime.now().toIso8601String().split('T').first,
        'duration_minutes': duration,
        'notes': notes,
        'status': 'planned',
        'created_at': DateTime.now().toIso8601String(),
      })
      .select()
      .maybeSingle();

  if (response == null) {
    throw StateError('Failed to create study session');
  }
  return StudySessionModel.fromJson(response);
}

Future<StudySessionModel> updateSession(StudySessionModel session) async {
  final response = await client
      .from('study_sessions')
      .update(session.toJson())
      .eq('id', session.id)
      .select()
      .maybeSingle();
  if (response == null) {
    throw StateError('Failed to update study session');
  }
  return StudySessionModel.fromJson(response);
}

Future<void> deleteSession(String sessionId) async {
  await client
      .from('study_sessions')
      .update({'deleted_at': DateTime.now().toIso8601String()})
      .eq('id', sessionId);
}

Future<StudySessionModel> endSession(String sessionId) async {
  final response = await client
      .from('study_sessions')
      .update({'status': 'completed'})
      .eq('id', sessionId)
      .select()
      .maybeSingle();
  if (response == null) {
    throw StateError('Failed to end study session');
  }
  return StudySessionModel.fromJson(response);
}

Future<Duration> getTotalStudyTime() async {
  final currentUser = getCurrentUser();
  if (currentUser == null) return Duration.zero;
  final response = await client
      .from('study_sessions')
      .select('duration_minutes, actual_duration_minutes')
      .eq('user_id', currentUser.id);
  final rows = response as List<dynamic>;
  final totalMinutes = rows.fold<int>(0, (sum, item) {
    final session = item as Map<String, dynamic>;
    return sum +
        ((session['actual_duration_minutes'] as int?) ??
            (session['duration_minutes'] as int?) ??
            0);
  });
  return Duration(minutes: totalMinutes);
}

Future<int> getDailyStreak() async {
  final currentUser = getCurrentUser();
  if (currentUser == null) return 0;
  final response = await client
      .from('study_sessions')
      .select('scheduled_date')
      .eq('user_id', currentUser.id)
      .order('scheduled_date', ascending: false);
  final distinctDays =
      (response as List<dynamic>)
          .map(
            (item) => DateTime.parse(
              (item as Map<String, dynamic>)['scheduled_date'] as String,
            ),
          )
          .map((date) => DateTime(date.year, date.month, date.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

  var streak = 0;
  var cursor = DateTime.now();
  for (final day in distinctDays) {
    final expected = DateTime(cursor.year, cursor.month, cursor.day);
    if (day == expected) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else if (day.isBefore(expected)) {
      break;
    }
  }
  return streak;
}

Future<List<StudySessionModel>> getSessionsToday() async {
  final currentUser = getCurrentUser();
  if (currentUser == null) return const [];
  final today = DateTime.now().toIso8601String().split('T').first;
  final response = await client
      .from('study_sessions')
      .select()
      .eq('user_id', currentUser.id)
      .eq('scheduled_date', today)
      .order('scheduled_date', ascending: false);
  return (response as List<dynamic>)
      .map((item) => StudySessionModel.fromJson(item as Map<String, dynamic>))
      .toList();
}

Future<Duration> getAverageSessionDuration() async {
  final currentUser = getCurrentUser();
  if (currentUser == null) return Duration.zero;
  final response = await client
      .from('study_sessions')
      .select('duration_minutes, actual_duration_minutes')
      .eq('user_id', currentUser.id);
  final rows = response as List<dynamic>;
  if (rows.isEmpty) return Duration.zero;
  final totalMinutes = rows.fold<int>(0, (sum, item) {
    final session = item as Map<String, dynamic>;
    return sum +
        ((session['actual_duration_minutes'] as int?) ??
            (session['duration_minutes'] as int?) ??
            0);
  });
  return Duration(minutes: totalMinutes ~/ rows.length);
}

Future<TopicModel?> getTopic(String topicId) async => getTopicById(topicId);

Future<TopicModel> createTopic({
  required String moduleId,
  required String name,
  required String description,
}) async {
  final currentUser = getCurrentUser();
  if (currentUser == null) {
    throw StateError('No authenticated user available');
  }
  final response = await client
      .from('topics')
      .insert({
        'module_id': moduleId,
        'user_id': currentUser.id,
        'name': name,
        'description': description,
        'is_studied': false,
        'study_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      })
      .select()
      .maybeSingle();
  if (response == null) {
    throw StateError('Failed to create topic');
  }
  return TopicModel.fromJson(response);
}

Future<TopicModel> updateTopic(TopicModel topic) async {
  final response = await client
      .from('topics')
      .update(topic.toJson())
      .eq('id', topic.id)
      .select()
      .maybeSingle();
  if (response == null) {
    throw StateError('Failed to update topic');
  }
  return TopicModel.fromJson(response);
}

Future<void> rateTopic(String topicId, int rating) async {
  await updateTopicRating(topicId, rating);
}

Future<List<TopicModel>> getRatedTopics({
  required int minRating,
  int? maxRating,
}) async {
  final currentUser = getCurrentUser();
  if (currentUser == null) return const [];
  var query = client
      .from('topics')
      .select()
      .eq('user_id', currentUser.id)
      .gte('current_rating', minRating);
  if (maxRating != null) {
    query = query.lte('current_rating', maxRating);
  }
  final response = await query;
  return (response as List<dynamic>)
      .map((item) => TopicModel.fromJson(item as Map<String, dynamic>))
      .toList();
}

Future<List<TopicModel>> getTopicsDueForReview() async {
  final currentUser = getCurrentUser();
  if (currentUser == null) return const [];
  final topics = await getTopicsNeedingReview(currentUser.id);
  return topics ?? const [];
}

Future<void> markTopicAsReviewed(String topicId) async {
  await client
      .from('topics')
      .update({'last_studied_at': DateTime.now().toIso8601String()})
      .eq('id', topicId);
}
}
