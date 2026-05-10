import 'dart:io';
import '../../../core/utils/app_logger.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_update_service.dart';

enum UpdateStatus {
  idle,
  available,
  downloading,
  verifying,
  awaitingPermission,
  readyToInstall,
  installing,
  error,
}

class UpdateProvider extends ChangeNotifier {
  UpdateProvider(this._service);

  final AppUpdateService _service;

  UpdateStatus _status = UpdateStatus.idle;
  AppUpdateInfo? _updateInfo;
  double _progress = 0;
  String? _errorMessage;
  String? _apkPath;
  bool _wifiOnly = false;

  UpdateStatus get status => _status;
  AppUpdateInfo? get updateInfo => _updateInfo;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  bool get wifiOnly => _wifiOnly;

  bool get shouldShowOverlay =>
      _status == UpdateStatus.available ||
      _status == UpdateStatus.downloading ||
      _status == UpdateStatus.verifying ||
      _status == UpdateStatus.awaitingPermission ||
      _status == UpdateStatus.readyToInstall ||
      _status == UpdateStatus.installing ||
      _status == UpdateStatus.error;

  Future<void> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      AppLogger.debug(
        '[Update] Update check skipped: Web or non-Android platform',
      );
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // Parse buildNumber carefully - should be numeric
      int currentVersionCode;
      if (packageInfo.buildNumber.isEmpty) {
        AppLogger.debug(
          '[Update] WARNING: PackageInfo.buildNumber is empty, using fallback ${AppConstants.currentVersionCode}',
        );
        currentVersionCode = AppConstants.currentVersionCode;
      } else {
        final parsed = int.tryParse(packageInfo.buildNumber);
        if (parsed == null) {
          AppLogger.debug(
            '[Update] WARNING: PackageInfo.buildNumber "${packageInfo.buildNumber}" is not a valid integer',
          );
          currentVersionCode = AppConstants.currentVersionCode;
        } else {
          currentVersionCode = parsed;
        }
      }

      final checkUrl = AppConstants.updateCheckUrl;
      AppLogger.debug('[Update] =================================');
      AppLogger.debug('[Update] Starting update check...');
      AppLogger.debug('[Update] Current app:');
      AppLogger.debug('[Update]   - versionCode=$currentVersionCode');
      AppLogger.debug('[Update]   - buildNumber="${packageInfo.buildNumber}"');
      AppLogger.debug('[Update]   - appVersion="${packageInfo.version}"');
      AppLogger.debug('[Update] Check URL: $checkUrl');

      try {
        final info = await _service.checkForUpdate(
          checkUrl: checkUrl,
          currentVersionCode: currentVersionCode,
        );

        if (info == null) {
          AppLogger.debug('[Update] No new version available');
          AppLogger.debug('[Update] =================================');
          return;
        }

        AppLogger.debug('[Update] ✓ NEW VERSION DETECTED! ✓');
        AppLogger.debug('[Update] Remote:');
        AppLogger.debug('[Update]   - versionCode=${info.versionCode}');
        AppLogger.debug('[Update]   - versionName=${info.versionName}');
        AppLogger.debug('[Update] Download URL: ${info.downloadUrl}');

        _updateInfo = info;
        _wifiOnly = info.wifiOnly;
        _status = UpdateStatus.available;
        _errorMessage = null;
        notifyListeners();
        AppLogger.debug('[Update] Update status changed to: AVAILABLE');
        AppLogger.debug('[Update] =================================');
      } on SocketException catch (e) {
        _status = UpdateStatus.error;
        _errorMessage = 'Network error. Check your internet connection.';
        notifyListeners();
        AppLogger.warning('[Update] ✗ NETWORK ERROR', error: e);
        AppLogger.debug('[Update] =================================');
      } on HttpException catch (e) {
        _status = UpdateStatus.error;
        _errorMessage = 'Unable to fetch updates (HTTP error).';
        notifyListeners();
        AppLogger.warning('[Update] ✗ HTTP ERROR', error: e);
        AppLogger.debug('[Update] =================================');
      } on FormatException catch (e) {
        _status = UpdateStatus.error;
        _errorMessage = 'Invalid update metadata format.';
        notifyListeners();
        AppLogger.warning('[Update] ✗ FORMAT ERROR', error: e);
        AppLogger.debug('[Update] =================================');
      } on Object catch (error, stackTrace) {
        _status = UpdateStatus.error;
        _errorMessage = 'Update check failed.';
        notifyListeners();
        AppLogger.warning('[Update] ✗ UNEXPECTED ERROR', error: error);
        AppLogger.warning('[Update] Stack trace', error: stackTrace);
        AppLogger.debug('[Update] =================================');
      }
    } on Object catch (e) {
      AppLogger.warning('[Update] ✗ FAILED TO GET PACKAGE INFO', error: e);
      _status = UpdateStatus.error;
      _errorMessage = 'Unable to check app version.';
      notifyListeners();
    }
  }

  Future<void> startDownload() async {
    final info = _updateInfo;
    if (info == null) {
      return;
    }

    final hasPermission = await _requestInstallPermission();
    if (!hasPermission) {
      _status = UpdateStatus.awaitingPermission;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (_wifiOnly && !await _isOnWifi()) {
      _status = UpdateStatus.error;
      _errorMessage =
          'Wi-Fi is required for this update. Connect to Wi-Fi and try again.';
      notifyListeners();
      return;
    }

    _status = UpdateStatus.downloading;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final savePath = await _service.apkSavePath;
      _apkPath = savePath;

      await for (final p in _service.downloadApk(info.downloadUrl, savePath)) {
        _progress = p;
        notifyListeners();
      }

      _status = UpdateStatus.verifying;
      notifyListeners();

      await _service.verifyDownloadedApk(
        filePath: savePath,
        expectedSha256: info.apkSha256,
      );

      _status = UpdateStatus.readyToInstall;
      notifyListeners();
    } on Exception catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> install() async {
    final path = _apkPath;
    if (path == null) {
      return;
    }

    try {
      _status = UpdateStatus.installing;
      notifyListeners();
      await _service.installApk(path);
      _status = UpdateStatus.idle;
      _errorMessage = null;
      notifyListeners();
    } on Exception catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> retryAfterPermission() async {
    final granted = await _requestInstallPermission();
    if (granted) {
      await startDownload();
    }
  }

  Future<void> retry() async {
    if (_updateInfo == null) {
      await checkForUpdate();
      return;
    }
    await startDownload();
  }

  // ignore: avoid_positional_boolean_parameters
  void setWifiOnly(bool value) {
    _wifiOnly = value;
    notifyListeners();
  }

  void dismiss() {
    _status = UpdateStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _requestInstallPermission() async {
    if (!defaultTargetPlatform.toString().contains('android')) {
      return true;
    }
    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) {
      return true;
    }
    final result = await Permission.requestInstallPackages.request();
    return result.isGranted;
  }

  Future<bool> _isOnWifi() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }
}
