import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/module_model.dart';
import '../../models/topic_model.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  SupabaseService._internal() {
    _initializeSupabase();
  }

  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  RealtimeChannel? _messagesChannel;

  SupabaseClient get client => Supabase.instance.client;

  void _initializeSupabase() {
    try {
      if (AppConstants.supabaseUrl != 'YOUR_SUPABASE_URL' &&
          AppConstants.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY') {
        Supabase.initialize(
          url: AppConstants.supabaseUrl,
          anonKey: AppConstants.supabaseAnonKey,
        );
      }
    } catch (error) {
      debugPrint('Supabase init error: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
    String course,
    int yearLevel,
    String primeStudyTime,
    int studyHoursPerDay,
    String studyPreference,
  ) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'course': course,
          'year_level': yearLevel,
          'prime_study_time': primeStudyTime,
          'study_hours_per_day': studyHoursPerDay,
          'study_preference': studyPreference,
        },
      );

      final user = response.user;
      if (user != null) {
        await client.from('profiles').upsert({
          'id': user.id,
          'name': name,
          'course': course,
          'year_level': yearLevel,
          'prime_study_time': primeStudyTime,
          'study_hours_per_day': studyHoursPerDay,
          'study_preference': studyPreference,
          'streak_count': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return user;
    } catch (error) {
      debugPrint('signUpWithEmail error: $error');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (error) {
      debugPrint('signInWithEmail error: $error');
      return null;
    }
  }

  Future<bool?> signOut() async {
    try {
      await client.auth.signOut();
      return true;
    } catch (error) {
      debugPrint('signOut error: $error');
      return null;
    }
  }

  User? getCurrentUser() {
    try {
      return client.auth.currentUser;
    } catch (error) {
      debugPrint('getCurrentUser error: $error');
      return null;
    }
  }

  bool isLoggedIn() {
    try {
      return client.auth.currentUser != null;
    } catch (error) {
      debugPrint('isLoggedIn error: $error');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PROFILES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('getProfile error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from('profiles')
          .update({
            ...data,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('updateProfile error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateStreak(String userId) async {
    try {
      final profile = await getProfile(userId);
      if (profile == null) {
        return null;
      }

      final lastStudyDate = profile['last_study_date'];
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final previousDate = lastStudyDate == null
          ? null
          : DateTime.parse(lastStudyDate.toString());

      final yesterday = todayDate.subtract(const Duration(days: 1));
      final isConsecutiveDay = previousDate != null &&
          previousDate.year == yesterday.year &&
          previousDate.month == yesterday.month &&
          previousDate.day == yesterday.day;

      final isSameDay = previousDate != null &&
          previousDate.year == todayDate.year &&
          previousDate.month == todayDate.month &&
          previousDate.day == todayDate.day;

      final currentStreak = (profile['streak_count'] as int?) ?? 0;
      final nextStreak = isSameDay
          ? currentStreak
          : isConsecutiveDay
              ? currentStreak + 1
              : 1;

      return await updateProfile(userId, {
        'streak_count': nextStreak,
        'last_study_date': todayDate.toIso8601String().split('T').first,
      });
    } catch (error) {
      debugPrint('updateStreak error: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // MODULES
  // ---------------------------------------------------------------------------

  Future<List<ModuleModel>?> getModules(String userId) async {
    try {
      final response = await client
          .from('modules')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      return (response as List<dynamic>)
          .map((item) => ModuleModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('getModules error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addModule(
    String userId,
    String name,
    String color,
  ) async {
    try {
      final response = await client
          .from('modules')
          .insert({
            'user_id': userId,
            'name': name,
            'color': color,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('addModule error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateModule(
    String moduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from('modules')
          .update(data)
          .eq('id', moduleId)
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('updateModule error: $error');
      return null;
    }
  }

  Future<bool?> deleteModule(String moduleId) async {
    try {
      await client.from('modules').delete().eq('id', moduleId);
      return true;
    } catch (error) {
      debugPrint('deleteModule error: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // TOPICS
  // ---------------------------------------------------------------------------

  Future<List<TopicModel>?> getTopics(String moduleId) async {
    try {
      final response = await client
          .from('topics')
          .select()
          .eq('module_id', moduleId)
          .order('created_at');
      return (response as List<dynamic>)
          .map((item) => TopicModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('getTopics error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addTopic(
    String moduleId,
    String userId,
    String name,
  ) async {
    try {
      final response = await client
          .from('topics')
          .insert({
            'module_id': moduleId,
            'user_id': userId,
            'name': name,
            'is_studied': false,
            'study_count': 0,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('addTopic error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateTopicRating(
    String topicId,
    int rating,
  ) async {
    try {
      final topicResponse = await client
          .from('topics')
          .select('id, user_id, study_count')
          .eq('id', topicId)
          .maybeSingle();

      if (topicResponse == null) {
        return null;
      }

      final currentStudyCount = (topicResponse['study_count'] as int?) ?? 0;

      await client.from('topic_ratings_history').insert({
        'topic_id': topicId,
        'user_id': topicResponse['user_id'],
        'rating': rating,
        'rated_at': DateTime.now().toIso8601String(),
      });

      final response = await client
          .from('topics')
          .update({
            'current_rating': rating,
            'study_count': currentStudyCount + 1,
            'last_studied_at': DateTime.now().toIso8601String(),
          })
          .eq('id', topicId)
          .select()
          .maybeSingle();

      return response;
    } catch (error) {
      debugPrint('updateTopicRating error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> markTopicStudied(String topicId) async {
    try {
      final topic = await client
          .from('topics')
          .select('study_count')
          .eq('id', topicId)
          .maybeSingle();

      if (topic == null) {
        return null;
      }

      final response = await client
          .from('topics')
          .update({
            'is_studied': true,
            'study_count': ((topic['study_count'] as int?) ?? 0) + 1,
            'last_studied_at': DateTime.now().toIso8601String(),
          })
          .eq('id', topicId)
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('markTopicStudied error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateTopicNotes(
    String topicId,
    String notes,
  ) async {
    try {
      final response = await client
          .from('topics')
          .update({'notes': notes})
          .eq('id', topicId)
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('updateTopicNotes error: $error');
      return null;
    }
  }

  Future<List<TopicModel>?> getTopicsNeedingReview(String userId) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      final response = await client
          .from('topics')
          .select()
          .eq('user_id', userId)
          .lte('next_review_at', nowIso)
          .order('next_review_at');
      return (response as List<dynamic>)
          .map((item) => TopicModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('getTopicsNeedingReview error: $error');
      return null;
    }
  }

  Future<bool?> deleteTopic(String topicId) async {
    try {
      await client.from('topics').delete().eq('id', topicId);
      return true;
    } catch (error) {
      debugPrint('deleteTopic error: $error');
      return null;
    }
  }

  Future<bool?> deleteTopics(String topicId) async {
    return deleteTopic(topicId);
  }

  // ---------------------------------------------------------------------------
  // TIMETABLE
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>?> getClassTimetable(String userId) async {
    try {
      final response = await client
          .from('class_timetable')
          .select()
          .eq('user_id', userId)
          .order('day_of_week')
          .order('start_time');
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getClassTimetable error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addClassSlot(Map<String, dynamic> data) async {
    try {
      final response = await client
          .from('class_timetable')
          .insert({
            ...data,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('addClassSlot error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateClassSlot(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from('class_timetable')
          .update(data)
          .eq('id', id)
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('updateClassSlot error: $error');
      return null;
    }
  }

  Future<bool?> deleteClassSlot(String id) async {
    try {
      await client.from('class_timetable').delete().eq('id', id);
      return true;
    } catch (error) {
      debugPrint('deleteClassSlot error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getStudySessions(
    String userId,
    DateTime date,
  ) async {
    try {
      final day = date.toIso8601String().split('T').first;
      final response = await client
          .from('study_sessions')
          .select()
          .eq('user_id', userId)
          .eq('scheduled_date', day)
          .order('start_time');
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getStudySessions error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addStudySession(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from('study_sessions')
          .insert({
            ...data,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('addStudySession error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateSessionStatus(
    String sessionId,
    String status,
    int? actualDuration,
  ) async {
    try {
      final response = await client
          .from('study_sessions')
          .update({
            'status': status,
            'actual_duration_minutes': actualDuration,
          })
          .eq('id', sessionId)
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('updateSessionStatus error: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // EXAMS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>?> getExams(String userId) async {
    try {
      final response = await client
          .from('exams')
          .select()
          .eq('user_id', userId)
          .order('exam_date');
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getExams error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addExam(Map<String, dynamic> data) async {
    try {
      final response = await client
          .from('exams')
          .insert({
            ...data,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('addExam error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateExam(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from('exams')
          .update(data)
          .eq('id', id)
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('updateExam error: $error');
      return null;
    }
  }

  Future<bool?> deleteExam(String id) async {
    try {
      await client.from('exams').delete().eq('id', id);
      return true;
    } catch (error) {
      debugPrint('deleteExam error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getUpcomingExams(String userId) async {
    try {
      final response = await client
          .from('exams')
          .select()
          .eq('user_id', userId)
          .gte('exam_date', DateTime.now().toIso8601String().split('T').first)
          .order('exam_date');
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getUpcomingExams error: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // STUDY GROUPS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> createGroup(
    String name,
    String description,
    String createdBy,
  ) async {
    try {
      final response = await client
          .from('study_groups')
          .insert({
            'name': name,
            'description': description,
            'created_by': createdBy,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();

      if (response != null) {
        await client.from('group_members').insert({
          'group_id': response['id'],
          'user_id': createdBy,
          'role': 'admin',
          'joined_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } catch (error) {
      debugPrint('createGroup error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinGroup(
    String inviteCode,
    String userId,
  ) async {
    try {
      final group = await client
          .from('study_groups')
          .select()
          .eq('invite_code', inviteCode.toUpperCase())
          .maybeSingle();

      if (group == null) {
        return null;
      }

      final response = await client
          .from('group_members')
          .upsert({
            'group_id': group['id'],
            'user_id': userId,
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('joinGroup error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getMyGroups(String userId) async {
    try {
      final memberships = await client
          .from('group_members')
          .select()
          .eq('user_id', userId)
          .order('joined_at');

      final results = <Map<String, dynamic>>[];

      for (final item in memberships as List<dynamic>) {
        final membership = item as Map<String, dynamic>;
        final group = await client
            .from('study_groups')
            .select()
            .eq('id', membership['group_id'])
            .maybeSingle();

        results.add({
          ...membership,
          'study_groups': group,
        });
      }

      return results;
    } catch (error) {
      debugPrint('getMyGroups error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getGroupMembers(String groupId) async {
    try {
      final response = await client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .order('joined_at');
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getGroupMembers error: $error');
      return null;
    }
  }

  Future<bool?> leaveGroup(String groupId, String userId) async {
    try {
      await client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
      return true;
    } catch (error) {
      debugPrint('leaveGroup error: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // MESSAGES (REALTIME)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>?> getTopicMessages(String topicId) async {
    try {
      final response = await client
          .from('group_messages')
          .select()
          .eq('topic_id', topicId)
          .order('created_at');
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getTopicMessages error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendMessage(Map<String, dynamic> data) async {
    try {
      final response = await client
          .from('group_messages')
          .insert({
            ...data,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('sendMessage error: $error');
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
      debugPrint('subscribeToMessages error: $error');
      return null;
    }
  }

  Future<void> unsubscribeFromMessages() async {
    try {
      if (_messagesChannel != null) {
        await client.removeChannel(_messagesChannel!);
        _messagesChannel = null;
      }
    } catch (error) {
      debugPrint('unsubscribeFromMessages error: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // WEEKLY REPORTS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> saveWeeklyReport(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from('weekly_reports')
          .insert({
            ...data,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('saveWeeklyReport error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getWeeklyReports(
    String userId,
    int limit,
  ) async {
    try {
      final response = await client
          .from('weekly_reports')
          .select()
          .eq('user_id', userId)
          .order('week_start', ascending: false)
          .limit(limit);
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getWeeklyReports error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLastWeekReport(String userId) async {
    try {
      final response = await client
          .from('weekly_reports')
          .select()
          .eq('user_id', userId)
          .order('week_start', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('getLastWeekReport error: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // UPLOADED NOTES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> saveUploadedNote(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await client
          .from('uploaded_notes')
          .insert({
            ...data,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('saveUploadedNote error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getNotesByTopic(String topicId) async {
    try {
      final response = await client
          .from('uploaded_notes')
          .select()
          .eq('topic_id', topicId)
          .order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getNotesByTopic error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateNoteProcessingStatus(
    String noteId,
    String status,
  ) async {
    try {
      final response = await client
          .from('uploaded_notes')
          .update({'processing_status': status})
          .eq('id', noteId)
          .select()
          .maybeSingle();
      return response;
    } catch (error) {
      debugPrint('updateNoteProcessingStatus error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getNoteChunks(String noteId) async {
    try {
      final response = await client
          .from('note_chunks')
          .select()
          .eq('note_id', noteId)
          .order('chunk_index');
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('getNoteChunks error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> saveNoteChunks(
    String noteId,
    List<String> chunks,
  ) async {
    try {
      final payload = chunks.asMap().entries.map((entry) {
        return {
          'note_id': noteId,
          'chunk_index': entry.key,
          'content': entry.value,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      final response = await client
          .from('note_chunks')
          .insert(payload)
          .select();

      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (error) {
      debugPrint('saveNoteChunks error: $error');
      return null;
    }
  }
}
