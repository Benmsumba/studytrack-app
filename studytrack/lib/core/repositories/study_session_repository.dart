import '../../models/study_session_model.dart';
import '../utils/result.dart';

/// Abstract interface for study session operations
abstract class StudySessionRepository {
  /// Fetch all study sessions
  Future<Result<List<StudySessionModel>>> getAllSessions();

  /// Fetch sessions for a specific date range
  Future<Result<List<StudySessionModel>>> getSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetch sessions for a specific topic
  Future<Result<List<StudySessionModel>>> getSessionsByTopic(String topicId);

  /// Create new study session
  Future<Result<StudySessionModel>> createSession({
    required String topicId,
    required int duration,
    required String focusArea,
    String? notes,
  });

  /// Update session
  Future<Result<StudySessionModel>> updateSession(StudySessionModel session);

  /// Update session status with optional actual duration
  Future<Result<void>> updateSessionStatus({
    required String sessionId,
    required String status,
    int? actualDurationMinutes,
  });

  /// Delete session
  Future<Result<void>> deleteSession(String sessionId);

  /// End study session
  Future<Result<StudySessionModel>> endSession(String sessionId);

  /// Get total study time for user
  Future<Result<Duration>> getTotalStudyTime();

  /// Get daily study streak
  Future<Result<int>> getDailyStreak();

  /// Get sessions completed today
  Future<Result<List<StudySessionModel>>> getSessionsToday();

  /// Get average session duration
  Future<Result<Duration>> getAverageSessionDuration();

  /// Sync sessions with backend
  Future<Result<void>> syncSessions();
}
