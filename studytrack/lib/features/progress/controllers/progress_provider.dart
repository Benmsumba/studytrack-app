import 'package:flutter/foundation.dart';

import '../../../core/repositories/study_session_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/repositories/weekly_report_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/topic_model.dart';
import '../../../models/weekly_report_model.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider({
    WeeklyReportRepository? weeklyReportRepository,
    StudySessionRepository? studySessionRepository,
    TopicRepository? topicRepository,
  }) : _weeklyReportRepository =
           weeklyReportRepository ?? getIt<WeeklyReportRepository>(),
       _studySessionRepository =
           studySessionRepository ?? getIt<StudySessionRepository>(),
       _topicRepository = topicRepository ?? getIt<TopicRepository>();

  final WeeklyReportRepository _weeklyReportRepository;
  final StudySessionRepository _studySessionRepository;
  final TopicRepository _topicRepository;

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
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Fetch study sessions for the week
      final sessionsResult = await _studySessionRepository
          .getSessionsByDateRange(startDate: weekStart, endDate: weekEnd);

      final completed = sessionsResult.fold(
        (error) => 0,
        (sessions) => sessions.where((s) => s.status == 'completed').length,
      );

      final sessionsCount = sessionsResult.fold(
        (error) => 0,
        (sessions) => sessions.length,
      );

      // Fetch topics due for review
      final topicsResult = await _topicRepository.getTopicsDueForReview();

      final topicsForCharts = topicsResult.fold(
        (error) => <dynamic>[],
        (topics) => topics,
      );

      final averageRating = _averageRating(
        topicsResult.fold((error) => [], (topics) => topics),
      );

      // Save the weekly report
      final saveResult = await _weeklyReportRepository.saveWeeklyReport(
        weekStart: weekStart,
        weekEnd: weekEnd,
        topicsStudied: topicsForCharts.length,
        topicsPlanned: topicsForCharts.length,
        sessionsCompleted: completed,
        sessionsPlanned: sessionsCount,
        averageRating: averageRating,
        streakAtEnd: 0,
        aiSummary: 'Keep your momentum this week.',
      );

      saveResult.fold(
        (error) {
          _errorMessage = error.message;
        },
        (report) {
          _weeklyReport = report;
        },
      );
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
      // Fetch weekly reports
      final reportsResult = await _weeklyReportRepository.getWeeklyReports(8);

      reportsResult.fold(
        (error) {
          _errorMessage = error.message;
          _chartData = const {};
        },
        (reports) {
          _errorMessage = null;
          _chartData = {
            'weeklyReports': reports,
            'sessionTrend': reports
                .map((report) => report.sessionsCompleted)
                .toList(growable: false),
            'ratingTrend': reports
                .map((report) => report.averageRating)
                .toList(growable: false),
          };
        },
      );

      // Fetch latest weekly report
      final latestResult = await _weeklyReportRepository.getLastWeeklyReport();
      latestResult.fold(
        (error) {
          // Error fetching latest, silently ignore
          debugPrint('Failed to load latest report: ${error.message}');
        },
        (report) {
          if (report != null) {
            _weeklyReport = report;
          }
        },
      );
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
