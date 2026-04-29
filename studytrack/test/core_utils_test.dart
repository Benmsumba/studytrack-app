import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/core/utils/helpers.dart';
import 'package:studytrack/core/utils/validators.dart';
import 'package:studytrack/models/topic_model.dart';

void main() {
  group('Validators.requiredField', () {
    test('returns error for null or blank input', () {
      expect(Validators.requiredField(null), 'This field is required');
      expect(Validators.requiredField(''), 'This field is required');
      expect(Validators.requiredField('   '), 'This field is required');
    });

    test('returns null for valid input', () {
      expect(Validators.requiredField('Biochemistry'), isNull);
    });
  });

  group('Helpers', () {
    test('formatTitle capitalizes first letter when not empty', () {
      expect(Helpers.formatTitle('studytrack'), 'Studytrack');
      expect(Helpers.formatTitle(''), '');
    });

    test('formatTime returns 12-hour timestamp', () {
      final value = Helpers.formatTime(const TimeOfDay(hour: 9, minute: 5));
      expect(value, matches(RegExp(r'^\d{2}:\d{2} [AP]M$')));
    });

    test('getGreeting maps time ranges correctly', () {
      expect(
        Helpers.getGreeting(now: DateTime.parse('2026-04-29T09:00:00.000Z')),
        'Good morning',
      );
      expect(
        Helpers.getGreeting(now: DateTime.parse('2026-04-29T14:00:00.000Z')),
        'Good afternoon',
      );
      expect(
        Helpers.getGreeting(now: DateTime.parse('2026-04-29T20:00:00.000Z')),
        'Good evening',
      );
    });

    test('calculateReadinessScore ignores unrated topics', () {
      final topics = [
        _topic(currentRating: 8),
        _topic(currentRating: 6),
        _topic(currentRating: null),
      ];

      expect(Helpers.calculateReadinessScore(topics), closeTo(70.0, 0.001));
    });

    test('calculateReadinessScore returns zero when no ratings exist', () {
      final topics = [_topic(currentRating: null), _topic(currentRating: null)];
      expect(Helpers.calculateReadinessScore(topics), 0);
    });

    test('getSpacedRepetitionDate maps rating bands to exact offsets', () {
      final base = DateTime.parse('2026-04-29T08:00:00.000Z');

      expect(
        Helpers.getSpacedRepetitionDate(2, from: base),
        DateTime.parse('2026-04-30T08:00:00.000Z'),
      );
      expect(
        Helpers.getSpacedRepetitionDate(5, from: base),
        DateTime.parse('2026-05-02T08:00:00.000Z'),
      );
      expect(
        Helpers.getSpacedRepetitionDate(7, from: base),
        DateTime.parse('2026-05-06T08:00:00.000Z'),
      );
      expect(
        Helpers.getSpacedRepetitionDate(9, from: base),
        DateTime.parse('2026-05-13T08:00:00.000Z'),
      );
      expect(
        Helpers.getSpacedRepetitionDate(10, from: base),
        DateTime.parse('2026-05-29T08:00:00.000Z'),
      );
    });
  });
}

TopicModel _topic({required int? currentRating}) => TopicModel(
    id: 'topic-1',
    moduleId: 'module-1',
    userId: 'user-1',
    name: 'Sample topic',
    isStudied: false,
    currentRating: currentRating,
    studyCount: 0,
    createdAt: DateTime.parse('2026-04-29T00:00:00.000Z'),
  );
