import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_update_service.dart';

enum UpdateStatus {
  idle,
  available,
  downloading,
  awaitingPermission,
  readyToInstall,
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

  UpdateStatus get status => _status;
  AppUpdateInfo? get updateInfo => _updateInfo;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;

  bool get shouldShowOverlay =>
      _status == UpdateStatus.available ||
      _status == UpdateStatus.downloading ||
      _status == UpdateStatus.awaitingPermission ||
      _status == UpdateStatus.readyToInstall ||
      _status == UpdateStatus.error;

  Future<void> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionCode =
        int.tryParse(packageInfo.buildNumber) ?? AppConstants.currentVersionCode;

    final info = await _service.checkForUpdate(
      checkUrl: AppConstants.updateCheckUrl,
      currentVersionCode: currentVersionCode,
    );
    if (info == null) {
      return;
    }
    _updateInfo = info;
    _status = UpdateStatus.available;
    notifyListeners();
  }

  Future<void> startDownload() async {
    final info = _updateInfo;
    if (info == null) {
      return;
    }

    final hasPermission = await _requestInstallPermission();
    if (!hasPermission) {
      _status = UpdateStatus.awaitingPermission;
      notifyListeners();
      return;
    }

    _status = UpdateStatus.downloading;
    _progress = 0;
    notifyListeners();

    try {
      final savePath = await _service.apkSavePath;
      _apkPath = savePath;

      await for (final p in _service.downloadApk(info.downloadUrl, savePath)) {
        _progress = p;
        notifyListeners();
      }

      _status = UpdateStatus.readyToInstall;
      notifyListeners();

      await install();
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
      await _service.installApk(path);
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
}
