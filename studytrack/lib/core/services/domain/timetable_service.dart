import 'dart:async';
import '../../utils/app_logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class TimetableService extends DomainServiceBase {
  TimetableService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;

// ---------------------------------------------------------------------------
// TIMETABLE
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>?> getClassTimetable(String userId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('class_timetable')
          .select()
          .eq('user_id', userId)
          .order('day_of_week')
          .order('start_time');
      final rows = activeRows(response as List<dynamic>);
      await cacheList('class_timetable', userId, rows);
      return rows;
    }

    return activeRows(
      await cachedList('class_timetable', userId) ?? const [],
    );
  } catch (error) {
    AppLogger.warning('getClassTimetable error', error: error);
    return activeRows(
      await cachedList('class_timetable', userId) ?? const [],
    );
  }
}

Future<Map<String, dynamic>?> addClassSlot(Map<String, dynamic> data) async {
  try {
    final id = newId();
    final payload = {
      'id': id,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (await isOnline()) {
      final response = await client
          .from('class_timetable')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord(
          'class_timetable',
          response['id'].toString(),
          response,
        );
      }
      return response;
    }

    await queueChange('class_timetable', 'insert', payload, recordId: id);
    await cacheRecord('class_timetable', id, payload);
    return payload;
  } catch (error) {
    AppLogger.warning('addClassSlot error', error: error);
    return null;
  }
}

Future<Map<String, dynamic>?> updateClassSlot(
  String id,
  Map<String, dynamic> data,
) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('class_timetable')
          .update(data)
          .eq('id', id)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('class_timetable', id, response);
      }
      return response;
    }

    final payload = {'id': id, ...data};
    await queueChange('class_timetable', 'update', payload, recordId: id);
    await cacheRecord('class_timetable', id, payload);
    return payload;
  } catch (error) {
    AppLogger.warning('updateClassSlot error', error: error);
    return null;
  }
}

Future<bool?> deleteClassSlot(String id) async {
  try {
    if (await isOnline()) {
      final userId = await currentUserId();
      await client
          .from('class_timetable')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      if (userId != null) {
        await purgeCachedListItem(
          entity: 'class_timetable',
          scope: userId,
          recordId: id,
        );
      }
      await purgeCachedRecord('class_timetable', id);
      return true;
    }

    await queueChange('class_timetable', 'update', {
      'id': id,
      'deleted_at': DateTime.now().toIso8601String(),
    }, recordId: id);
    return true;
  } catch (error) {
    AppLogger.warning('deleteClassSlot error', error: error);
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
}
