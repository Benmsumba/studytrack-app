import 'dart:async';
import '../../utils/app_logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class ExamService extends DomainServiceBase {
  ExamService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;

// ---------------------------------------------------------------------------
// EXAMS
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>?> getExams(String userId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('exams')
          .select()
          .eq('user_id', userId)
          .order('exam_date');
      final rows = activeRows(response as List<dynamic>);
      await cacheList('exams', userId, rows);
      return rows;
    }

    return activeRows(await cachedList('exams', userId) ?? const []);
  } catch (error) {
    AppLogger.warning('getExams error', error: error);
    return activeRows(await cachedList('exams', userId) ?? const []);
  }
}

Future<Map<String, dynamic>?> addExam(Map<String, dynamic> data) async {
  try {
    final id = newId();
    final payload = {
      'id': id,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (await isOnline()) {
      final response = await client
          .from('exams')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('exams', response['id'].toString(), response);
      }
      return response;
    }

    await queueChange('exams', 'insert', payload, recordId: id);
    await cacheRecord('exams', id, payload);
    return payload;
  } catch (error) {
    AppLogger.warning('addExam error', error: error);
    return null;
  }
}

Future<Map<String, dynamic>?> updateExam(
  String id,
  Map<String, dynamic> data,
) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('exams')
          .update(data)
          .eq('id', id)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('exams', id, response);
      }
      return response;
    }

    final payload = {'id': id, ...data};
    await queueChange('exams', 'update', payload, recordId: id);
    await cacheRecord('exams', id, payload);
    return payload;
  } catch (error) {
    AppLogger.warning('updateExam error', error: error);
    return null;
  }
}

Future<bool?> deleteExam(String id) async {
  try {
    if (await isOnline()) {
      final userId = await currentUserId();
      await client
          .from('exams')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      if (userId != null) {
        await purgeCachedListItem(
          entity: 'exams',
          scope: userId,
          recordId: id,
        );
      }
      await purgeCachedRecord('exams', id);
      return true;
    }

    await queueChange('exams', 'update', {
      'id': id,
      'deleted_at': DateTime.now().toIso8601String(),
    }, recordId: id);
    return true;
  } catch (error) {
    AppLogger.warning('deleteExam error', error: error);
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getUpcomingExams(String userId) async {
  try {
    final scope = userId;
    if (await isOnline()) {
      final response = await client
          .from('exams')
          .select()
          .eq('user_id', userId)
          .gte('exam_date', DateTime.now().toIso8601String().split('T').first)
          .order('exam_date');
      final rows = activeRows(response as List<dynamic>);
      await cacheList('upcoming_exams', scope, rows);
      return rows;
    }

    return activeRows(
      await cachedList('upcoming_exams', scope) ?? const [],
    );
  } catch (error) {
    AppLogger.warning('getUpcomingExams error', error: error);
    return activeRows(
      await cachedList('upcoming_exams', userId) ?? const [],
    );
  }
}
}
