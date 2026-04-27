import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/topic_model.dart';
import '../../../models/weekly_report_model.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  final SupabaseService _supabaseService;

  WeeklyReportModel? _weeklyReport;
  bool _isGeneratingWrapped = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _chartData = const {};

  WeeklyReportModel? get weeklyReport => _weeklyReport;
  bool get isGeneratingWrapped => _isGeneratingWrapped;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get chartData => _chartData;

  Future<void> generateWeeklyReport(String userId) async {
    _isGeneratingWrapped = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final sessions = await _supabaseService.getStudySessions(userId, now) ??
          const [];
      final topicsForCharts = await _supabaseService.getTopicsNeedingReview(
            userId,
          ) ??
          const <TopicModel>[];

      final completed = sessions
          .where((row) => (row['status']?.toString() ?? '') == 'completed')
          .length;

      final reportPayload = {
        'user_id': userId,
        'week_start': weekStart.toIso8601String().split('T').first,
        'week_end': weekEnd.toIso8601String().split('T').first,
        'topics_studied': topicsForCharts.length,
        'topics_planned': topicsForCharts.length,
        'sessions_completed': completed,
        'sessions_planned': sessions.length,
        'average_rating': _averageRating(topicsForCharts),
        'streak_at_end': 0,
        'ai_summary': 'Keep your momentum this week.',
      };

      final saved = await _supabaseService.saveWeeklyReport(reportPayload);
      if (saved == null) {
        _errorMessage = 'Failed to generate weekly report.';
      } else {
        _weeklyReport = WeeklyReportModel.fromJson(saved);
      }
    } catch (error) {
      _errorMessage = 'Failed to generate weekly report: $error';
    } finally {
      _isGeneratingWrapped = false;
      notifyListeners();
    }
  }

  Future<void> loadChartData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reports = await _supabaseService.getWeeklyReports(userId, 8) ??
          const [];

      _chartData = {
        'weeklyReports': reports,
        'sessionTrend': reports
            .map((row) => (row['sessions_completed'] as num?)?.toInt() ?? 0)
            .toList(growable: false),
        'ratingTrend': reports
            .map((row) => (row['average_rating'] as num?)?.toDouble() ?? 0)
            .toList(growable: false),
      };

      final latest = await _supabaseService.getLastWeekReport(userId);
      if (latest != null) {
        _weeklyReport = WeeklyReportModel.fromJson(latest);
      }
    } catch (error) {
      _errorMessage = 'Failed to load analytics data: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double _averageRating(List<TopicModel> topics) {
    final rated = topics.where((topic) => topic.currentRating != null).toList();
    if (rated.isEmpty) {
      return 0;
    }

    final total = rated.fold<int>(
      0,
      (sum, topic) => sum + (topic.currentRating ?? 0),
    );

    return total / rated.length;
  }
}
