import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/core/constants/app_colors.dart';
import 'package:studytrack/models/topic_model.dart';

void main() {
  group('TopicModel masteryLevel', () {
    test('maps rating boundaries to expected mastery labels', () {
      expect(_topic(currentRating: null).masteryLevel, 'Needs Work');
      expect(_topic(currentRating: 2).masteryLevel, 'Needs Work');
      expect(_topic(currentRating: 3).masteryLevel, 'Learning');
      expect(_topic(currentRating: 4).masteryLevel, 'Learning');
      expect(_topic(currentRating: 5).masteryLevel, 'Good');
      expect(_topic(currentRating: 7).masteryLevel, 'Good');
      expect(_topic(currentRating: 8).masteryLevel, 'Mastered');
    });
  });

  group('TopicModel ratingColor', () {
    test('maps rating boundaries to semantic colors', () {
      expect(_topic(currentRating: null).ratingColor, AppColors.danger);
      expect(_topic(currentRating: 2).ratingColor, AppColors.danger);
      expect(_topic(currentRating: 3).ratingColor, AppColors.warning);
      expect(_topic(currentRating: 4).ratingColor, AppColors.warning);
      expect(_topic(currentRating: 5).ratingColor, AppColors.accent);
      expect(_topic(currentRating: 7).ratingColor, AppColors.accent);
      expect(_topic(currentRating: 8).ratingColor, AppColors.success);
    });
  });

  group('TopicModel serialization', () {
    test('fromJson and toJson preserve key fields', () {
      final json = {
        'id': 'topic-1',
        'module_id': 'module-1',
        'user_id': 'user-1',
        'name': 'Cardiac cycle',
        'is_studied': true,
        'current_rating': 6,
        'study_count': 2,
        'last_studied_at': '2026-04-28T09:30:00.000Z',
        'next_review_at': '2026-05-01T09:30:00.000Z',
        'notes': 'Review pressure curves',
        'created_at': '2026-04-20T08:00:00.000Z',
      };

      final topic = TopicModel.fromJson(json);
      final encoded = topic.toJson();

      expect(topic.name, 'Cardiac cycle');
      expect(topic.currentRating, 6);
      expect(topic.isStudied, isTrue);
      expect(topic.lastStudiedAt, DateTime.parse('2026-04-28T09:30:00.000Z'));
      expect(topic.nextReviewAt, DateTime.parse('2026-05-01T09:30:00.000Z'));

      expect(encoded['id'], 'topic-1');
      expect(encoded['module_id'], 'module-1');
      expect(encoded['user_id'], 'user-1');
      expect(encoded['current_rating'], 6);
      expect(encoded['study_count'], 2);
      expect(encoded['notes'], 'Review pressure curves');
    });

    test('copyWith overrides only provided fields', () {
      final original = _topic(
        currentRating: 4,
        isStudied: false,
        studyCount: 1,
      );

      final updated = original.copyWith(
        name: 'Respiratory control',
        currentRating: 8,
        isStudied: true,
      );

      expect(updated.id, original.id);
      expect(updated.moduleId, original.moduleId);
      expect(updated.userId, original.userId);
      expect(updated.name, 'Respiratory control');
      expect(updated.currentRating, 8);
      expect(updated.isStudied, isTrue);
      expect(updated.studyCount, 1);
      expect(updated.createdAt, original.createdAt);
    });
  });
}

TopicModel _topic({
  required int? currentRating,
  bool isStudied = false,
  int studyCount = 0,
}) {
  return TopicModel(
    id: 'topic-1',
    moduleId: 'module-1',
    userId: 'user-1',
    name: 'Sample topic',
    isStudied: isStudied,
    currentRating: currentRating,
    studyCount: studyCount,
    createdAt: DateTime.parse('2026-04-20T08:00:00.000Z'),
  );
}
