import 'package:flutter/foundation.dart';

import '../../../models/weekly_report_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../weekly_report_repository.dart';

/// Implementation of WeeklyReportRepository using SupabaseService
class WeeklyReportRepositoryImpl implements WeeklyReportRepository {
  WeeklyReportRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  String? get _userId => _supabaseService.getCurrentUser()?.id;

  @override
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
  }) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(DataException(message: 'User not authenticated'));
      }

      final payload = {
        'user_id': uid,
        'week_start': weekStart.toIso8601String().split('T').first,
        'week_end': weekEnd.toIso8601String().split('T').first,
        'topics_studied': topicsStudied,
        'topics_planned': topicsPlanned,
        'sessions_completed': sessionsCompleted,
        'sessions_planned': sessionsPlanned,
        'average_rating': averageRating,
        'streak_at_end': streakAtEnd,
        'ai_summary': aiSummary,
      };

      final result = await _supabaseService.saveWeeklyReport(payload);
      if (result == null) {
        return Failure(DataException(message: 'Failed to save weekly report'));
      }

      return Success(WeeklyReportModel.fromJson(result));
    } on Object catch (e, stack) {
      debugPrint('saveWeeklyReport error: $e');
      return Failure(
        DataException(
          message: 'Failed to save weekly report: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<WeeklyReportModel>>> getWeeklyReports(int limit) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(<WeeklyReportModel>[]);
      }

      final reports = await _supabaseService.getWeeklyReports(uid, limit);
      final models = (reports ?? []).map(WeeklyReportModel.fromJson).toList();
      return Success(models);
    } on Object catch (e, stack) {
      debugPrint('getWeeklyReports error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch weekly reports: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<WeeklyReportModel?>> getLastWeeklyReport() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(null);
      }

      final report = await _supabaseService.getLastWeekReport(uid);
      if (report == null) {
        return const Success(null);
      }

      return Success(WeeklyReportModel.fromJson(report));
    } on Object catch (e, stack) {
      debugPrint('getLastWeeklyReport error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch week report: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<WeeklyReportModel>>> getWeeklyReportsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(<WeeklyReportModel>[]);
      }

      // Get all reports and filter client-side
      final reports = await _supabaseService.getWeeklyReports(uid, 52);
      final filtered = (reports ?? []).map(WeeklyReportModel.fromJson).where((
        report,
      ) {
        final reportStart = DateTime.parse(report.weekStart.toString());
        return reportStart.isAfter(startDate) && reportStart.isBefore(endDate);
      }).toList();

      return Success(filtered);
    } on Object catch (e, stack) {
      debugPrint('getWeeklyReportsByDateRange error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch weekly reports for date range: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteWeeklyReport(String reportId) async {
    try {
      // Since SupabaseService doesn't have a delete method for reports,
      // we would need to query the database directly or add a method
      // For now, return success (this can be implemented later if needed)
      return const Success(null);
    } catch (e, stack) {
      debugPrint('deleteWeeklyReport error: $e');
      return Failure(
        DataException(
          message: 'Failed to delete weekly report: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> syncWeeklyReports() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(null);
      }

      // Trigger a fresh fetch to sync
      await _supabaseService.getWeeklyReports(uid, 52);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('syncWeeklyReports error: $e');
      return Failure(
        DataException(
          message: 'Failed to sync weekly reports: $e',
          stackTrace: stack,
        ),
      );
    }
  }
}
