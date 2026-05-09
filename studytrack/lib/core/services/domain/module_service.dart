import 'dart:async';
import '../../utils/app_logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/module_model.dart';
import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class ModuleService extends DomainServiceBase {
  ModuleService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;

// ---------------------------------------------------------------------------
// MODULES
// ---------------------------------------------------------------------------

Future<List<ModuleModel>?> getModules(String userId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('modules')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('created_at');
      final rows = activeRows(response as List<dynamic>);
      await cacheList('modules', userId, rows);
      return rows.map(ModuleModel.fromJson).toList();
    }

    final cached = await cachedList('modules', userId);
    return activeRows(
      cached ?? const [],
    ).map(ModuleModel.fromJson).toList(growable: false);
  } on Object catch (error, stackTrace) {
    AppLogger.warning('getModules error', error: error, stackTrace: stackTrace);
    final cached = await cachedList('modules', userId);
    return activeRows(
      cached ?? const [],
    ).map(ModuleModel.fromJson).toList(growable: false);
  }
}

Future<ModuleModel?> getModuleById(String moduleId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('modules')
          .select()
          .eq('id', moduleId)
          .maybeSingle();

      if (response == null || response['deleted_at'] != null) {
        return null;
      }

      await cacheRecord('modules', moduleId, response);
      return ModuleModel.fromJson(response);
    }

    final cached = await cachedRecord('modules', moduleId);
    return activeRow(cached) == null ? null : ModuleModel.fromJson(cached!);
  } on Object catch (error, stackTrace) {
    AppLogger.warning('getModuleById error', error: error, stackTrace: stackTrace);
    final cached = await cachedRecord('modules', moduleId);
    return activeRow(cached) == null ? null : ModuleModel.fromJson(cached!);
  }
}

Future<Map<String, dynamic>?> addModule(
  String userId,
  String name,
  String color,
) async {
  try {
    final moduleId = newId();
    final payload = {
      'id': moduleId,
      'user_id': userId,
      'name': name,
      'color': color,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (await isOnline()) {
      final response = await client
          .from('modules')
          .insert(payload)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('modules', response['id'].toString(), response);
      }
      return response;
    }

    await queueChange('modules', 'insert', payload, recordId: moduleId);
    await cacheRecord('modules', moduleId, payload);
    return payload;
  } on Object catch (error, stackTrace) {
    AppLogger.warning('addModule error', error: error, stackTrace: stackTrace);
    return null;
  }
}

Future<Map<String, dynamic>?> updateModule(
  String moduleId,
  Map<String, dynamic> data,
) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('modules')
          .update(data)
          .eq('id', moduleId)
          .select()
          .maybeSingle();
      if (response != null) {
        await cacheRecord('modules', moduleId, response);
      }
      return response;
    }

    final payload = {'id': moduleId, ...data};
    await queueChange('modules', 'update', payload, recordId: moduleId);
    final existing =
        await cachedRecord('modules', moduleId) ?? {'id': moduleId};
    final optimistic = {...existing, ...data, 'id': moduleId};
    await cacheRecord('modules', moduleId, optimistic);
    return optimistic;
  } on Object catch (error, stackTrace) {
    AppLogger.warning('updateModule error', error: error, stackTrace: stackTrace);
    return null;
  }
}

Future<bool?> deleteModule(String moduleId) async {
  try {
    if (await isOnline()) {
      final userId = await currentUserId();
      await client
          .from('modules')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', moduleId);
      if (userId != null) {
        await purgeCachedListItem(
          entity: 'modules',
          scope: userId,
          recordId: moduleId,
        );
        await clearCachedList('exams', userId);
      }
      await clearCachedList('topics', moduleId);
      await purgeCachedRecord('modules', moduleId);
      return true;
    }

    await queueChange('modules', 'update', {
      'id': moduleId,
      'deleted_at': DateTime.now().toIso8601String(),
    }, recordId: moduleId);
    return true;
  } on Object catch (error, stackTrace) {
    AppLogger.warning('deleteModule error', error: error, stackTrace: stackTrace);
    return null;
  }
}
}
