import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class OfflinePendingChange {
  const OfflinePendingChange({
    required this.id,
    required this.entity,
    required this.operation,
    required this.recordId,
    required this.payload,
    required this.createdAt,
  });

  final int id;
  final String entity;
  final String operation;
  final String? recordId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
}

class OfflineDataStore {
  OfflineDataStore._internal();

  static final OfflineDataStore instance = OfflineDataStore._internal();

  Database? _database;

  Future<void> initialize({String? databasePath}) async {
    if (_database != null) {
      return;
    }

    final path = databasePath ?? await _defaultDatabasePath();
    _database = sqlite3.open(path);
    _createTables();
  }

  Future<String> _defaultDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, 'studytrack_offline.db');
  }

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('OfflineDataStore.initialize must be called first.');
    }
    return database;
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS cached_records (
        cache_key TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS cached_queries (
        query_key TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS pending_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        operation TEXT NOT NULL,
        record_id TEXT,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> upsertRecord({
    required String entity,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    _db.execute(
      'INSERT OR REPLACE INTO cached_records (cache_key, entity, record_id, payload, updated_at) VALUES (?, ?, ?, ?, ?)',
      [
        _recordCacheKey(entity, recordId),
        entity,
        recordId,
        jsonEncode(payload),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<void> deleteRecord({
    required String entity,
    required String recordId,
  }) async {
    _db.execute('DELETE FROM cached_records WHERE cache_key = ?', [
      _recordCacheKey(entity, recordId),
    ]);
  }

  Future<Map<String, dynamic>?> readRecord({
    required String entity,
    required String recordId,
  }) async {
    final rows = _db.select(
      'SELECT payload FROM cached_records WHERE cache_key = ? LIMIT 1',
      [_recordCacheKey(entity, recordId)],
    );
    if (rows.isEmpty) {
      return null;
    }

    return _decodeMap(rows.first['payload'] as String?);
  }

  Future<void> upsertQueryResults({
    required String queryKey,
    required String entity,
    required List<Map<String, dynamic>> payload,
  }) async {
    _db.execute(
      'INSERT OR REPLACE INTO cached_queries (query_key, entity, payload, updated_at) VALUES (?, ?, ?, ?)',
      [queryKey, entity, jsonEncode(payload), DateTime.now().toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>?> readQueryResults(String queryKey) async {
    final rows = _db.select(
      'SELECT payload FROM cached_queries WHERE query_key = ? LIMIT 1',
      [queryKey],
    );
    if (rows.isEmpty) {
      return null;
    }

    final payload = rows.first['payload'] as String?;
    if (payload == null || payload.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (value) => Map<String, dynamic>.from(value.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> queueChange({
    required String entity,
    required String operation,
    required Map<String, dynamic> payload,
    String? recordId,
  }) async {
    _db.execute(
      'INSERT INTO pending_changes (entity, operation, record_id, payload, created_at) VALUES (?, ?, ?, ?, ?)',
      [
        entity,
        operation,
        recordId,
        jsonEncode(payload),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<List<OfflinePendingChange>> getPendingChanges() async {
    final rows = _db.select(
      'SELECT id, entity, operation, record_id, payload, created_at FROM pending_changes ORDER BY id ASC',
    );

    return rows.map((row) {
      return OfflinePendingChange(
        id: row['id'] as int,
        entity: row['entity'] as String,
        operation: row['operation'] as String,
        recordId: row['record_id'] as String?,
        payload:
            _decodeMap(row['payload'] as String?) ?? const <String, dynamic>{},
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<void> removePendingChange(int id) async {
    _db.execute('DELETE FROM pending_changes WHERE id = ?', [id]);
  }

  Future<int> pendingCount() async {
    final rows = _db.select('SELECT COUNT(*) AS total FROM pending_changes');
    if (rows.isEmpty) {
      return 0;
    }

    return (rows.first['total'] as int?) ?? 0;
  }

  Future<void> clearAllData() async {
    _db.execute('DELETE FROM pending_changes');
    _db.execute('DELETE FROM cached_queries');
    _db.execute('DELETE FROM cached_records');
  }

  String _recordCacheKey(String entity, String recordId) =>
      '$entity::$recordId';

  Map<String, dynamic>? _decodeMap(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    }
    return null;
  }
}
