import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../profile_repository.dart';

/// Implementation of ProfileRepository using SupabaseService
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  String? get _userId => _supabaseService.getCurrentUser()?.id;

  @override
  Future<Result<Map<String, dynamic>?>> getCurrentProfile() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(AuthException(message: 'User not authenticated'));
      }
      final profile = await _supabaseService.getProfile(uid);
      return Success(profile);
    } on Exception catch (e, stack) {
      debugPrint('getCurrentProfile error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch profile: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> getProfileById(String userId) async {
    try {
      if (userId.trim().isEmpty) {
        return Failure(ValidationException(message: 'User ID is required'));
      }
      final profile = await _supabaseService.getProfile(userId);
      return Success(profile);
    } on Exception catch (e, stack) {
      debugPrint('getProfileById error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch profile: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(AuthException(message: 'User not authenticated'));
      }

      final updated = await _supabaseService.updateProfile(uid, profileData);
      if (updated == null) {
        return Failure(DataException(message: 'Failed to update profile'));
      }
      return Success(updated);
    } on Exception catch (e, stack) {
      debugPrint('updateProfile error: $e');
      return Failure(
        DataException(
          message: 'Failed to update profile: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateBio(String bio) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(AuthException(message: 'User not authenticated'));
      }

      await _supabaseService.updateProfile(uid, {'bio': bio});
      return const Success(null);
    } on Exception catch (e, stack) {
      debugPrint('updateBio error: $e');
      return Failure(
        DataException(message: 'Failed to update bio: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> updateAvatarUrl(String avatarUrl) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(AuthException(message: 'User not authenticated'));
      }

      await _supabaseService.updateProfile(uid, {'avatar_url': avatarUrl});
      return const Success(null);
    } on Exception catch (e, stack) {
      debugPrint('updateAvatarUrl error: $e');
      return Failure(
        DataException(
          message: 'Failed to update avatar: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updatePreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(AuthException(message: 'User not authenticated'));
      }

      await _supabaseService.updateProfile(uid, preferences);
      return const Success(null);
    } on Exception catch (e, stack) {
      debugPrint('updatePreferences error: $e');
      return Failure(
        DataException(
          message: 'Failed to update preferences: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(AuthException(message: 'User not authenticated'));
      }

      final client = _supabaseService.client;

      // Delete user-owned rows (RLS allows this). Order: child → parent.
      for (final table in const [
        'group_messages',
        'group_members',
        'study_sessions',
        'topic_ratings',
        'uploaded_notes',
        'topics',
        'modules',
        'class_slots',
        'exams',
        'badges',
        'weekly_reports',
        'profiles',
      ]) {
        await client.from(table).delete().eq('user_id', uid);
      }

      // Call the delete-account edge function which uses the service-role key
      // to call auth.admin.deleteUser — the only way to hard-delete the auth
      // record from client-side code.
      await client.functions.invoke(
        'delete-account',
        method: supabase.HttpMethod.post,
      );

      // Sign out last so the JWT is still valid for the function call above.
      await client.auth.signOut();

      return const Success(null);
    } on Exception catch (e, stack) {
      debugPrint('deleteAccount error: $e');
      return Failure(
        DataException(
          message: 'Failed to delete account: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserStatistics() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(AuthException(message: 'User not authenticated'));
      }

      final client = _supabaseService.client;

      final sessions = await client
          .from('study_sessions')
          .select('duration_minutes')
          .eq('user_id', uid);

      final totalSessions = (sessions as List).length;
      final totalMinutes = sessions.fold<int>(
        0,
        (sum, row) => sum + ((row['duration_minutes'] as num?)?.toInt() ?? 0),
      );

      final modules = await client
          .from('modules')
          .select('id')
          .eq('user_id', uid);

      return Success({
        'total_sessions': totalSessions,
        'total_study_minutes': totalMinutes,
        'total_modules': (modules as List).length,
      });
    } on Exception catch (e, stack) {
      debugPrint('getUserStatistics error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch user statistics: $e',
          stackTrace: stack,
        ),
      );
    }
  }
}
