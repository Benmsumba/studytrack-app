import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/module_model.dart';
import '../../models/topic_model.dart';
import 'offline_sync_service.dart';

class SupabaseService {
  SupabaseService._internal();

  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  RealtimeChannel? _messagesChannel;
  String? _lastAuthError;
  final OfflineSyncService _offlineSync = OfflineSyncService.instance;
  final Uuid _uuid = const Uuid();

  SupabaseClient get client => Supabase.instance.client;
  String? get lastAuthError => _lastAuthError;

  Future<bool> _isOnline() async => _offlineSync.onlineNow;

  String _queryKey(String entity, String scope) => '$entity::$scope';

  Future<List<Map<String, dynamic>>?> _cachedList(String entity, String scope) {
    return _offlineSync.cachedQuery(_queryKey(entity, scope));
  }

  Future<void> _cacheList(
    String entity,
    String scope,
    List<Map<String, dynamic>> items,
  ) async {
    await _offlineSync.cacheQuery(
      queryKey: _queryKey(entity, scope),
      entity: entity,
      payload: items,
    );
  }

  Future<Map<String, dynamic>?> _cachedRecord(String entity, String recordId) {
    return _offlineSync.cachedRecord(entity: entity, recordId: recordId);
  }

  Future<void> _cacheRecord(
    String entity,
    String recordId,
    Map<String, dynamic> payload,
  ) async {
    await _offlineSync.cacheRecord(
      entity: entity,
      recordId: recordId,
      payload: payload,
    );
  }

  Future<void> _queueChange(
    String entity,
    String operation,
    Map<String, dynamic> payload, {
    String? recordId,
  }) async {
    await _offlineSync.queueChange(
      entity: entity,
      operation: operation,
      payload: payload,
      recordId: recordId,
    );
  }

  String _newId() => _uuid.v4();

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
    _lastAuthError = null;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: _buildEmailRedirectTo(),
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
        final session = response.session;
        if (user == null) {
          _lastAuthError = 'Unable to create account. Please try again.';
          return null;
        }

        // Only write profile when there is an authenticated session.
        // When email confirmation is required, no session is issued yet and RLS
        // would block direct profile writes from the client.
        if (session != null) {
          try {
            await _upsertProfile(
              userId: user.id,
              data: {
                'name': name,
                'course': course,
                'year_level': yearLevel,
                'prime_study_time': primeStudyTime,
                'study_hours_per_day': studyHoursPerDay,
                'study_preference': studyPreference,
              },
            );
          } catch (error) {
            // Account creation already succeeded in Auth. A profile can be
            // created/updated later during onboarding or on next login.
            debugPrint('signUpWithEmail profile upsert error: $error');
          }
        }

