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
    if (!kReleaseMode) {
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionCode =
        int.tryParse(packageInfo.buildNumber) ??
        AppConstants.currentVersionCode;

    try {
      final info = await _service.checkForUpdate(
        checkUrl: AppConstants.updateCheckUrl,
        currentVersionCode: currentVersionCode,
      );
      if (info == null) {
        return;
      }

      _updateInfo = info;
      _wifiOnly = info.wifiOnly;
      _status = UpdateStatus.available;
      _errorMessage = null;
      notifyListeners();
    } on Object catch (error) {
      _status = UpdateStatus.error;
      _errorMessage = 'Unable to check for updates right now.';
      notifyListeners();
      debugPrint('Update check failed: $error');
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
