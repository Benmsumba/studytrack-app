import '../utils/result.dart';

/// Abstract interface for user profile operations
abstract class ProfileRepository {
  /// Fetch current user's profile
  Future<Result<Map<String, dynamic>?>> getCurrentProfile();

  /// Fetch profile by user ID
  Future<Result<Map<String, dynamic>?>> getProfileById(String userId);

  /// Update user profile
  Future<Result<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> profileData,
  );

  /// Update user bio
  Future<Result<void>> updateBio(String bio);

  /// Update user avatar URL
  Future<Result<void>> updateAvatarUrl(String avatarUrl);

  /// Update user preferences
  Future<Result<void>> updatePreferences(Map<String, dynamic> preferences);

  /// Delete user account
  Future<Result<void>> deleteAccount();

  /// Get user statistics (study streaks, total sessions, etc.)
  Future<Result<Map<String, dynamic>>> getUserStatistics();
}
