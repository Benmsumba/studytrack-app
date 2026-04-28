import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({SupabaseService? service})
    : _service = service ?? SupabaseService();

  final SupabaseService _service;

  bool isLoading = false;
  Map<String, dynamic>? profile;
  String? error;

  Future<void> refresh() async {
    final user = _service.getCurrentUser();
    if (user == null) {
      error = 'User not authenticated';
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      profile = await _service.getProfile(user.id);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
