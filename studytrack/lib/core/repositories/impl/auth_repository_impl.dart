import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../auth_repository.dart';

/// Implementation of AuthRepository using SupabaseService
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  /// Convert User from Gotrue to ProfileModel
  ProfileModel? _userToProfileModel(User? user) {
    if (user == null) return null;

    final userData = user.userMetadata ?? {};
    final createdAt = DateTime.parse(user.createdAt);
    final updatedAt = user.updatedAt is String
        ? DateTime.parse(user.updatedAt!)
        : (user.updatedAt as DateTime?);

    return ProfileModel(
      id: user.id,
      name: userData['name'] as String?,
      course: userData['course'] as String?,
      yearLevel: (userData['year_level'] as num?)?.toInt(),
      primeStudyTime: userData['prime_study_time'] as String?,
      studyHoursPerDay: (userData['study_hours_per_day'] as num?)?.toInt(),
      studyPreference: userData['study_preference'] as String?,
      streakCount: 0,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

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

      final profile = _userToProfileModel(user);
      if (profile == null) {
        return Failure(
          AuthException(message: 'Unable to convert user to profile'),
        );
      }

      return Success(profile);
    } on Object catch (e, stack) {
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

      final profile = _userToProfileModel(user);
      if (profile == null) {
        return Failure(
          AuthException(message: 'Unable to convert user to profile'),
        );
      }

      return Success(profile);
    } on Object catch (e, stack) {
      debugPrint('SignIn error: $e');
      return Failure(
        AuthException(message: 'Sign in failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    try {
      final ok = await _supabaseService.signInWithGoogle();
      if (!ok) {
        return Failure(
          AuthException(
            message: _supabaseService.lastAuthError ?? 'Google sign-in failed',
          ),
        );
      }
      return const Success(null);
    } on Object catch (e, stack) {
      debugPrint('GoogleSignIn error: $e');
      return Failure(
        AuthException(message: 'Google sign-in failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _supabaseService.signOut();
      return const Success(null);
    } on Object catch (e, stack) {
      debugPrint('SignOut error: $e');
      return Failure(
        AuthException(message: 'Sign out failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<ProfileModel?>> getCurrentUser() async {
    try {
      final user = _supabaseService.getCurrentUser();
      final profile = _userToProfileModel(user);
      return Success(profile);
    } on Object catch (e, stack) {
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
      final success = await _supabaseService.resetPasswordForEmail(email);
      if (!success) {
        return Failure(
          AuthException(
            message:
                _supabaseService.lastAuthError ?? 'Failed to reset password',
          ),
        );
      }
      return const Success(null);
    } on Object catch (e, stack) {
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
      final response = await _supabaseService.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      final profile = _userToProfileModel(response.user);
      if (profile == null) {
        return Failure(AuthException(message: 'OTP verification failed'));
      }
      return Success(profile);
    } on Object catch (e, stack) {
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
      final user = _supabaseService.getCurrentUser();
      if (user == null) {
        return Failure(AuthException(message: 'No authenticated user found'));
      }

      final data = {
        'name': profile.name,
        'course': profile.course,
        'year_level': profile.yearLevel,
        'prime_study_time': profile.primeStudyTime,
        'study_hours_per_day': profile.studyHoursPerDay,
        'study_preference': profile.studyPreference,
        'avatar_url': profile.avatarUrl,
      };

      final updated = await _supabaseService.updateProfile(user.id, data);

      if (updated == null) {
        return Failure(DataException(message: 'Failed to update profile'));
      }

      // Merge updated profile data with original
      final updatedProfile = ProfileModel(
        id: profile.id,
        name: updated['name'] as String? ?? profile.name,
        course: updated['course'] as String? ?? profile.course,
        yearLevel:
            (updated['year_level'] as num?)?.toInt() ?? profile.yearLevel,
        primeStudyTime:
            updated['prime_study_time'] as String? ?? profile.primeStudyTime,
        studyHoursPerDay:
            (updated['study_hours_per_day'] as num?)?.toInt() ??
            profile.studyHoursPerDay,
        studyPreference:
            updated['study_preference'] as String? ?? profile.studyPreference,
        avatarUrl: updated['avatar_url'] as String? ?? profile.avatarUrl,
        streakCount:
            (updated['streak_count'] as num?)?.toInt() ?? profile.streakCount,
        lastStudyDate: profile.lastStudyDate,
        createdAt: profile.createdAt,
        updatedAt: DateTime.now(),
      );

      return Success(updatedProfile);
    } on Object catch (e, stack) {
      debugPrint('UpdateProfile error: $e');
      return Failure(
        DataException(message: 'Profile update failed: $e', stackTrace: stack),
      );
    }
  }

  @override
  bool get isAuthenticated => _supabaseService.isLoggedIn();

  @override
  String? get lastAuthError => _supabaseService.lastAuthError;
}
