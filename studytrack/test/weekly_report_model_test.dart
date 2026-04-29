import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/models/weekly_report_model.dart';

void main() {
  group('WeeklyReportModel', () {
    test('fromJson creates WeeklyReportModel with all fields', () {
      final weekStart = DateTime(2026, 4, 13);
      final weekEnd = DateTime(2026, 4, 19);
      final createdAt = DateTime(2026, 4, 20, 9, 0, 0);
      final json = {
        'id': 'report-1',
        'user_id': 'user-123',
        'week_start': weekStart.toIso8601String().split('T').first,
        'week_end': weekEnd.toIso8601String().split('T').first,
        'topics_studied': 8,
        'topics_planned': 10,
        'sessions_completed': 12,
        'sessions_planned': 15,
        'average_rating': 4.2,
        'best_subject': 'Physics',
        'weakest_subject': 'Chemistry',
        'streak_at_end': 5,
        'ai_summary': 'Great week of progress',
        'created_at': createdAt.toIso8601String(),
      };

      final report = WeeklyReportModel.fromJson(json);

      expect(report.id, 'report-1');
      expect(report.userId, 'user-123');
      expect(report.topicsStudied, 8);
      expect(report.topicsPlanned, 10);
      expect(report.sessionsCompleted, 12);
      expect(report.sessionsPlanned, 15);
      expect(report.averageRating, 4.2);
      expect(report.bestSubject, 'Physics');
      expect(report.weakestSubject, 'Chemistry');
      expect(report.streakAtEnd, 5);
      expect(report.aiSummary, 'Great week of progress');
    });

    test('fromJson handles null optional fields', () {
      final weekStart = DateTime(2026, 4, 13);
      final weekEnd = DateTime(2026, 4, 19);
      final createdAt = DateTime(2026, 4, 20, 9, 0, 0);
      final json = {
        'id': 'report-2',
        'user_id': 'user-456',
        'week_start': weekStart.toIso8601String().split('T').first,
        'week_end': weekEnd.toIso8601String().split('T').first,
        'topics_studied': 5,
        'topics_planned': 8,
        'sessions_completed': 6,
        'sessions_planned': 10,
        'average_rating': null,
        'best_subject': null,
        'weakest_subject': null,
        'streak_at_end': 2,
        'ai_summary': null,
        'created_at': createdAt.toIso8601String(),
      };

      final report = WeeklyReportModel.fromJson(json);

      expect(report.averageRating, isNull);
      expect(report.bestSubject, isNull);
      expect(report.weakestSubject, isNull);
      expect(report.aiSummary, isNull);
    });

    test('toJson converts WeeklyReportModel to JSON with date formatting', () {
      final weekStart = DateTime(2026, 4, 13);
      final weekEnd = DateTime(2026, 4, 19);
      final createdAt = DateTime(2026, 4, 20, 9, 0, 0);
      final report = WeeklyReportModel(
        id: 'report-3',
        userId: 'user-789',
        weekStart: weekStart,
        weekEnd: weekEnd,
        topicsStudied: 7,
        topicsPlanned: 9,
        sessionsCompleted: 10,
        sessionsPlanned: 12,
        averageRating: 3.8,
        bestSubject: 'Math',
        weakestSubject: 'History',
        streakAtEnd: 3,
        aiSummary: 'Consistent effort observed',
        createdAt: createdAt,
      );

      final json = report.toJson();

      expect(json['id'], 'report-3');
      expect(json['topics_studied'], 7);
      expect(json['sessions_completed'], 10);
      expect(json['week_start'], '2026-04-13');
      expect(json['week_end'], '2026-04-19');
      expect(json['average_rating'], 3.8);
    });

    test('copyWith updates specified fields only', () {
      final weekStart = DateTime(2026, 4, 13);
      final weekEnd = DateTime(2026, 4, 19);
      final createdAt = DateTime(2026, 4, 20);
      final original = WeeklyReportModel(
        id: 'report-1',
        userId: 'user-1',
        weekStart: weekStart,
        weekEnd: weekEnd,
        topicsStudied: 5,
        topicsPlanned: 10,
        sessionsCompleted: 8,
        sessionsPlanned: 12,
        averageRating: 3.5,
        bestSubject: 'Physics',
        weakestSubject: 'Biology',
        streakAtEnd: 2,
        aiSummary: 'Good progress',
        createdAt: createdAt,
      );

      final updated = original.copyWith(
        topicsStudied: 8,
        sessionsCompleted: 10,
        averageRating: 4.1,
        streakAtEnd: 3,
      );

      expect(updated.id, 'report-1');
      expect(updated.topicsStudied, 8);
      expect(updated.sessionsCompleted, 10);
      expect(updated.averageRating, 4.1);
      expect(updated.streakAtEnd, 3);
      expect(updated.bestSubject, 'Physics');
    });
  });
}
