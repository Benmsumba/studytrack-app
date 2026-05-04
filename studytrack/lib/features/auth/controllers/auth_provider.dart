import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/constants/app_constants.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/services/supabase_service.dart';
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
  AuthProvider({
    AuthRepository? authRepository,
    SupabaseService? supabaseService,
  }) : _authRepository =
           authRepository ??
           (supabaseService == null ? getIt<AuthRepository>() : null),
       _legacySupabaseService = supabaseService {
    _bindAuthStateStream();
    unawaited(refreshCurrentUser(silent: true));
  }

  final AuthRepository? _authRepository;
  final SupabaseService? _legacySupabaseService;
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
    if (_legacySupabaseService != null) {
      return _legacySignInWithEmail(email: email, password: password);
    }

    final normalizedEmail = email.trim();
    final emailValidation = _validateEmail(normalizedEmail);
    if (emailValidation != null) {
      return _validationFailure(emailValidation);
    }
    if (password.isEmpty) {
      return _validationFailure('Password is required.');
    }

    _setLoading(true);
    _clearError();

    final result = await _authRepository!.signInWithEmail(
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
    if (_legacySupabaseService != null) {
      return _legacySignInWithGoogle();
    }

    _setLoading(true);
    _clearError();

    final result = await _authRepository!.signInWithGoogle();

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
    if (_legacySupabaseService != null) {
      return _legacySignUpWithEmail(
        fullName: fullName,
        email: email,
        password: password,
      );
    }

    if (!AppConstants.isSupabaseConfigured) {
      return _validationFailure(
        'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY first.',
      );
    }

    final trimmedName = fullName.trim();
    final normalizedEmail = email.trim();

    if (trimmedName.isEmpty) {
      return _validationFailure('Full name is required.');
    }
    final emailValidation = _validateEmail(normalizedEmail);
    if (emailValidation != null) {
      return _validationFailure(emailValidation);
    }
    if (password.length < 8) {
      return _validationFailure('Use at least 8 characters for your password.');
    }

    _setLoading(true);
    _clearError();

    final result = await _authRepository!.signUpWithEmail(
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
    if (_legacySupabaseService != null) {
      return _legacyResetPassword(email);
    }

    final normalizedEmail = email.trim();
    final emailValidation = _validateEmail(normalizedEmail);
    if (emailValidation != null) {
      return _validationFailure(emailValidation);
    }

    _setLoading(true);
    _clearError();

    final result = await _authRepository!.resetPassword(normalizedEmail);
    return _handleVoidCommand(
      result,
      successStatusCode: 200,
      successMessage: 'Password reset link sent. Check your inbox.',
    );
  }

  Future<AuthCommandResult> logout() async {
    if (_legacySupabaseService != null) {
      return _legacyLogout();
    }

    final snapshot = _currentUser;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();

    _setLoading(true);
    _clearError();

    final result = await _authRepository!.signOut();
    if (result is Success<void>) {
      _setLoading(false);
      return const AuthCommandResult(
        success: true,
        statusCode: 200,
        message: 'Signed out successfully.',
      );
    }

    _currentUser = snapshot;
    _status = snapshot == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    _setFailure((result as Failure<void>).error);
    _setLoading(false);

    return AuthCommandResult(
      success: false,
      statusCode: _statusCodeFromException(result.error),
      message: _errorMessage ?? 'Failed to sign out.',
      errorCode: result.error.code,
    );
  }

  Future<void> refreshCurrentUser({bool silent = false}) async {
    if (_legacySupabaseService != null) {
      await _legacyRefreshCurrentUser(silent: silent);
      return;
    }

    if (!silent) {
      _setLoading(true);
      _clearError();
    }

    final result = await _authRepository!.getCurrentUser();
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

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String course = 'Not set yet',
    int yearLevel = 1,
  }) async {
    await signUpWithEmail(fullName: fullName, email: email, password: password);
  }

  Future<void> login({required String email, required String password}) async {
    await signInWithEmail(email: email, password: password);
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

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _bindAuthStateStream() {
    if (!AppConstants.isSupabaseConfigured) {
      _status = AuthStatus.unauthenticated;
      return;
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      final session = event.session;
      if (session == null) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
        return;
      }

      unawaited(refreshCurrentUser(silent: true));
    });
  }

  AuthCommandResult _handleProfileCommand(
    Result<ProfileModel> result, {
    required int successStatusCode,
    required String successMessage,
  }) {
    if (result is Success<ProfileModel>) {
      _currentUser = result.data;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return AuthCommandResult(
        success: true,
        statusCode: successStatusCode,
        message: successMessage,
      );
    }

    final failure = result as Failure<ProfileModel>;
    _setFailure(failure.error);
    _setLoading(false);
    return AuthCommandResult(
      success: false,
      statusCode: _statusCodeFromException(failure.error),
      message: _errorMessage ?? 'Authentication request failed.',
      errorCode: failure.error.code,
    );
  }

  AuthCommandResult _handleVoidCommand(
    Result<void> result, {
    required int successStatusCode,
    required String successMessage,
    bool keepLoadingUntilAuthSync = false,
  }) {
    if (result is Success<void>) {
      if (!keepLoadingUntilAuthSync) {
        _setLoading(false);
      }
      return AuthCommandResult(
        success: true,
        statusCode: successStatusCode,
        message: successMessage,
      );
    }

    final failure = result as Failure<void>;
    _setFailure(failure.error);
    _setLoading(false);
    return AuthCommandResult(
      success: false,
      statusCode: _statusCodeFromException(failure.error),
      message: _errorMessage ?? 'Authentication request failed.',
      errorCode: failure.error.code,
    );
  }

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
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required.';
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email)) return 'Enter a valid email address.';
    return null;
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
    if (value) {
      _status = AuthStatus.loading;
    }
    notifyListeners();
  }

  Future<AuthCommandResult> _legacySignUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final service = _legacySupabaseService!;
    _setLoading(true);
    _clearError();

    try {
      final user = await service.signUpWithEmail(
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
        _errorMessage = service.lastAuthError ?? 'Unable to create account.';
        _status = AuthStatus.unauthenticated;
        _setLoading(false);
        return AuthCommandResult(
          success: false,
          statusCode: 401,
          message: _errorMessage!,
          errorCode: 'AUTH_ERROR',
        );
      }

      _currentUser = null;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return const AuthCommandResult(
        success: true,
        statusCode: 201,
        message: 'Account created successfully.',
      );
    } catch (error) {
      debugPrint('register error: $error');
      _setLoading(false);
      _errorMessage = 'Registration failed: $error';
      return AuthCommandResult(
        success: false,
        statusCode: 500,
        message: _errorMessage!,
      );
    }
  }

  Future<AuthCommandResult> _legacySignInWithEmail({
    required String email,
    required String password,
  }) async {
    final service = _legacySupabaseService!;
    _setLoading(true);
    _clearError();

    try {
      final user = await service.signInWithEmail(email, password);
      if (user == null) {
        _errorMessage = service.lastAuthError ?? 'Login failed.';
        _status = AuthStatus.unauthenticated;
        _setLoading(false);
        return AuthCommandResult(
          success: false,
          statusCode: 401,
          message: _errorMessage!,
          errorCode: 'AUTH_ERROR',
        );
      }

      _currentUser = null;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return const AuthCommandResult(
        success: true,
        statusCode: 200,
        message: 'Signed in successfully.',
      );
    } catch (error) {
      debugPrint('login error: $error');
      _setLoading(false);
      _errorMessage = 'Login failed: $error';
      return AuthCommandResult(
        success: false,
        statusCode: 500,
        message: _errorMessage!,
      );
    }
  }

  Future<AuthCommandResult> _legacySignInWithGoogle() async {
    final service = _legacySupabaseService!;
    _setLoading(true);
    _clearError();

    try {
      final ok = await service.signInWithGoogle();
      if (!ok) {
        _errorMessage = service.lastAuthError ?? 'Google sign-in failed.';
        _status = AuthStatus.unauthenticated;
        _setLoading(false);
        return AuthCommandResult(
          success: false,
          statusCode: 401,
          message: _errorMessage!,
          errorCode: 'AUTH_ERROR',
        );
      }

      _status = AuthStatus.authenticated;
      _setLoading(false);
      return const AuthCommandResult(
        success: true,
        statusCode: 200,
        message: 'Google sign-in started.',
      );
    } catch (error) {
      debugPrint('GoogleSignIn error: $error');
      _setLoading(false);
      _errorMessage = 'Google sign-in failed: $error';
      return AuthCommandResult(
        success: false,
        statusCode: 500,
        message: _errorMessage!,
      );
    }
  }

  Future<AuthCommandResult> _legacyResetPassword(String email) async {
    final service = _legacySupabaseService!;
    _setLoading(true);
    _clearError();

    try {
      final sent = await service.resetPasswordForEmail(email);
      if (!sent) {
        _errorMessage = service.lastAuthError ?? 'Could not send reset email.';
        _setLoading(false);
        return AuthCommandResult(
          success: false,
          statusCode: 500,
          message: _errorMessage!,
          errorCode: 'AUTH_ERROR',
        );
      }

      _setLoading(false);
      return const AuthCommandResult(
        success: true,
        statusCode: 200,
        message: 'Password reset link sent. Check your inbox.',
      );
    } catch (error) {
      debugPrint('resetPassword error: $error');
      _setLoading(false);
      _errorMessage = 'Password reset failed: $error';
      return AuthCommandResult(
        success: false,
        statusCode: 500,
        message: _errorMessage!,
      );
    }
  }

  Future<AuthCommandResult> _legacyLogout() async {
    final service = _legacySupabaseService!;
    _setLoading(true);
    _clearError();

    try {
      await service.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      return const AuthCommandResult(
        success: true,
        statusCode: 200,
        message: 'Signed out successfully.',
      );
    } catch (error) {
      debugPrint('logout error: $error');
      _errorMessage = 'Logout failed: $error';
      _setLoading(false);
      return AuthCommandResult(
        success: false,
        statusCode: 500,
        message: _errorMessage!,
      );
    }
  }

  Future<void> _legacyRefreshCurrentUser({required bool silent}) async {
    final service = _legacySupabaseService!;
    if (!silent) {
      _setLoading(true);
      _clearError();
    }

    final user = service.getCurrentUser();
    if (user == null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      if (!silent) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
      return;
    }

    final profileResult = await service.getProfile(user.id);
    _currentUser = profileResult == null
        ? null
        : ProfileModel.fromJson(profileResult);
    _status = _currentUser == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    if (!silent) {
      _setLoading(false);
    } else {
      notifyListeners();
    }
  }
}
