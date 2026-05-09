import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/app_logger.dart';
import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class ProfileService extends DomainServiceBase {
  ProfileService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;


// ---------------------------------------------------------------------------
// PROFILES
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>?> getProfile(String userId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (response != null) {
        await cacheRecord('profiles', userId, response);
      }
      return response;
    }

    return await cachedRecord('profiles', userId);
  } on Object catch (error, stackTrace) {
    AppLogger.warning('getProfile error', error: error, stackTrace: stackTrace);
    return cachedRecord('profiles', userId);
  }
}

Future<Map<String, dynamic>?> updateProfile(
  String userId,
  Map<String, dynamic> data,
) async {
  final payload = {
    'id': userId,
    ...data,
    'updated_at': DateTime.now().toIso8601String(),
  };

  try {
    if (await isOnline()) {
      await _upsertProfile(userId: userId, data: data);
      await cacheRecord('profiles', userId, payload);
      return payload;
    }

    await queueChange('profiles', 'upsert', payload, recordId: userId);
    final existing =
        await cachedRecord('profiles', userId) ?? {'id': userId};
    final optimistic = {...existing, ...payload};
    await cacheRecord('profiles', userId, optimistic);
    return optimistic;
  } on Object catch (error, stackTrace) {
    AppLogger.warning('updateProfile error', error: error, stackTrace: stackTrace);
    try {
      await queueChange('profiles', 'upsert', payload, recordId: userId);
      final existing =
          await cachedRecord('profiles', userId) ?? {'id': userId};
      final optimistic = {...existing, ...payload};
      await cacheRecord('profiles', userId, optimistic);
      return optimistic;
    } on Object catch (queueError, queueStack) {
      AppLogger.warning('updateProfile queue fallback error', error: queueError, stackTrace: queueStack);
      return null;
    }
  }
}

Future<void> _upsertProfile({
  required String userId,
  required Map<String, dynamic> data,
}) async {
  await client.from('profiles').upsert({
    'id': userId,
    ...data,
    'updated_at': DateTime.now().toIso8601String(),
  }, onConflict: 'id');
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
  } on Object catch (error, stackTrace) {
    // Non-fatal: user can still proceed and retry profile updates later.
    AppLogger.warning('ensureProfileExists error', error: error, stackTrace: stackTrace);
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
  } on Object catch (error, stackTrace) {
    AppLogger.warning('updateStreak error', error: error, stackTrace: stackTrace);
    return null;
  }
}
}
