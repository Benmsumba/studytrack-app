import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  final SupabaseService _supabaseService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _supabaseService.signInWithEmail(email, password);
      if (user == null) {
        _errorMessage =
            _supabaseService.lastAuthError ??
            'Unable to login. Please check your credentials.';
        return false;
      }
      return true;
    } catch (error) {
      _errorMessage = 'Login failed: $error';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final ok = await _supabaseService.signInWithGoogle();
      if (!ok) {
        _errorMessage =
            _supabaseService.lastAuthError ?? 'Google sign-in failed.';
      }
      return ok;
    } catch (error) {
      _errorMessage = 'Google sign-in failed: $error';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (!AppConstants.isSupabaseConfigured) {
      _errorMessage =
          'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY first.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _supabaseService.signUpWithEmail(
        email,
        password,
        fullName,
        'Not set yet',
        1,
        'evening',
        2,
        'alone',
      );

      if (user == null) {
        _errorMessage =
            _supabaseService.lastAuthError ??
            'Unable to create account. Please try again.';
        return false;
      }

      return true;
    } catch (error) {
      _errorMessage = 'Sign up failed: $error';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  double passwordStrength(String password) {
    if (password.isEmpty) return 0;

    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    return score / 5;
  }

  String passwordStrengthLabel(String password) {
    final strength = passwordStrength(password);

    if (strength == 0) return 'Enter a password';
    if (strength <= 0.2) return 'Very weak';
    if (strength <= 0.4) return 'Weak';
    if (strength <= 0.6) return 'Fair';
    if (strength <= 0.8) return 'Strong';
    return 'Very strong';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
