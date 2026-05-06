import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/constants/app_constants.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/user_model.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

class AuthCommandResult {
  const AuthCommandResult({
    required this.success,
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  final bool success;
  final int statusCode;
  final String message;
  final String? errorCode;
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? getIt<AuthRepository>() {
    _bindAuthStateStream();
    unawaited(refreshCurrentUser(silent: true));
  }

  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _authSubscription;

  ProfileModel? _currentUser;
  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get errorMessage => _errorMessage;

  Future<AuthCommandResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final emailError = _validateEmail(normalizedEmail);
    if (emailError != null) return _validationFailure(emailError);
    if (password.isEmpty) return _validationFailure('Password is required.');

    _setLoading(true);
    _clearError();

    final result = await _authRepository.signInWithEmail(
      email: normalizedEmail,
      password: password,
    );
    return _handleProfileCommand(
      result,
      successStatusCode: 200,
      successMessage: 'Signed in successfully.',
    );
  }

  Future<AuthCommandResult> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    final result = await _authRepository.signInWithGoogle();
    return _handleVoidCommand(
      result,
      successStatusCode: 200,
      successMessage: 'Google sign-in started.',
      keepLoadingUntilAuthSync: true,
    );
  }

  Future<AuthCommandResult> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (!AppConstants.isSupabaseConfigured) {
      return _validationFailure(
        'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY first.',
      );
    }

    final trimmedName = fullName.trim();
    final normalizedEmail = email.trim();

    if (trimmedName.isEmpty) return _validationFailure('Full name is required.');
    final emailError = _validateEmail(normalizedEmail);
    if (emailError != null) return _validationFailure(emailError);
    if (password.length < 8) {
      return _validationFailure('Use at least 8 characters for your password.');
    }

    _setLoading(true);
    _clearError();

    final result = await _authRepository.signUpWithEmail(
      email: normalizedEmail,
      password: password,
      fullName: trimmedName,
      course: 'Not set yet',
      yearLevel: 1,
      studyStyle: 'evening',
      sessionsPerWeek: 2,
      preferredStudyMethod: 'alone',
    );
    return _handleProfileCommand(
      result,
      successStatusCode: 201,
      successMessage: 'Account created successfully.',
    );
  }

  Future<AuthCommandResult> sendOtp(String email) async {
    final normalizedEmail = email.trim();
    final emailValidation = _validateEmail(normalizedEmail);
    if (emailValidation != null) {
      return _validationFailure(emailValidation);
    }

    _setLoading(true);
    _clearError();

    final result = await _authRepository!.sendOtp(normalizedEmail);
    return _handleVoidCommand(
      result,
      successStatusCode: 200,
      successMessage: 'OTP sent. Check your inbox.',
    );
  }

  Future<AuthCommandResult> verifyOtpCode({
    required String email,
    required String otp,
  }) async {
    if (otp.trim().isEmpty) {
      return _validationFailure('Enter the code from your email.');
    }

    _setLoading(true);
    _clearError();

    final result = await _authRepository!.verifyOtp(
      email: email.trim(),
      otp: otp.trim(),
    );

    return _handleProfileCommand(
      result,
      successStatusCode: 200,
      successMessage: 'Signed in successfully.',
    );
  }

  Future<AuthCommandResult> resetPassword(String email) async {
    final normalizedEmail = email.trim();
    final emailError = _validateEmail(normalizedEmail);
    if (emailError != null) return _validationFailure(emailError);

    _setLoading(true);
    _clearError();

    final result = await _authRepository.resetPassword(normalizedEmail);
    return _handleVoidCommand(
      result,
      successStatusCode: 200,
      successMessage: 'Password reset link sent. Check your inbox.',
    );
  }

  /// Optimistic UI: clears session immediately, restores on failure.
  Future<AuthCommandResult> logout() async {
    final snapshot = _currentUser;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();

    _setLoading(true);
    _clearError();

    final result = await _authRepository.signOut();

    return result.fold(
      (error) {
        _currentUser = snapshot;
        _status = snapshot == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated;
        _setFailure(error);
        _setLoading(false);
        return AuthCommandResult(
          success: false,
          statusCode: _statusCodeFromException(error),
          message: error.message,
          errorCode: error.code,
        );
      },
      (_) {
        _setLoading(false);
        return const AuthCommandResult(
          success: true,
          statusCode: 200,
          message: 'Signed out successfully.',
        );
      },
    );
  }

  Future<void> refreshCurrentUser({bool silent = false}) async {
    if (!silent) {
      _setLoading(true);
      _clearError();
    }

    final result = await _authRepository.getCurrentUser();
    switch (result) {
      case Success(data: final profile):
        _currentUser = profile;
        _status = profile == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated;
      case Failure(error: final error):
        _setFailure(error);
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
    }

    if (!silent) {
      _setLoading(false);
    } else {
      notifyListeners();
    }
  }

  // Thin aliases kept for callers that use the old names.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String course = 'Not set yet',
    int yearLevel = 1,
  }) => signUpWithEmail(fullName: fullName, email: email, password: password);

  Future<void> login({required String email, required String password}) =>
      signInWithEmail(email: email, password: password);

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

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _bindAuthStateStream() {
    if (!AppConstants.isSupabaseConfigured) {
      _status = AuthStatus.unauthenticated;
      return;
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (event) {
        if (event.session == null) {
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
          _isLoading = false;
          notifyListeners();
          return;
        }
        unawaited(refreshCurrentUser(silent: true));
      },
    );
  }

  AuthCommandResult _handleProfileCommand(
    Result<ProfileModel> result, {
    required int successStatusCode,
    required String successMessage,
  }) => result.fold(
    (error) {
      _setFailure(error);
      _setLoading(false);
      return AuthCommandResult(
        success: false,
        statusCode: _statusCodeFromException(error),
        message: error.message,
        errorCode: error.code,
      );
    },
    (profile) {
      _currentUser = profile;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return AuthCommandResult(
        success: true,
        statusCode: successStatusCode,
        message: successMessage,
      );
    },
  );

  AuthCommandResult _handleVoidCommand(
    Result<void> result, {
    required int successStatusCode,
    required String successMessage,
    bool keepLoadingUntilAuthSync = false,
  }) => result.fold(
    (error) {
      _setFailure(error);
      _setLoading(false);
      return AuthCommandResult(
        success: false,
        statusCode: _statusCodeFromException(error),
        message: error.message,
        errorCode: error.code,
      );
    },
    (_) {
      if (!keepLoadingUntilAuthSync) _setLoading(false);
      return AuthCommandResult(
        success: true,
        statusCode: successStatusCode,
        message: successMessage,
      );
    },
  );

  AuthCommandResult _validationFailure(String message) {
    _errorMessage = message;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return AuthCommandResult(
      success: false,
      statusCode: 422,
      message: message,
      errorCode: 'VALIDATION_ERROR',
    );
  }

  void _setFailure(AppException error) {
    _errorMessage = error.message;
    // Only force unauthenticated for actual auth failures.
    // Data/network errors must not kill an authenticated session.
    if (error is AuthException) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required.';
    final regex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email) ? null : 'Enter a valid email address.';
  }

  int _statusCodeFromException(AppException error) => switch (error) {
    ValidationException() => 422,
    AuthException() => 401,
    OfflineException() => 503,
    DataException() => 500,
    AppGenericException() => 500,
    _ => 500,
  };

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _status = AuthStatus.loading;
    notifyListeners();
  }
}
