import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../services/supabase_service.dart';
import 'offline_data_store.dart';

class OfflineSyncService extends ChangeNotifier {
  OfflineSyncService._internal();

  static final OfflineSyncService instance = OfflineSyncService._internal();

  final Connectivity _connectivity = Connectivity();
  final OfflineDataStore _store = OfflineDataStore.instance;
  final Uuid _uuid = const Uuid();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _initialized = false;
  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingChanges = 0;
  DateTime? _lastSyncedAt;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingChanges => _pendingChanges;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get hasPendingChanges => _pendingChanges > 0;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _store.initialize();
    _pendingChanges = await _store.pendingCount();
    _isOnline = await _hasInternetAccess();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final online = await _hasInternetAccess(results);
      if (_isOnline != online) {
        _isOnline = online;
        notifyListeners();
      }

      if (online) {
        await syncPendingChanges();
      }
    });

    _initialized = true;
    notifyListeners();
    if (_isOnline) {
      await syncPendingChanges();
    }
  }

  Future<bool> _hasInternetAccess([List<ConnectivityResult>? results]) async {
    final connectivityResults =
        results ?? await _connectivity.checkConnectivity();
    if (connectivityResults.isEmpty ||
        connectivityResults.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final lookup = await InternetAddress.lookup('google.com');
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> get onlineNow async {
    _isOnline = await _hasInternetAccess();
    return _isOnline;
  }

  Future<void> cacheRecord({
    required String entity,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await _store.upsertRecord(
      entity: entity,
      recordId: recordId,
      payload: payload,
    );
  }

  Future<void> deleteCachedRecord({
    required String entity,
    required String recordId,
  }) async {
    await _store.deleteRecord(entity: entity, recordId: recordId);
  }

  Future<void> cacheQuery({
    required String queryKey,
    required String entity,
    required List<Map<String, dynamic>> payload,
  }) async {
    await _store.upsertQueryResults(
      queryKey: queryKey,
      entity: entity,
      payload: payload,
    );
  }

  Future<Map<String, dynamic>?> cachedRecord({
    required String entity,
    required String recordId,
  }) async => _store.readRecord(entity: entity, recordId: recordId);

  Future<List<Map<String, dynamic>>?> cachedQuery(String queryKey) async =>
      _store.readQueryResults(queryKey);

  Future<void> queueChange({
    required String entity,
    required String operation,
    required Map<String, dynamic> payload,
    String? recordId,
  }) async {
    await _store.queueChange(
      entity: entity,
      operation: operation,
      payload: payload,
      recordId: recordId,
    );
    _pendingChanges = await _store.pendingCount();
    notifyListeners();
  }

  Future<void> syncPendingChanges() async {
    if (_isSyncing || !await _hasInternetAccess()) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final pendingChanges = await _store.getPendingChanges();
      for (final change in pendingChanges) {
        final success = await _applyChange(change);
        if (success) {
          await _store.removePendingChange(change.id);
        }
      }

      _pendingChanges = await _store.pendingCount();
      _lastSyncedAt = DateTime.now();
      await _updateWidgetSnapshot();
    } finally {
      _isSyncing = false;
      _isOnline = await _hasInternetAccess();
      notifyListeners();
    }
  }

  Future<bool> _applyChange(OfflinePendingChange change) async {
    final client = Supabase.instance.client;
    try {
      switch (change.operation) {
        case 'insert':
          await client.from(change.entity).insert(change.payload);
          return true;
        case 'update':
          final recordId = change.recordId ?? change.payload['id']?.toString();
          if (recordId == null || recordId.isEmpty) {
            return false;
          }
          await client
              .from(change.entity)
              .update(change.payload)
              .eq('id', recordId);
          return true;
        case 'delete':
          final recordId = change.recordId ?? change.payload['id']?.toString();
          if (recordId == null || recordId.isEmpty) {
            return false;
          }
          await client.from(change.entity).delete().eq('id', recordId);
          return true;
        case 'upsert':
          await client.from(change.entity).upsert(change.payload);
          return true;
        case 'joinGroup':
          if (change.entity != 'group_members') {
            return false;
          }
          final inviteCode = change.payload['invite_code']
              ?.toString()
              .toUpperCase();
          final userId = change.payload['user_id']?.toString();
          if (inviteCode == null || inviteCode.isEmpty || userId == null) {
            return false;
          }

          final group = await client
              .from('study_groups')
              .select()
              .eq('invite_code', inviteCode)
              .maybeSingle();
          if (group == null) {
            return false;
          }

          await client.from('group_members').upsert({
            'group_id': group['id'],
            'user_id': userId,
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
          });
          return true;
        case 'removeGroupMember':
        case 'leaveGroup':
          if (change.entity != 'group_members') {
            return false;
          }
          final groupId = change.payload['group_id']?.toString();
          final userId = change.payload['user_id']?.toString();
          if (groupId == null || userId == null) {
            return false;
          }

          await client
              .from('group_members')
              .delete()
              .eq('group_id', groupId)
              .eq('user_id', userId);
          return true;
        default:
          return false;
      }
    } catch (error) {
      debugPrint(
        'sync change failed (${change.entity}/${change.operation}): $error',
      );
      return false;
    }
  }

  Future<String> generateRecordId() async => _uuid.v4();

  Future<void> clearOfflineStateForTesting() async {
    await _store.clearAllData();
    _pendingChanges = 0;
    notifyListeners();
  }

  Future<void> saveWidgetSnapshot({required String userId}) async {
    if (!Platform.isAndroid) {
      return;
    }

    final service = SupabaseService();
    final profile = await service.getProfile(userId);
    final timetable = await service.getClassTimetable(userId) ?? [];
    final exams = await service.getUpcomingExams(userId) ?? [];

    final today = DateTime.now().weekday;
    final todayClasses = timetable.where((slot) {
      final day = (slot['day_of_week'] as num?)?.toInt() ?? 0;
      return day == today;
    }).toList();

    final nextExam = exams.isEmpty ? null : exams.first;
    final nextExamDate = nextExam == null
        ? null
        : DateTime.tryParse(nextExam['exam_date']?.toString() ?? '');
    final daysUntilExam = nextExamDate?.difference(DateTime.now()).inDays;

    final streakCount = (profile?['streak_count'] as num?)?.toInt() ?? 0;

    await HomeWidget.saveWidgetData(
      'studytrack_widget_today_classes',
      todayClasses.length,
    );
    await HomeWidget.saveWidgetData(
      'studytrack_widget_today_label',
      todayClasses.isEmpty
          ? 'No classes today'
          : '${todayClasses.length} class${todayClasses.length == 1 ? '' : 'es'} today',
    );
    await HomeWidget.saveWidgetData(
      'studytrack_widget_next_exam',
      daysUntilExam == null
          ? 'No upcoming exam'
          : 'Next exam in $daysUntilExam day${daysUntilExam == 1 ? '' : 's'}',
    );
    await HomeWidget.saveWidgetData('studytrack_widget_streak', streakCount);
    await HomeWidget.saveWidgetData(
      'studytrack_widget_updated_at',
      DateTime.now().toIso8601String(),
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.studytrack.app.StudyTrackWidgetProvider',
    );
  }

  Future<void> _updateWidgetSnapshot() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await saveWidgetSnapshot(userId: user.id);
    } catch (error) {
      debugPrint('saveWidgetSnapshot error: $error');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
