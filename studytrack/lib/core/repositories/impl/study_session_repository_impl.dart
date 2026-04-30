import 'package:flutter/foundation.dart';

import '../../../models/study_session_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../study_session_repository.dart';

/// Implementation of StudySessionRepository using SupabaseService
class StudySessionRepositoryImpl implements StudySessionRepository {
  StudySessionRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  @override
  Future<Result<List<StudySessionModel>>> getAllSessions() async {
    try {
      final sessions = await _supabaseService.getSessions();
      return Success(sessions);
    } catch (e, stack) {
      debugPrint('getAllSessions error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch sessions: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<StudySessionModel>>> getSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final sessions = await _supabaseService.getSessionsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      return Success(sessions);
    } catch (e, stack) {
      debugPrint('getSessionsByDateRange error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch sessions: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<StudySessionModel>>> getSessionsByTopic(
    String topicId,
  ) async {
    try {
      final sessions = await _supabaseService.getSessionsByTopic(topicId);
      return Success(sessions);
    } catch (e, stack) {
      debugPrint('getSessionsByTopic error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch sessions: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<StudySessionModel>> createSession({
    required String topicId,
    required int duration,
    required String focusArea,
    String? notes,
  }) async {
    try {
      final session = await _supabaseService.createSession(
        topicId: topicId,
        duration: duration,
        focusArea: focusArea,
        notes: notes,
      );
      return Success(session);
    } catch (e, stack) {
      debugPrint('createSession error: $e');
      return Failure(
        DataException(
          message: 'Failed to create session: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<StudySessionModel>> updateSession(
    StudySessionModel session,
  ) async {
    try {
      final updated = await _supabaseService.updateSession(session);
      return Success(updated);
    } catch (e, stack) {
      debugPrint('updateSession error: $e');
      return Failure(
        DataException(
          message: 'Failed to update session: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateSessionStatus({
    required String sessionId,
    required String status,
    int? actualDurationMinutes,
  }) async {
    try {
      final updated = await _supabaseService.updateSessionStatus(
        sessionId,
        status,
        actualDurationMinutes,
      );
      if (updated == null) {
        return Failure(
          DataException(message: 'Failed to update session status.'),
        );
      }
      return const Success(null);
    } catch (e, stack) {
      debugPrint('updateSessionStatus error: $e');
      return Failure(
        DataException(
          message: 'Failed to update session status: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    try {
      await _supabaseService.deleteSession(sessionId);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('deleteSession error: $e');
      return Failure(
        DataException(
          message: 'Failed to delete session: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<StudySessionModel>> endSession(String sessionId) async {
    try {
      final session = await _supabaseService.endSession(sessionId);
      return Success(session);
    } catch (e, stack) {
      debugPrint('endSession error: $e');
      return Failure(
        DataException(message: 'Failed to end session: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<Duration>> getTotalStudyTime() async {
    try {
      final total = await _supabaseService.getTotalStudyTime();
      return Success(total);
    } catch (e, stack) {
      debugPrint('getTotalStudyTime error: $e');
      return Failure(
        DataException(
          message: 'Failed to get total study time: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getDailyStreak() async {
    try {
      final streak = await _supabaseService.getDailyStreak();
      return Success(streak);
    } catch (e, stack) {
      debugPrint('getDailyStreak error: $e');
      return Failure(
        DataException(
          message: 'Failed to get daily streak: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<StudySessionModel>>> getSessionsToday() async {
    try {
      final sessions = await _supabaseService.getSessionsToday();
      return Success(sessions);
    } catch (e, stack) {
      debugPrint('getSessionsToday error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch sessions: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<Duration>> getAverageSessionDuration() async {
    try {
      final average = await _supabaseService.getAverageSessionDuration();
      return Success(average);
    } catch (e, stack) {
      debugPrint('getAverageSessionDuration error: $e');
      return Failure(
        DataException(
          message: 'Failed to get average session duration: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> syncSessions() async {
    try {
      // Sync handled by offline sync service
      return const Success(null);
    } catch (e, stack) {
      debugPrint('syncSessions error: $e');
      return Failure(
        DataException(
          message: 'Failed to sync sessions: $e',
          stackTrace: stack,
        ),
      );
    }
  }
}
