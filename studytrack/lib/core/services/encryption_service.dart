import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Production-grade encryption service for offline cache security
/// Uses AES-256 encryption with secure key management via flutter_secure_storage
class EncryptionService {
  factory EncryptionService() => _instance;

  EncryptionService._internal() : _secureStorage = const FlutterSecureStorage();
  static final EncryptionService _instance = EncryptionService._internal();

  final FlutterSecureStorage _secureStorage;
  late encrypt_lib.Key _encryptionKey;
  late encrypt_lib.IV _iv;
  bool _initialized = false;

  static const String _keyStorageKey = 'app_encryption_key';
  static const String _ivStorageKey = 'app_encryption_iv';
  static const int _keyLength = 32; // 256-bit key

  /// Initialize encryption service with secure key management
  Future<void> initialize({String? customKey}) async {
    if (_initialized) return;

    try {
      // Retrieve or generate encryption key from secure storage
      final storedKey = await _secureStorage.read(key: _keyStorageKey);
      final storedIv = await _secureStorage.read(key: _ivStorageKey);

      if (storedKey != null && storedIv != null) {
        // Use stored key
        _encryptionKey = encrypt_lib.Key.fromBase64(storedKey);
        _iv = encrypt_lib.IV.fromBase64(storedIv);
      } else {
        // Generate new key and IV
        _encryptionKey = encrypt_lib.Key.fromSecureRandom(_keyLength);
        _iv = encrypt_lib.IV.fromSecureRandom(16);

        // Store key and IV securely
        await _secureStorage.write(
          key: _keyStorageKey,
          value: _encryptionKey.base64,
        );
        await _secureStorage.write(key: _ivStorageKey, value: _iv.base64);
      }

      _initialized = true;
      debugPrint('EncryptionService initialized with AES-256');
    } catch (e) {
      debugPrint('EncryptionService initialization failed: $e');
      rethrow;
    }
  }

  /// Check if encryption is initialized
  bool get isInitialized => _initialized;

  /// Encrypt sensitive data using AES-256
  String encryptString(String plaintext) {
    if (!_initialized) {
      throw Exception('EncryptionService not initialized');
    }

    try {
      final cipher = encrypt_lib.Encrypter(
        encrypt_lib.AES(_encryptionKey, mode: encrypt_lib.AESMode.cbc),
      );
      final encrypted = cipher.encrypt(plaintext, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption failed: $e');
      rethrow;
    }
  }

  /// Decrypt sensitive data using AES-256
  String decryptString(String encryptedData) {
    if (!_initialized) {
      throw Exception('EncryptionService not initialized');
    }

    try {
      final cipher = encrypt_lib.Encrypter(
        encrypt_lib.AES(_encryptionKey, mode: encrypt_lib.AESMode.cbc),
      );
      final decrypted = cipher.decrypt64(encryptedData, iv: _iv);
      return decrypted;
    } catch (e) {
      debugPrint('Decryption failed: $e');
      rethrow;
    }
  }

  /// Encrypt a map of data, optionally specifying which keys to encrypt
  Map<String, dynamic> encryptMap(
    Map<String, dynamic> data, {
    List<String>? keysToEncrypt,
  }) {
    try {
      final result = <String, dynamic>{};

      data.forEach((key, value) {
        if (value == null) {
          result[key] = null;
        } else if ((keysToEncrypt?.contains(key) ?? false) && value is String) {
          // Encrypt this field
          result[key] = encryptString(value);
        } else {
          // Keep as-is
          result[key] = value;
        }
      });

      return result;
    } catch (e) {
      debugPrint('Map encryption failed: $e');
      rethrow;
    }
  }

  /// Decrypt a map of data
  Map<String, dynamic> decryptMap(
    Map<String, dynamic> data, {
    List<String>? keysToDecrypt,
  }) {
    try {
      final result = <String, dynamic>{};

      data.forEach((key, value) {
        if (value == null) {
          result[key] = null;
        } else if ((keysToDecrypt?.contains(key) ?? false) && value is String) {
          // Decrypt this field
          try {
            result[key] = decryptString(value);
          } catch (_) {
            // If decryption fails, keep original value
            result[key] = value;
          }
        } else {
          // Keep as-is
          result[key] = value;
        }
      });

      return result;
    } catch (e) {
      debugPrint('Map decryption failed: $e');
      rethrow;
    }
  }

  /// Generate a hash for data integrity verification
  String hashData(String data) => sha256.convert(utf8.encode(data)).toString();

  /// Verify data integrity using hash
  bool verifyDataIntegrity(String data, String hash) => hashData(data) == hash;

  /// Sensitive fields that should always be encrypted in offline cache
  static const List<String> sensitiveFields = [
    'password',
    'email',
    'phone',
    'auth_token',
    'refresh_token',
    'user_id',
    'personal_note',
    'access_token',
    'session_token',
  ];

  /// Clear all stored encryption keys (use with caution)
  Future<void> clearKeys() async {
    try {
      await _secureStorage.delete(key: _keyStorageKey);
      await _secureStorage.delete(key: _ivStorageKey);
      _initialized = false;
      debugPrint('Encryption keys cleared');
    } catch (e) {
      debugPrint('Failed to clear encryption keys: $e');
      rethrow;
    }
  }
}
