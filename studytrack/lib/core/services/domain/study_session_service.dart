import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_logger.dart';

import '../../../models/study_session_model.dart';
import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class StudySessionService extends DomainServiceBase {
  StudySessionService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;


Future<List<Map<String, dynamic>>?> getStudySessions(
  String userId,
  DateTime date,
) async {
  try {
    final day = date.toIso8601String().split('T').first;
    final scope = '$userId:$day';
    if (await isOnline()) {
      final response = await client
          .from('study_sessions')
          .select()
          .eq('user_id', userId)
          .eq('scheduled_date', day)
          .isFilter('deleted_at', null)
          .order('start_time');
      final rows = activeRows(response as List<dynamic>);
      await cacheList('study_sessions', scope, rows);
      return rows;
    }

    return cachedList('study_sessions', scope);
  } catch (error) {
    AppLogger.warning('getStudySessions error', error: error);
    return cachedList(
      'study_sessions',
      '$userId:${date.toIso8601String().split('T').first}',
    );
  }
}

Future<Map<String, dynamic>?> addStudySession(
  Map<String, dynamic> data,
) async {
  try {
    final id = newId();
    final payload = {
      'id': id,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (await isOnline()) {
      final response = await client
          .from('study_sessions')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord(
          'study_sessions',
          response['id'].toString(),
          response,
        );
      }
      return response;
    }

    await queueChange('study_sessions', 'insert', payload, recordId: id);
    await cacheRecord('study_sessions', id, payload);
    return payload;
  } catch (error) {
    AppLogger.warning('addStudySession error', error: error);
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
    if (await isOnline()) {
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
        await cacheRecord('study_sessions', sessionId, response);
      }
      return response;
    }

    await queueChange(
      'study_sessions',
      'update',
      payload,
      recordId: sessionId,
    );
    await cacheRecord('study_sessions', sessionId, payload);
    return payload;
  } catch (error) {
    AppLogger.warning('updateSessionStatus error', error: error);
    return null;
  }
}

Future<void> deleteSession(String sessionId) async {
  await client
      .from('study_sessions')
      .update({'deleted_at': DateTime.now().toIso8601String()})
      .eq('id', sessionId);
}

Future<StudySessionModel> endSession(String sessionId) async {
}
