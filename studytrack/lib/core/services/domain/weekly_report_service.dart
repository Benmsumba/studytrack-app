import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_logger.dart';

import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class WeeklyReportService extends DomainServiceBase {
  WeeklyReportService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;

// WEEKLY REPORTS
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>?> saveWeeklyReport(
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
          .from('weekly_reports')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord(
          'weekly_reports',
          response['id'].toString(),
          response,
        );
      }
      return response;
    }

    await queueChange('weekly_reports', 'insert', payload, recordId: id);
    await cacheRecord('weekly_reports', id, payload);
    return payload;
  } catch (error) {
    AppLogger.warning('saveWeeklyReport error', error: error);
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getWeeklyReports(
  String userId,
  int limit,
) async {
  try {
    final scope = '$userId:$limit';
    if (await isOnline()) {
      final response = await client
          .from('weekly_reports')
          .select()
          .eq('user_id', userId)
          .order('week_start', ascending: false)
          .limit(limit);
      final rows = (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      await cacheList('weekly_reports', scope, rows);
      return rows;
    }

    return cachedList('weekly_reports', scope);
  } catch (error) {
    AppLogger.warning('getWeeklyReports error', error: error);
    return cachedList('weekly_reports', '$userId:$limit');
  }
}

Future<Map<String, dynamic>?> getLastWeekReport(String userId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('weekly_reports')
          .select()
          .eq('user_id', userId)
          .order('week_start', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response != null) {
        await cacheRecord('weekly_reports', userId, response);
      }
      return response;
    }

    return cachedRecord('weekly_reports', userId);
  } catch (error) {
    AppLogger.warning('getLastWeekReport error', error: error);
    return cachedRecord('weekly_reports', userId);
  }
}

// ---------------------------------------------------------------------------
}
