import 'package:flutter/foundation.dart';

import '../../../core/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
    : _service = service ?? NotificationService();

  final NotificationService _service;

  bool _isBootstrapping = false;
  bool get isBootstrapping => _isBootstrapping;

  Future<void> refreshSchedules() async {
    _isBootstrapping = true;
    notifyListeners();
    try {
      await _service.bootstrapForCurrentUser();
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }
}
