import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/core/services/app_update_service.dart';

void main() {
  group('AppUpdateInfo', () {
    test('parses latest.json aliases and optional flags', () {
      final info = AppUpdateInfo.fromJson({
        'version_code': 42,
        'version': '1.2.3',
        'download_url': 'https://example.com/app.apk',
        'release_notes': 'Bug fixes and polish',
        'changelog': 'Bug fixes and polish',
        'apk_sha256': 'abc123',
        'wifi_only': true,
      });

      expect(info.versionCode, 42);
      expect(info.versionName, '1.2.3');
      expect(info.downloadUrl, 'https://example.com/app.apk');
      expect(info.releaseNotes, 'Bug fixes and polish');
      expect(info.changelog, 'Bug fixes and polish');
      expect(info.apkSha256, 'abc123');
      expect(info.wifiOnly, isTrue);
    });
  });

  group('AppUpdateService integrity checks', () {
    late Directory tempDirectory;
    late AppUpdateService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'studytrack-update-',
      );
      service = AppUpdateService();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('verifies downloaded APK hash before install', () async {
      final apkFile = File('${tempDirectory.path}/studytrack.apk');
      await apkFile.writeAsString('studytrack-apk');

      final expectedHash = await service.calculateFileSha256(apkFile.path);
      await service.verifyDownloadedApk(
        filePath: apkFile.path,
        expectedSha256: expectedHash,
      );

      expect(
        () => service.verifyDownloadedApk(
          filePath: apkFile.path,
          expectedSha256: 'deadbeef',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
