import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.changelog,
    required this.apkSha256,
    required this.wifiOnly,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
    versionCode: _readInt(json, const ['versionCode', 'version_code', 'build']),
    versionName: _readString(json, const [
      'versionName',
      'version_name',
      'version',
    ]),
    downloadUrl: _readString(json, const [
      'downloadUrl',
      'download_url',
      'apkUrl',
      'apk_url',
    ]),
    releaseNotes: _readString(json, const ['releaseNotes', 'release_notes']),
    changelog: _readString(json, const ['changelog', 'release_notes']),
    apkSha256: _readString(json, const [
      'apkSha256',
      'apk_sha256',
      'sha256',
      'download_sha256',
    ]),
    wifiOnly: _readBool(json, const ['wifiOnly', 'wifi_only']),
  );

  final int versionCode;
  final String versionName;
  final String downloadUrl;
  final String releaseNotes;
  final String changelog;
  final String apkSha256;
  final bool wifiOnly;
}

class AppUpdateService {
  static const _channel = MethodChannel('com.studytrack.app/installer');

  Future<AppUpdateInfo?> checkForUpdate({
    required String checkUrl,
    required int currentVersionCode,
  }) async {
    if (checkUrl.isEmpty || checkUrl == 'YOUR_UPDATE_CHECK_URL') {
      debugPrint('[AppUpdateService] Update check skipped: empty or placeholder URL');
      return null;
    }
    final client = HttpClient();
    try {
      debugPrint('[AppUpdateService] Fetching update manifest from: $checkUrl');
      final request = await client.getUrl(Uri.parse(checkUrl));
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response = await request.close();
      debugPrint('[AppUpdateService] HTTP response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw HttpException(
          'Unable to fetch update manifest (${response.statusCode}).',
          uri: Uri.parse(checkUrl),
        );
      }
      final body = await response.transform(utf8.decoder).join();
      debugPrint('[AppUpdateService] Manifest body: $body');
      
      final json = jsonDecode(body);
      if (json is! Map) {
        throw const FormatException('Update manifest must be a JSON object.');
      }
      final info = AppUpdateInfo.fromJson(Map<String, dynamic>.from(json));
      debugPrint('[AppUpdateService] Parsed manifest: versionCode=${info.versionCode}, versionName=${info.versionName}');
      
      if (info.versionCode <= currentVersionCode) {
        debugPrint('[AppUpdateService] No update needed: remote versionCode ${info.versionCode} ≤ current $currentVersionCode');
        return null;
      }
      if (info.downloadUrl.isEmpty) {
        throw const FormatException('Update manifest is missing downloadUrl.');
      }
      debugPrint('[AppUpdateService] Update available! versionCode: ${info.versionCode}, downloadUrl: ${info.downloadUrl}');
      return info;
    } on Exception catch (e) {
      debugPrint('[AppUpdateService] Update check failed: $e');
      debugPrint('[AppUpdateService] Exception type: ${e.runtimeType}');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Streams download progress from 0.0 to 1.0.
  /// Yields values as bytes arrive; yields exactly 1.0 when done.
  Stream<double> downloadApk(String url, String savePath) async* {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException(
          'APK download failed (${response.statusCode}).',
          uri: Uri.parse(url),
        );
      }
      final total = response.contentLength;
      var received = 0;
      final file = File(savePath);
      final sink = file.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          yield received / total;
        }
      }
      await sink.flush();
      await sink.close();
    } on Exception catch (e) {
      debugPrint('APK download failed: $e');
      rethrow;
    } finally {
      client.close();
    }
    yield 1.0;
  }

  Future<void> verifyDownloadedApk({
    required String filePath,
    required String expectedSha256,
  }) async {
    if (expectedSha256.isEmpty) {
      return;
    }

    final digest = await calculateFileSha256(filePath);
    if (digest != expectedSha256.toLowerCase()) {
      throw StateError('Downloaded APK failed integrity verification.');
    }
  }

  Future<String> calculateFileSha256(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<void> installApk(String filePath) async {
    await _channel.invokeMethod<void>('installApk', <String, String>{
      'filePath': filePath,
    });
  }

  Future<String> get apkSavePath async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/studytrack_update.apk';
  }
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return 0;
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
  }
  return false;
}
