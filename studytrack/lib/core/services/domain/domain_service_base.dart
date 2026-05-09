import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../utils/app_logger.dart';
import '../offline_sync_service.dart';

/// Shared infrastructure for all domain services:
/// offline cache helpers, ID generation, soft-delete filter.
///
/// Domain services extend this class — no logic lives here,
/// only the plumbing that every service needs.
abstract class DomainServiceBase {
  DomainServiceBase(this._offlineSync);

  final OfflineSyncService _offlineSync;
  final Uuid _uuid = const Uuid();

  Future<bool> isOnline() async => _offlineSync.onlineNow;

  String newId() => _uuid.v4();

  String queryKey(String entity, String scope) => '$entity::$scope';

  Future<List<Map<String, dynamic>>?> cachedList(
    String entity,
    String scope,
  ) =>
      _offlineSync.cachedQuery(queryKey(entity, scope));

  Future<void> cacheList(
    String entity,
    String scope,
    List<Map<String, dynamic>> items,
  ) async {
    await _offlineSync.cacheQuery(
      queryKey: queryKey(entity, scope),
      entity: entity,
      payload: items,
    );
  }

  Future<Map<String, dynamic>?> cachedRecord(
    String entity,
    String recordId,
  ) =>
      _offlineSync.cachedRecord(entity: entity, recordId: recordId);

  Future<void> cacheRecord(
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

  Future<void> queueChange(
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

  Future<void> purgeCachedListItem({
    required String entity,
    required String scope,
    required String recordId,
  }) async {
    final cached = await cachedList(entity, scope);
    if (cached == null || cached.isEmpty) return;
    final filtered = cached
        .where((row) => row['id']?.toString() != recordId)
        .toList();
    await cacheList(entity, scope, filtered);
  }

  Future<void> clearCachedList(String entity, String scope) =>
      cacheList(entity, scope, const []);

  Future<void> purgeCachedRecord(String entity, String recordId) =>
      _offlineSync.deleteCachedRecord(entity: entity, recordId: recordId);

  bool isActiveRow(Map<String, dynamic> row) => row['deleted_at'] == null;

  List<Map<String, dynamic>> activeRows(List<dynamic> response) => response
      .whereType<Map<String, dynamic>>()
      .where(isActiveRow)
      .toList(growable: false);

  Map<String, dynamic>? activeRow(Map<String, dynamic>? row) =>
      row == null || !isActiveRow(row) ? null : row;

  void logWarning(String msg, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.warning(msg, error: error, stackTrace: stackTrace);

  User? getCurrentUser() => Supabase.instance.client.auth.currentUser;

  Future<String?> currentUserId() async => getCurrentUser()?.id;
}
