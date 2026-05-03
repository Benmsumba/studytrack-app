import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/core/services/offline_data_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineDataStore queue semantics', () {
    late OfflineDataStore store;

    setUp(() async {
      store = OfflineDataStore.instance;
      await store.initialize(databasePath: ':memory:');
      await store.clearAllData();
    });

    test('collapses repeated mutations for the same record', () async {
      await store.queueChange(
        entity: 'topics',
        operation: 'insert',
        payload: {'id': 'topic-1', 'name': 'Offline topic'},
        recordId: 'topic-1',
      );

      await store.queueChange(
        entity: 'topics',
        operation: 'update',
        payload: {'id': 'topic-1', 'name': 'Offline topic updated'},
        recordId: 'topic-1',
      );

      await store.queueChange(
        entity: 'topics',
        operation: 'delete',
        payload: {'id': 'topic-1'},
        recordId: 'topic-1',
      );

      final pending = await store.getPendingChanges();

      expect(pending, isEmpty);
      expect(await store.pendingCount(), 0);
    });

    test('keeps only the latest payload for repeated updates', () async {
      await store.queueChange(
        entity: 'study_sessions',
        operation: 'update',
        payload: {'id': 'session-1', 'status': 'paused'},
        recordId: 'session-1',
      );

      await store.queueChange(
        entity: 'study_sessions',
        operation: 'update',
        payload: {'id': 'session-1', 'status': 'completed'},
        recordId: 'session-1',
      );

      final pending = await store.getPendingChanges();

      expect(pending.length, 1);
      expect(pending.first.operation, 'update');
      expect(pending.first.payload['status'], 'completed');
    });

    test('pending changes can be removed after sync replay', () async {
      await store.queueChange(
        entity: 'study_sessions',
        operation: 'insert',
        payload: {'id': 'session-1', 'status': 'pending'},
        recordId: 'session-1',
      );

      final before = await store.getPendingChanges();
      expect(before, isNotEmpty);

      await store.removePendingChange(before.first.id);
      final after = await store.getPendingChanges();

      expect(after, isEmpty);
      expect(await store.pendingCount(), 0);
    });
  });
}
