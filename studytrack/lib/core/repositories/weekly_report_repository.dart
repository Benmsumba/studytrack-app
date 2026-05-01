import '../../models/weekly_report_model.dart';
import '../utils/result.dart';

/// Abstract interface for weekly report operations
abstract class WeeklyReportRepository {
  /// Save a new weekly report
  Future<Result<WeeklyReportModel>> saveWeeklyReport({
    required DateTime weekStart,
    required DateTime weekEnd,
    required int topicsStudied,
    required int topicsPlanned,
    required int sessionsCompleted,
    required int sessionsPlanned,
    required double averageRating,
    required int streakAtEnd,
    required String aiSummary,
  });

  /// Fetch all weekly reports for current user (limited by count)
  Future<Result<List<WeeklyReportModel>>> getWeeklyReports(int limit);

  /// Fetch the most recent weekly report
  Future<Result<WeeklyReportModel?>> getLastWeeklyReport();

  /// Get weekly reports for a specific date range
  Future<Result<List<WeeklyReportModel>>> getWeeklyReportsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Delete a weekly report
  Future<Result<void>> deleteWeeklyReport(String reportId);

  /// Sync weekly reports with backend
  Future<Result<void>> syncWeeklyReports();
}
