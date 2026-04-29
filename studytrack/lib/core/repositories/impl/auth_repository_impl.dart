import 'package:flutter/foundation.dart';

import '../../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../auth_repository.dart';

/// Implementation of AuthRepository using SupabaseService
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseService _supabaseService;

  AuthRepositoryImpl(this._supabaseService);

  @override
  Future<Result<ProfileModel>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String course,
    required int yearLevel,
    required String studyStyle,
    required int sessionsPerWeek,
    required String preferredStudyMethod,
  }) async {
    try {
      final user = await _supabaseService.signUpWithEmail(
        email,
        password,
        fullName,
        course,
        yearLevel,
        studyStyle,
        sessionsPerWeek,
        preferredStudyMethod,
      );

      if (user == null) {
        return Failure(
          AuthException(
            message:
                _supabaseService.lastAuthError ?? 'Unable to create account',
          ),
        );
      }

      return Success(user);
    } catch (e, stack) {
      debugPrint('SignUp error: $e');
      return Failure(
        AuthException(message: 'Sign up failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<ProfileModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _supabaseService.signInWithEmail(email, password);

      if (user == null) {
        return Failure(
          AuthException(
            message: _supabaseService.lastAuthError ?? 'Unable to sign in',
          ),
        );
      }

      return Success(user);
    } catch (e, stack) {
      debugPrint('SignIn error: $e');
      return Failure(
        AuthException(message: 'Sign in failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _supabaseService.signOut();
      return const Success(null);
    } catch (e, stack) {
      debugPrint('SignOut error: $e');
      return Failure(
        AuthException(message: 'Sign out failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<ProfileModel?>> getCurrentUser() async {
    try {
      final user = await _supabaseService.getCurrentUser();
      return Success(user);
    } catch (e, stack) {
      debugPrint('GetCurrentUser error: $e');
      return Failure(
        DataException(
          message: 'Failed to get current user: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _supabaseService.resetPassword(email);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('ResetPassword error: $e');
      return Failure(
        AuthException(message: 'Password reset failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<ProfileModel>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final user = await _supabaseService.verifyOtp(email: email, otp: otp);

      if (user == null) {
        return Failure(
          AuthException(
            message: _supabaseService.lastAuthError ?? 'Unable to verify OTP',
          ),
        );
      }

      return Success(user);
    } catch (e, stack) {
      debugPrint('VerifyOtp error: $e');
      return Failure(
        AuthException(
          message: 'OTP verification failed: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<ProfileModel>> updateProfile(ProfileModel profile) async {
    try {
      final updated = await _supabaseService.updateProfile(profile);

      if (updated == null) {
        return Failure(DataException(message: 'Failed to update profile'));
      }

      return Success(updated);
    } catch (e, stack) {
      debugPrint('UpdateProfile error: $e');
      return Failure(
        DataException(message: 'Profile update failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  bool get isAuthenticated => _supabaseService.isAuthenticated;

  @override
  String? get lastAuthError => _supabaseService.lastAuthError;
}