        return user;
      } catch (error) {
        final errorMessage = error.toString();
        if (_isRetryableAuthErrorMessage(errorMessage) && attempt < 2) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        _lastAuthError = _mapAuthErrorText(errorMessage);
        debugPrint('signUpWithEmail auth error: $errorMessage');
        return null;
      }
    }

    _lastAuthError = 'Unable to create account. Please try again.';
    return null;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    _lastAuthError = null;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user != null) {
          await _ensureProfileExists(response.user!);
        }

        return response.user;
      } catch (error) {
        final errorMessage = error.toString();
        if (_isRetryableAuthErrorMessage(errorMessage) && attempt < 2) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        _lastAuthError = _mapAuthErrorText(errorMessage);
        debugPrint('signInWithEmail auth error: $errorMessage');
        return null;
      }
    }

    _lastAuthError = 'Unable to login. Please try again.';
    return null;
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

  Future<bool> resetPasswordForEmail(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email.trim());
      return true;
    } catch (error) {
      debugPrint('resetPasswordForEmail error: $error');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _lastAuthError = null;
    try {
      final launched = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.studytrack.app://callback',
      );
      if (!launched) {
        _lastAuthError = 'Could not open Google sign-in. Please try again.';
      }
      return launched;
    } catch (error) {
      _lastAuthError = _mapAuthErrorText(error.toString());
      debugPrint('signInWithGoogle error: $error');
      return false;
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
      if (await _isOnline()) {
        final response = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('profiles', userId, response);
        }
        return response;
      }

      return await _cachedRecord('profiles', userId);
    } catch (error) {
      debugPrint('getProfile error: $error');
      return _cachedRecord('profiles', userId);
    }
  }

  Future<Map<String, dynamic>?> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final payload = {'id': userId, ...data};
      if (await _isOnline()) {
        final response = await _upsertProfile(userId: userId, data: data);
        if (response != null) {
          await _cacheRecord('profiles', userId, response);
        }
        return response;
      }

      await _queueChange('profiles', 'upsert', payload, recordId: userId);
      final existing =
          await _cachedRecord('profiles', userId) ?? {'id': userId};
      final optimistic = {...existing, ...data, 'id': userId};
      await _cacheRecord('profiles', userId, optimistic);
      return optimistic;
    } catch (error) {
      debugPrint('updateProfile error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _upsertProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    return await client
        .from('profiles')
        .upsert({
          'id': userId,
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id')
        .select()
        .maybeSingle();
  }

  Future<void> _ensureProfileExists(User user) async {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final name = (metadata['name'] as String?)?.trim();

    try {
      await _upsertProfile(
        userId: user.id,
        data: {
          if (name != null && name.isNotEmpty) 'name': name,
          'streak_count': 0,
        },
      );
    } catch (error) {
      // Non-fatal: user can still proceed and retry profile updates later.
      debugPrint('ensureProfileExists error: $error');
    }
  }

  String _mapAuthErrorText(String message) {
    final lowerMessage = message.toLowerCase();

    if (_isRetryableAuthErrorMessage(message)) {
      return 'Network timeout from auth server. Please retry in a few seconds.';
    }

    if (lowerMessage.contains('over_email_send_rate_limit')) {
      return 'Email rate limit exceeded. Wait a moment before trying again.';
    }

    if (lowerMessage.contains('unexpected_failure')) {
      if (lowerMessage.contains('email') ||
          lowerMessage.contains('verification')) {
        return 'Email verification service is temporarily unavailable. Please try again in a minute.';
      }
      return 'Auth service is temporarily unavailable. Please retry shortly.';
    }

    if (lowerMessage.contains('user already exists') ||
        lowerMessage.contains('email_address_already_in_use')) {
      return 'This email is already registered. Try logging in.';
    }

    if (lowerMessage.contains('invalid_credentials')) {
      return 'Invalid email or password.';
    }

    return message.isNotEmpty
        ? message
        : 'Authentication failed. Please try again.';
  }

  bool _isRetryableAuthErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('upstream request timeout') ||
        lowerMessage.contains('statuscode: 504') ||
        lowerMessage.contains('statuscode: 503') ||
        lowerMessage.contains('statuscode: 502') ||
        lowerMessage.contains('gateway timeout') ||
        lowerMessage.contains('unexpected_failure') ||
        lowerMessage.contains('authretryablefetchexception') ||
        lowerMessage.contains('socketexception') ||
        lowerMessage.contains('timeout');
  }

  String? _buildEmailRedirectTo() {
    if (!kIsWeb) {
      return null;
    }

    final origin = Uri.base.origin;
    if (origin.isEmpty) {
      return null;
    }

    return '$origin/#/login';
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
      final isConsecutiveDay =
          previousDate != null &&
          previousDate.year == yesterday.year &&
          previousDate.month == yesterday.month &&
          previousDate.day == yesterday.day;

      final isSameDay =
          previousDate != null &&
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
      if (await _isOnline()) {
        final response = await client
            .from('modules')
            .select()
            .eq('user_id', userId)
            .order('created_at');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('modules', userId, rows);
        return rows.map(ModuleModel.fromJson).toList();
      }

      final cached = await _cachedList('modules', userId);
      return cached?.map(ModuleModel.fromJson).toList();
    } catch (error) {
      debugPrint('getModules error: $error');
      final cached = await _cachedList('modules', userId);
      return cached?.map(ModuleModel.fromJson).toList();
    }
  }

  Future<ModuleModel?> getModuleById(String moduleId) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('modules')
            .select()
            .eq('id', moduleId)
            .maybeSingle();

        if (response == null) {
          return null;
        }

        await _cacheRecord('modules', moduleId, response);
        return ModuleModel.fromJson(response);
      }

      final cached = await _cachedRecord('modules', moduleId);
      return cached == null ? null : ModuleModel.fromJson(cached);
    } catch (error) {
      debugPrint('getModuleById error: $error');
      final cached = await _cachedRecord('modules', moduleId);
      return cached == null ? null : ModuleModel.fromJson(cached);
    }
  }

  Future<Map<String, dynamic>?> addModule(
    String userId,
    String name,
    String color,
  ) async {
    try {
      final moduleId = _newId();
      final payload = {
        'id': moduleId,
        'user_id': userId,
        'name': name,
        'color': color,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (await _isOnline()) {
        final response = await client
            .from('modules')
            .insert(payload)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('modules', response['id'].toString(), response);
        }
        return response;
      }

      await _queueChange('modules', 'insert', payload, recordId: moduleId);
      await _cacheRecord('modules', moduleId, payload);
      return payload;
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
      if (await _isOnline()) {
        final response = await client
            .from('modules')
            .update(data)
            .eq('id', moduleId)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('modules', moduleId, response);
        }
        return response;
      }

      final payload = {'id': moduleId, ...data};
      await _queueChange('modules', 'update', payload, recordId: moduleId);
      final existing =
          await _cachedRecord('modules', moduleId) ?? {'id': moduleId};
      final optimistic = {...existing, ...data, 'id': moduleId};
      await _cacheRecord('modules', moduleId, optimistic);
      return optimistic;
    } catch (error) {
      debugPrint('updateModule error: $error');
      return null;
    }
  }

  Future<bool?> deleteModule(String moduleId) async {
    try {
      if (await _isOnline()) {
        await client.from('modules').delete().eq('id', moduleId);
        await _offlineSync.deleteCachedRecord(
          entity: 'modules',
          recordId: moduleId,
        );
        return true;
      }

      await _queueChange('modules', 'delete', {
        'id': moduleId,
      }, recordId: moduleId);
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
      if (await _isOnline()) {
        final response = await client
            .from('topics')
            .select()
            .eq('module_id', moduleId)
            .order('created_at');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('topics', moduleId, rows);
        return rows.map(TopicModel.fromJson).toList();
      }

      final cached = await _cachedList('topics', moduleId);
      return cached?.map(TopicModel.fromJson).toList();
    } catch (error) {
      debugPrint('getTopics error: $error');
      final cached = await _cachedList('topics', moduleId);
      return cached?.map(TopicModel.fromJson).toList();
    }
  }

  Future<TopicModel?> getTopicById(String topicId) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('topics')
            .select()
            .eq('id', topicId)
            .maybeSingle();

        if (response == null) {
          return null;
        }

        await _cacheRecord('topics', topicId, response);
        return TopicModel.fromJson(response);
      }

      final cached = await _cachedRecord('topics', topicId);
      return cached == null ? null : TopicModel.fromJson(cached);
    } catch (error) {
      debugPrint('getTopicById error: $error');
      final cached = await _cachedRecord('topics', topicId);
      return cached == null ? null : TopicModel.fromJson(cached);
    }
  }

  Future<List<Map<String, dynamic>>?> getTopicRatingHistory(
    String topicId, {
    int limit = 5,
  }) async {
    try {
      final queryKey = 'topic_ratings_history:$topicId:$limit';
      if (await _isOnline()) {
        final response = await client
            .from('topic_ratings_history')
            .select()
            .eq('topic_id', topicId)
            .order('rated_at', ascending: false)
            .limit(limit);

        final values = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('topic_ratings_history', queryKey, values);
        return values.reversed.toList();
      }

      final cached = await _cachedList('topic_ratings_history', queryKey);
      return cached?.reversed.toList();
    } catch (error) {
      debugPrint('getTopicRatingHistory error: $error');
      final queryKey = 'topic_ratings_history:$topicId:$limit';
      final cached = await _cachedList('topic_ratings_history', queryKey);
      return cached?.reversed.toList();
    }
  }

  Future<Map<String, dynamic>?> addTopic(
    String moduleId,
    String userId,
    String name,
  ) async {
    try {
      final topicId = _newId();
      final payload = {
        'id': topicId,
        'module_id': moduleId,
        'user_id': userId,
        'name': name,
        'is_studied': false,
        'study_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (await _isOnline()) {
        final response = await client
            .from('topics')
            .insert(payload)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('topics', response['id'].toString(), response);
        }
        return response;
      }

      await _queueChange('topics', 'insert', payload, recordId: topicId);
      await _cacheRecord('topics', topicId, payload);
      return payload;
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
      final topicResponse = await getTopicById(topicId);
      if (topicResponse == null) {
        return null;
      }

      final currentStudyCount = topicResponse.studyCount;
      final nowIso = DateTime.now().toIso8601String();
      final historyPayload = {
        'id': _newId(),
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

      if (await _isOnline()) {
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
          await _cacheRecord('topics', topicId, response);
        }
        return response;
      }

      await _queueChange(
        'topic_ratings_history',
        'insert',
        historyPayload,
        recordId: historyPayload['id']?.toString(),
      );
      await _queueChange('topics', 'update', topicPayload, recordId: topicId);
      final optimistic = {...topicResponse.toJson(), ...topicPayload};
      await _cacheRecord('topics', topicId, optimistic);
      return optimistic;
    } catch (error) {
      debugPrint('updateTopicRating error: $error');
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

      if (await _isOnline()) {
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
          await _cacheRecord('topics', topicId, response);
        }
        return response;
      }

      await _queueChange('topics', 'update', payload, recordId: topicId);
      final optimistic = {...topic.toJson(), ...payload};
      await _cacheRecord('topics', topicId, optimistic);
      return optimistic;
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
      if (await _isOnline()) {
        final response = await client
            .from('topics')
            .update({'notes': notes})
            .eq('id', topicId)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('topics', topicId, response);
        }
        return response;
      }

      await _queueChange('topics', 'update', {
        'id': topicId,
        'notes': notes,
      }, recordId: topicId);
      final topic = await getTopicById(topicId);
      final optimistic = topic == null
          ? {'id': topicId, 'notes': notes}
          : {...topic.toJson(), 'notes': notes};
      await _cacheRecord('topics', topicId, optimistic);
      return optimistic;
    } catch (error) {
      debugPrint('updateTopicNotes error: $error');
      return null;
    }
  }

  Future<List<TopicModel>?> getTopicsNeedingReview(String userId) async {
    try {
      final queryKey = 'topics_needing_review:$userId';
      if (await _isOnline()) {
        final nowIso = DateTime.now().toIso8601String();
        final response = await client
            .from('topics')
            .select()
            .eq('user_id', userId)
            .lte('next_review_at', nowIso)
            .order('next_review_at');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('topics_needing_review', queryKey, rows);
        return rows.map(TopicModel.fromJson).toList();
      }

      final cached = await _cachedList('topics_needing_review', queryKey);
      return cached?.map(TopicModel.fromJson).toList();
    } catch (error) {
      debugPrint('getTopicsNeedingReview error: $error');
      final queryKey = 'topics_needing_review:$userId';
      final cached = await _cachedList('topics_needing_review', queryKey);
      return cached?.map(TopicModel.fromJson).toList();
    }
  }

  Future<bool?> deleteTopic(String topicId) async {
    try {
      if (await _isOnline()) {
        await client.from('topics').delete().eq('id', topicId);
        await _offlineSync.deleteCachedRecord(
          entity: 'topics',
          recordId: topicId,
        );
        return true;
      }

      await _queueChange('topics', 'delete', {
        'id': topicId,
      }, recordId: topicId);
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
      if (await _isOnline()) {
        final response = await client
            .from('class_timetable')
            .select()
            .eq('user_id', userId)
            .order('day_of_week')
            .order('start_time');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('class_timetable', userId, rows);
        return rows;
      }

      return await _cachedList('class_timetable', userId);
    } catch (error) {
      debugPrint('getClassTimetable error: $error');
      return _cachedList('class_timetable', userId);
    }
  }

  Future<Map<String, dynamic>?> addClassSlot(Map<String, dynamic> data) async {
    try {
      final id = _newId();
      final payload = {
        'id': id,
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      };
      if (await _isOnline()) {
        final response = await client
            .from('class_timetable')
            .insert(payload)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord(
            'class_timetable',
            response['id'].toString(),
            response,
          );
        }
        return response;
      }

      await _queueChange('class_timetable', 'insert', payload, recordId: id);
      await _cacheRecord('class_timetable', id, payload);
      return payload;
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
      if (await _isOnline()) {
        final response = await client
            .from('class_timetable')
            .update(data)
            .eq('id', id)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('class_timetable', id, response);
        }
        return response;
      }

      final payload = {'id': id, ...data};
      await _queueChange('class_timetable', 'update', payload, recordId: id);
      await _cacheRecord('class_timetable', id, payload);
      return payload;
    } catch (error) {
      debugPrint('updateClassSlot error: $error');
      return null;
    }
  }

  Future<bool?> deleteClassSlot(String id) async {
    try {
      if (await _isOnline()) {
        await client.from('class_timetable').delete().eq('id', id);
        await _offlineSync.deleteCachedRecord(
          entity: 'class_timetable',
          recordId: id,
        );
        return true;
      }

      await _queueChange('class_timetable', 'delete', {'id': id}, recordId: id);
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
      final scope = '$userId:$day';
      if (await _isOnline()) {
        final response = await client
            .from('study_sessions')
            .select()
            .eq('user_id', userId)
            .eq('scheduled_date', day)
            .order('start_time');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('study_sessions', scope, rows);
        return rows;
      }

      return _cachedList('study_sessions', scope);
    } catch (error) {
      debugPrint('getStudySessions error: $error');
      return _cachedList(
        'study_sessions',
        '$userId:${date.toIso8601String().split('T').first}',
      );
    }
  }

  Future<Map<String, dynamic>?> addStudySession(
    Map<String, dynamic> data,
  ) async {
    try {
      final id = _newId();
      final payload = {
        'id': id,
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      };
      if (await _isOnline()) {
        final response = await client
            .from('study_sessions')
            .insert(payload)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord(
            'study_sessions',
            response['id'].toString(),
            response,
          );
        }
        return response;
      }

      await _queueChange('study_sessions', 'insert', payload, recordId: id);
      await _cacheRecord('study_sessions', id, payload);
      return payload;
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
      final payload = {
        'id': sessionId,
        'status': status,
        'actual_duration_minutes': actualDuration,
      };
      if (await _isOnline()) {
        final response = await client
            .from('study_sessions')
            .update({
              'status': status,
              'actual_duration_minutes': actualDuration,
            })
            .eq('id', sessionId)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('study_sessions', sessionId, response);
        }
        return response;
      }

      await _queueChange(
        'study_sessions',
        'update',
        payload,
        recordId: sessionId,
      );
      await _cacheRecord('study_sessions', sessionId, payload);
      return payload;
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
      if (await _isOnline()) {
        final response = await client
            .from('exams')
            .select()
            .eq('user_id', userId)
            .order('exam_date');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('exams', userId, rows);
        return rows;
      }

      return _cachedList('exams', userId);
    } catch (error) {
      debugPrint('getExams error: $error');
      return _cachedList('exams', userId);
    }
  }

  Future<Map<String, dynamic>?> addExam(Map<String, dynamic> data) async {
    try {
      final id = _newId();
      final payload = {
        'id': id,
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      };
      if (await _isOnline()) {
        final response = await client
            .from('exams')
            .insert(payload)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('exams', response['id'].toString(), response);
        }
        return response;
      }

      await _queueChange('exams', 'insert', payload, recordId: id);
      await _cacheRecord('exams', id, payload);
      return payload;
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
      if (await _isOnline()) {
        final response = await client
            .from('exams')
            .update(data)
            .eq('id', id)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('exams', id, response);
        }
        return response;
      }

      final payload = {'id': id, ...data};
      await _queueChange('exams', 'update', payload, recordId: id);
      await _cacheRecord('exams', id, payload);
      return payload;
    } catch (error) {
      debugPrint('updateExam error: $error');
      return null;
    }
  }

  Future<bool?> deleteExam(String id) async {
    try {
      if (await _isOnline()) {
        await client.from('exams').delete().eq('id', id);
        await _offlineSync.deleteCachedRecord(entity: 'exams', recordId: id);
        return true;
      }

      await _queueChange('exams', 'delete', {'id': id}, recordId: id);
      return true;
    } catch (error) {
      debugPrint('deleteExam error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getUpcomingExams(String userId) async {
    try {
      final scope = userId;
      if (await _isOnline()) {
        final response = await client
            .from('exams')
            .select()
            .eq('user_id', userId)
            .gte('exam_date', DateTime.now().toIso8601String().split('T').first)
            .order('exam_date');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('upcoming_exams', scope, rows);
        return rows;
      }

      return _cachedList('upcoming_exams', scope);
    } catch (error) {
      debugPrint('getUpcomingExams error: $error');
      return _cachedList('upcoming_exams', userId);
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
      final groupId = _newId();
      final groupPayload = {
        'id': groupId,
        'name': name,
        'description': description,
        'created_by': createdBy,
        'created_at': DateTime.now().toIso8601String(),
      };
      final membershipPayload = {
        'id': _newId(),
        'group_id': groupId,
        'user_id': createdBy,
        'role': 'admin',
        'joined_at': DateTime.now().toIso8601String(),
      };

      if (await _isOnline()) {
        final response = await client
            .from('study_groups')
            .insert(groupPayload)
            .select()
            .maybeSingle();

        if (response != null) {
          await client.from('group_members').insert(membershipPayload);
          await _cacheRecord(
            'study_groups',
            response['id'].toString(),
            response,
          );
        }

        return response;
      }

      await _queueChange(
        'study_groups',
        'insert',
        groupPayload,
        recordId: groupId,
      );
      await _queueChange(
        'group_members',
        'insert',
        membershipPayload,
        recordId: membershipPayload['id'].toString(),
      );
      await _cacheRecord('study_groups', groupId, groupPayload);
      return groupPayload;
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
      if (await _isOnline()) {
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
      }

      await _queueChange('group_members', 'joinGroup', {
        'invite_code': inviteCode.toUpperCase(),
        'user_id': userId,
      });
      return {
        'invite_code': inviteCode.toUpperCase(),
        'user_id': userId,
        'status': 'pending',
      };
    } catch (error) {
      debugPrint('joinGroup error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getMyGroups(String userId) async {
    try {
      if (await _isOnline()) {
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

          var memberCount = 1;
          String? lastActivityAt;

          try {
            final groupId = membership['group_id']?.toString();
            if (groupId != null && groupId.isNotEmpty) {
              final members = await client
                  .from('group_members')
                  .select('id')
                  .eq('group_id', groupId);
              memberCount = (members as List<dynamic>).length;

              final lastMessage = await client
                  .from('group_messages')
                  .select('created_at')
                  .eq('group_id', groupId)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();
              lastActivityAt = lastMessage?['created_at']?.toString();
            }
          } catch (error) {
            debugPrint('getMyGroups metadata error: $error');
          }

          results.add({
            ...membership,
            'study_groups': group,
            'member_count': memberCount,
            'last_activity_at': lastActivityAt,
          });
        }

        await _cacheList('my_groups', userId, results);
        return results;
      }

      return _cachedList('my_groups', userId);
    } catch (error) {
      debugPrint('getMyGroups error: $error');
      return _cachedList('my_groups', userId);
    }
  }

  Future<List<Map<String, dynamic>>?> getGroupMembers(String groupId) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('group_members')
            .select()
            .eq('group_id', groupId)
            .order('joined_at');

        final currentUser = getCurrentUser();
        final currentProfile = currentUser == null
            ? null
            : await getProfile(currentUser.id);

        final rows = (response as List<dynamic>).map((item) {
          final member = item as Map<String, dynamic>;
          final isCurrentUser = member['user_id'] == currentUser?.id;
          if (isCurrentUser) {
            return {
              ...member,
              'name': currentProfile?['name']?.toString() ?? 'You',
              'course': currentProfile?['course']?.toString() ?? 'N/A',
              'year_level': (currentProfile?['year_level'] as num?)?.toInt(),
            };
          }

          final rawUserId = member['user_id']?.toString() ?? '';
          final shortId = rawUserId.length <= 8
              ? rawUserId
              : rawUserId.substring(0, 8);
          return {
            ...member,
            'name': 'Member $shortId',
            'course': 'Private',
            'year_level': null,
          };
        }).toList();

        await _cacheList('group_members', groupId, rows);
        return rows;
      }

      return _cachedList('group_members', groupId);
    } catch (error) {
      debugPrint('getGroupMembers error: $error');
      return _cachedList('group_members', groupId);
    }
  }

  Future<bool?> removeGroupMember(String groupId, String memberUserId) async {
    try {
      if (await _isOnline()) {
        await client
            .from('group_members')
            .delete()
            .eq('group_id', groupId)
            .eq('user_id', memberUserId);
        return true;
      }

      await _queueChange('group_members', 'removeGroupMember', {
        'group_id': groupId,
        'user_id': memberUserId,
      });
      return true;
    } catch (error) {
      debugPrint('removeGroupMember error: $error');
      return null;
    }
  }

  Future<bool?> leaveGroup(String groupId, String userId) async {
    try {
      if (await _isOnline()) {
        await client
            .from('group_members')
            .delete()
            .eq('group_id', groupId)
            .eq('user_id', userId);
        return true;
      }

      await _queueChange('group_members', 'leaveGroup', {
        'group_id': groupId,
        'user_id': userId,
      });
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
      if (await _isOnline()) {
        final response = await client
            .from('group_messages')
            .select()
            .eq('topic_id', topicId)
            .order('created_at');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('topic_messages', topicId, rows);
        return rows;
      }

      return _cachedList('topic_messages', topicId);
    } catch (error) {
      debugPrint('getTopicMessages error: $error');
      return _cachedList('topic_messages', topicId);
    }
  }

  Future<List<Map<String, dynamic>>?> getGroupMessages(String groupId) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('group_messages')
            .select()
            .eq('group_id', groupId)
            .order('created_at');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('group_messages', groupId, rows);
        return rows;
      }

      return _cachedList('group_messages', groupId);
    } catch (error) {
      debugPrint('getGroupMessages error: $error');
      return _cachedList('group_messages', groupId);
    }
  }

  Future<Map<String, dynamic>?> sendMessage(Map<String, dynamic> data) async {
    try {
      final id = _newId();
      final payload = {
        'id': id,
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      };
      final scope =
          data['topic_id']?.toString() ??
          data['group_id']?.toString() ??
          'messages';
      if (await _isOnline()) {
        final response = await client
            .from('group_messages')
            .insert(payload)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord(
            'group_messages',
            response['id'].toString(),
            response,
          );
        }
        return response;
      }

      await _queueChange('group_messages', 'insert', payload, recordId: id);
      await _cacheRecord('group_messages', id, payload);
      final cached = await _cachedList('group_messages', scope) ?? [];
      await _cacheList('group_messages', scope, [...cached, payload]);
      return payload;
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
      debugPrint('subscribeToGroupMessages error: $error');
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
      final id = _newId();
      final payload = {
        'id': id,
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      };
      if (await _isOnline()) {
        final response = await client
            .from('weekly_reports')
            .insert(payload)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord(
            'weekly_reports',
            response['id'].toString(),
            response,
          );
        }
        return response;
      }

      await _queueChange('weekly_reports', 'insert', payload, recordId: id);
      await _cacheRecord('weekly_reports', id, payload);
      return payload;
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
      final scope = '$userId:$limit';
      if (await _isOnline()) {
        final response = await client
            .from('weekly_reports')
            .select()
            .eq('user_id', userId)
            .order('week_start', ascending: false)
            .limit(limit);
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('weekly_reports', scope, rows);
        return rows;
      }

      return _cachedList('weekly_reports', scope);
    } catch (error) {
      debugPrint('getWeeklyReports error: $error');
      return _cachedList('weekly_reports', '$userId:$limit');
    }
  }

  Future<Map<String, dynamic>?> getLastWeekReport(String userId) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('weekly_reports')
            .select()
            .eq('user_id', userId)
            .order('week_start', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('weekly_reports', userId, response);
        }
        return response;
      }

      return _cachedRecord('weekly_reports', userId);
    } catch (error) {
      debugPrint('getLastWeekReport error: $error');
      return _cachedRecord('weekly_reports', userId);
    }
  }

  // ---------------------------------------------------------------------------
  // UPLOADED NOTES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> saveUploadedNote(
    Map<String, dynamic> data,
  ) async {
    try {
      final id = _newId();
      final payload = {
        'id': id,
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      };
      final topicId = data['topic_id']?.toString() ?? 'notes';
      if (await _isOnline()) {
        final response = await client
            .from('uploaded_notes')
            .insert(payload)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord(
            'uploaded_notes',
            response['id'].toString(),
            response,
          );
        }
        return response;
      }

      await _queueChange('uploaded_notes', 'insert', payload, recordId: id);
      await _cacheRecord('uploaded_notes', id, payload);
      final cached = await _cachedList('uploaded_notes', topicId) ?? [];
      await _cacheList('uploaded_notes', topicId, [...cached, payload]);
      return payload;
    } catch (error) {
      debugPrint('saveUploadedNote error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getNotesByTopic(String topicId) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('uploaded_notes')
            .select()
            .eq('topic_id', topicId)
            .order('created_at', ascending: false);
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('uploaded_notes', topicId, rows);
        return rows;
      }

      return _cachedList('uploaded_notes', topicId);
    } catch (error) {
      debugPrint('getNotesByTopic error: $error');
      return _cachedList('uploaded_notes', topicId);
    }
  }

  Future<Map<String, dynamic>?> updateNoteProcessingStatus(
    String noteId,
    String status,
  ) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('uploaded_notes')
            .update({'processing_status': status})
            .eq('id', noteId)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('uploaded_notes', noteId, response);
        }
        return response;
      }

      final payload = {'id': noteId, 'processing_status': status};
      await _queueChange('uploaded_notes', 'update', payload, recordId: noteId);
      final existing =
          await _cachedRecord('uploaded_notes', noteId) ?? {'id': noteId};
      final optimistic = {...existing, 'processing_status': status};
      await _cacheRecord('uploaded_notes', noteId, optimistic);
      return optimistic;
    } catch (error) {
      debugPrint('updateNoteProcessingStatus error: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUploadedNoteSharing(
    String noteId,
    bool isShared,
  ) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('uploaded_notes')
            .update({'is_shared_with_group': isShared})
            .eq('id', noteId)
            .select()
            .maybeSingle();
        if (response != null) {
          await _cacheRecord('uploaded_notes', noteId, response);
        }
        return response;
      }

      final payload = {'id': noteId, 'is_shared_with_group': isShared};
      await _queueChange('uploaded_notes', 'update', payload, recordId: noteId);
      final existing =
          await _cachedRecord('uploaded_notes', noteId) ?? {'id': noteId};
      final optimistic = {...existing, 'is_shared_with_group': isShared};
      await _cacheRecord('uploaded_notes', noteId, optimistic);
      return optimistic;
    } catch (error) {
      debugPrint('updateUploadedNoteSharing error: $error');
      return null;
    }
  }

  Future<bool?> deleteUploadedNote(String noteId) async {
    try {
      if (await _isOnline()) {
        await client.from('uploaded_notes').delete().eq('id', noteId);
        await _offlineSync.deleteCachedRecord(
          entity: 'uploaded_notes',
          recordId: noteId,
        );
        return true;
      }

      await _queueChange('uploaded_notes', 'delete', {
        'id': noteId,
      }, recordId: noteId);
      return true;
    } catch (error) {
      debugPrint('deleteUploadedNote error: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getNoteChunks(String noteId) async {
    try {
      if (await _isOnline()) {
        final response = await client
            .from('note_chunks')
            .select()
            .eq('note_id', noteId)
            .order('chunk_index');
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('note_chunks', noteId, rows);
        return rows;
      }

      return _cachedList('note_chunks', noteId);
    } catch (error) {
      debugPrint('getNoteChunks error: $error');
      return _cachedList('note_chunks', noteId);
    }
  }

  Future<List<Map<String, dynamic>>?> saveNoteChunks(
    String noteId,
    List<String> chunks,
  ) async {
    try {
      final payload = chunks.asMap().entries.map((entry) {
        return {
          'id': _newId(),
          'note_id': noteId,
          'chunk_index': entry.key,
          'content': entry.value,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      if (await _isOnline()) {
        final response = await client
            .from('note_chunks')
            .insert(payload)
            .select();
        final rows = (response as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        await _cacheList('note_chunks', noteId, rows);
        return rows;
      }

      for (final chunk in payload) {
        await _queueChange(
          'note_chunks',
          'insert',
          chunk,
          recordId: chunk['id']?.toString(),
        );
      }
      await _cacheList('note_chunks', noteId, payload);
      return payload;
    } catch (error) {
      debugPrint('saveNoteChunks error: $error');
      return null;
    }
  }
}
