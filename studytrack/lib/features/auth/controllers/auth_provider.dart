import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  final SupabaseService _supabaseService;

  ProfileModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String course = 'Not set yet',
    int yearLevel = 1,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _supabaseService.signUpWithEmail(
        email,
        password,
        fullName,
        course,
        yearLevel,
        'evening',
        2,
        'alone',
      );

      if (user == null) {
        _errorMessage =
            _supabaseService.lastAuthError ?? 'Unable to create account.';
        return;
      }

      await _loadCurrentProfile(user.id);
    } catch (error) {
      _errorMessage = 'Registration failed: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _supabaseService.signInWithEmail(email, password);
      if (user == null) {
        _errorMessage = _supabaseService.lastAuthError ?? 'Login failed.';
        return;
      }

      await _loadCurrentProfile(user.id);
    } catch (error) {
      _errorMessage = 'Login failed: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _supabaseService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Logout failed: $error';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCurrentUser() async {
    final user = _supabaseService.getCurrentUser();
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    await _loadCurrentProfile(user.id);
  }

  Future<void> _loadCurrentProfile(String userId) async {
    final profile = await _supabaseService.getProfile(userId);
    if (profile == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    _currentUser = ProfileModel.fromJson(profile);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
