import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
    versionCode: json['versionCode'] as int,
    versionName: json['versionName'] as String? ?? '',
    downloadUrl: json['downloadUrl'] as String,
    releaseNotes: json['releaseNotes'] as String? ?? '',
  );

  final int versionCode;
  final String versionName;
  final String downloadUrl;
  final String releaseNotes;
}

class AppUpdateService {
  static const _channel = MethodChannel('com.studytrack.app/installer');

  Future<AppUpdateInfo?> checkForUpdate({
    required String checkUrl,
    required int currentVersionCode,
  }) async {
    if (checkUrl.isEmpty || checkUrl == 'YOUR_UPDATE_CHECK_URL') {
      return null;
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(checkUrl));
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final info = AppUpdateInfo.fromJson(json);
      if (info.versionCode <= currentVersionCode) {
        return null;
      }
      return info;
    } on Exception catch (e) {
      debugPrint('Update check failed: $e');
      return null;
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
      final response = await request.close();
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

  Future<void> installApk(String filePath) async {
    await _channel.invokeMethod<void>(
      'installApk',
      <String, String>{'filePath': filePath},
    );
  }

  Future<String> get apkSavePath async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/studytrack_update.apk';
  }
}
