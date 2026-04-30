import '../../models/user_model.dart';
import '../utils/result.dart';

/// Abstract interface for authentication operations
abstract class AuthRepository {
  /// Sign up with email and password
  Future<Result<ProfileModel>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String course,
    required int yearLevel,
    required String studyStyle,
    required int sessionsPerWeek,
    required String preferredStudyMethod,
  });

  /// Sign in with email and password
  Future<Result<ProfileModel>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google OAuth
  Future<Result<void>> signInWithGoogle();

  /// Sign out current user
  Future<Result<void>> signOut();

  /// Get current authenticated user
  Future<Result<ProfileModel?>> getCurrentUser();

  /// Reset password
  Future<Result<void>> resetPassword(String email);

  /// Verify OTP
  Future<Result<ProfileModel>> verifyOtp({
    required String email,
    required String otp,
  });

  /// Update user profile
  Future<Result<ProfileModel>> updateProfile(ProfileModel profile);

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Get last auth error
  String? get lastAuthError;
}
