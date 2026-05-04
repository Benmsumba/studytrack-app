import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_constants.dart';

class UpdateInfo {
  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
    version: (json['version'] as String?) ?? '0.0.0',
    build: (json['build'] as num?)?.toInt() ?? 0,
    apkUrl: (json['apk_url'] as String?) ?? '',
    releaseNotes: (json['release_notes'] as String?) ?? '',
  );
  const UpdateInfo({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.releaseNotes,
  });

  final String version;
  final int build;
  final String apkUrl;
  final String releaseNotes;
}

class SelfUpdateService {
  SelfUpdateService._();
  static final SelfUpdateService instance = SelfUpdateService._();

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  /// Returns [UpdateInfo] when a newer build is available, null otherwise.
  Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return null;

    final url = AppConstants.updateCheckUrl;
    if (url.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse(url), headers: {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final remote = UpdateInfo.fromJson(json);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (remote.build > currentBuild && remote.apkUrl.isNotEmpty) {
        return remote;
      }
      return null;
    } on Object catch (error) {
      debugPrint('SelfUpdateService.checkForUpdate error: $error');
      return null;
    }
  }

  /// Downloads the APK and launches the Android package installer.
  /// [onProgress] receives values 0.0–1.0 during the download.
  Future<bool> downloadAndInstall(
    UpdateInfo info, {
    ValueChanged<double>? onProgress,
  }) async {
    if (_isDownloading) return false;

    // Ensure the user has granted "Install unknown apps" for this app.
    final installPermission = await Permission.requestInstallPackages.status;
    if (!installPermission.isGranted) {
      final result = await Permission.requestInstallPackages.request();
      if (!result.isGranted) {
        await openAppSettings();
        return false;
      }
    }

    _isDownloading = true;
    try {
      final tempDir = await getTemporaryDirectory();
      final apkFile = File(
        '${tempDir.path}/studytrack_update_${info.build}.apk',
      );

      // Stream download so we can report progress.
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(info.apkUrl));
        final streamed = await client.send(request);

        if (streamed.statusCode != 200) return false;

        final total = streamed.contentLength ?? 0;
        var received = 0;
        final sink = apkFile.openWrite();

        await for (final chunk in streamed.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            onProgress?.call(received / total);
          }
        }
        await sink.flush();
        await sink.close();
      } finally {
        client.close();
      }

      onProgress?.call(1);

      final result = await OpenFile.open(apkFile.path);
      return result.type == ResultType.done;
    } on Object catch (error) {
      debugPrint('SelfUpdateService.downloadAndInstall error: $error');
      return false;
    } finally {
      _isDownloading = false;
    }
  }
}
