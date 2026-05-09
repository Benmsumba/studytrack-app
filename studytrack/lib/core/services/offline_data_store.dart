import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'encryption_service.dart';

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
  late final EncryptionService _encryption;
  bool _encryptionReady = false;

  static const _cacheTtlDays = 30;
  static const _maxCachedRecords = 500;
  static const _maxCachedQueries = 200;

  Future<void> initialize({
    String? databasePath,
    EncryptionService? encryptionService,
  }) async {
    if (_database != null) return;

    _encryption = encryptionService ?? EncryptionService();
    try {
      await _encryption.initialize();
      _encryptionReady = true;
    } on Object catch (e) {
      // Non-fatal: cache will store plaintext but still function.
      assert(() {
        // ignore: avoid_print
        print('[W/OfflineDataStore] Encryption init failed — storing plaintext: $e');
        return true;
      }());
    }

    final path = databasePath ?? await _defaultDatabasePath();
    _database = sqlite3.open(path);
    _createTables();
    pruneStaleEntries();
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

  // ---------------------------------------------------------------------------
  // Encryption helpers
  // ---------------------------------------------------------------------------

  String _encrypt(String plaintext) {
    if (!_encryptionReady) return plaintext;
    try {
      return _encryption.encryptString(plaintext);
    } on Object catch (_) {
      return plaintext;
    }
  }

  String _decrypt(String ciphertext) {
    if (!_encryptionReady) return ciphertext;
    try {
      return _encryption.decryptString(ciphertext);
    } on Object catch (_) {
      // Fallback: data was stored unencrypted (migration scenario).
      return ciphertext;
    }
  }

  // ---------------------------------------------------------------------------
  // Record cache
  // ---------------------------------------------------------------------------

  Future<void> upsertRecord({
    required String entity,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    final encoded = _encrypt(jsonEncode(payload));
    _db.execute(
      'INSERT OR REPLACE INTO cached_records '
      '(cache_key, entity, record_id, payload, updated_at) VALUES (?, ?, ?, ?, ?)',
      [
        _recordCacheKey(entity, recordId),
        entity,
        recordId,
        encoded,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  /// Inserts or replaces multiple records in a single transaction.
  Future<void> batchUpsertRecords({
    required String entity,
    required List<Map<String, dynamic>> records,
    required String Function(Map<String, dynamic>) idExtractor,
  }) async {
    if (records.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final stmt = _db.prepare(
      'INSERT OR REPLACE INTO cached_records '
      '(cache_key, entity, record_id, payload, updated_at) VALUES (?, ?, ?, ?, ?)',
    );
    try {
      _db.execute('BEGIN');
      for (final record in records) {
        final recordId = idExtractor(record);
        final encoded = _encrypt(jsonEncode(record));
        stmt.execute([_recordCacheKey(entity, recordId), entity, recordId, encoded, now]);
      }
      _db.execute('COMMIT');
    } on Object catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.dispose();
    }
  }

  Future<void> deleteRecord({
    required String entity,
    required String recordId,
  }) async {
    _db.execute(
      'DELETE FROM cached_records WHERE cache_key = ?',
      [_recordCacheKey(entity, recordId)],
    );
  }

  Future<Map<String, dynamic>?> readRecord({
    required String entity,
    required String recordId,
  }) async {
    final rows = _db.select(
      'SELECT payload FROM cached_records WHERE cache_key = ? LIMIT 1',
      [_recordCacheKey(entity, recordId)],
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['payload'] as String?;
    return _decodeMap(raw == null ? null : _decrypt(raw));
  }

  // ---------------------------------------------------------------------------
  // Query cache
  // ---------------------------------------------------------------------------

  Future<void> upsertQueryResults({
    required String queryKey,
    required String entity,
    required List<Map<String, dynamic>> payload,
  }) async {
    final encoded = _encrypt(jsonEncode(payload));
    _db.execute(
      'INSERT OR REPLACE INTO cached_queries '
      '(query_key, entity, payload, updated_at) VALUES (?, ?, ?, ?)',
      [queryKey, entity, encoded, DateTime.now().toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>?> readQueryResults(String queryKey) async {
    final rows = _db.select(
      'SELECT payload FROM cached_queries WHERE query_key = ? LIMIT 1',
      [queryKey],
    );
    if (rows.isEmpty) return null;

    final raw = rows.first['payload'] as String?;
    if (raw == null || raw.isEmpty) return const [];

    final decrypted = _decrypt(raw);
    final decoded = jsonDecode(decrypted);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map((v) => Map<String, dynamic>.from(v.cast<String, dynamic>()))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Pending changes queue
  // ---------------------------------------------------------------------------

  Future<void> queueChange({
    required String entity,
    required String operation,
    required Map<String, dynamic> payload,
    String? recordId,
  }) async {
    final normalizedRecordId = _normalizeRecordId(recordId, payload);
    final createdAt = DateTime.now().toIso8601String();

    if (normalizedRecordId == null) {
      _db.execute(
        'INSERT INTO pending_changes '
        '(entity, operation, record_id, payload, created_at) VALUES (?, ?, ?, ?, ?)',
        [entity, operation, recordId, jsonEncode(payload), createdAt],
      );
      return;
    }

    final rows = _db.select(
      'SELECT id, operation FROM pending_changes '
      'WHERE entity = ? AND record_id = ? ORDER BY id DESC LIMIT 1',
      [entity, normalizedRecordId],
    );

    if (rows.isEmpty) {
      _db.execute(
        'INSERT INTO pending_changes '
        '(entity, operation, record_id, payload, created_at) VALUES (?, ?, ?, ?, ?)',
        [entity, operation, normalizedRecordId, jsonEncode(payload), createdAt],
      );
      return;
    }

    final existingId = rows.first['id'] as int;
    final existingOperation = rows.first['operation'] as String? ?? operation;

    // An insert followed by a delete means the record never reached the server;
    // cancel both sides so nothing is sent.
    if (existingOperation == 'insert' && operation == 'delete') {
      _db.execute('DELETE FROM pending_changes WHERE id = ?', [existingId]);
      return;
    }

    final nextOperation =
        existingOperation == 'insert' && operation != 'delete' ? 'insert' : operation;

    _db.execute(
      'UPDATE pending_changes '
      'SET operation = ?, record_id = ?, payload = ?, created_at = ? WHERE id = ?',
      [nextOperation, normalizedRecordId, jsonEncode(payload), createdAt, existingId],
    );
  }

  Future<List<OfflinePendingChange>> getPendingChanges() async {
    final rows = _db.select(
      'SELECT id, entity, operation, record_id, payload, created_at '
      'FROM pending_changes ORDER BY id ASC',
    );

    return rows.map((row) {
      return OfflinePendingChange(
        id: row['id'] as int,
        entity: row['entity'] as String,
        operation: row['operation'] as String,
        recordId: row['record_id'] as String?,
        payload: _decodeMap(row['payload'] as String?) ?? const <String, dynamic>{},
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> removePendingChange(int id) async {
    _db.execute('DELETE FROM pending_changes WHERE id = ?', [id]);
  }

  Future<int> pendingCount() async {
    final rows = _db.select('SELECT COUNT(*) AS total FROM pending_changes');
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<void> clearAllData() async {
    _db.execute('DELETE FROM pending_changes');
    _db.execute('DELETE FROM cached_queries');
    _db.execute('DELETE FROM cached_records');
  }

  void pruneStaleEntries() {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: _cacheTtlDays))
        .toIso8601String();

    _db.execute('DELETE FROM cached_records WHERE updated_at < ?', [cutoff]);
    _db.execute('DELETE FROM cached_queries WHERE updated_at < ?', [cutoff]);

    _db.execute('''
      DELETE FROM cached_records
      WHERE cache_key NOT IN (
        SELECT cache_key FROM cached_records
        ORDER BY updated_at DESC
        LIMIT $_maxCachedRecords
      )
    ''');
    _db.execute('''
      DELETE FROM cached_queries
      WHERE query_key NOT IN (
        SELECT query_key FROM cached_queries
        ORDER BY updated_at DESC
        LIMIT $_maxCachedQueries
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _recordCacheKey(String entity, String recordId) => '$entity::$recordId';

  String? _normalizeRecordId(String? recordId, Map<String, dynamic> payload) {
    final trimmed = recordId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final fromPayload = payload['id']?.toString().trim();
    if (fromPayload != null && fromPayload.isNotEmpty) return fromPayload;
    return null;
  }

  Map<String, dynamic>? _decodeMap(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    }
    return null;
  }
}
