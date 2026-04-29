import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/models/topic_rating_history_model.dart';

void main() {
  group('TopicRatingHistoryModel', () {
    test('fromJson creates TopicRatingHistoryModel with correct values', () {
      final ratedAt = DateTime(2026, 4, 18, 16, 30, 0);
      final json = {
        'id': 'history-1',
        'topic_id': 'topic-123',
        'user_id': 'user-456',
        'rating': 4,
        'rated_at': ratedAt.toIso8601String(),
      };

      final history = TopicRatingHistoryModel.fromJson(json);

      expect(history.id, 'history-1');
      expect(history.topicId, 'topic-123');
      expect(history.userId, 'user-456');
      expect(history.rating, 4);
      expect(history.ratedAt, ratedAt);
    });

    test('fromJson handles various rating values', () {
      final ratedAt = DateTime(2026, 4, 18, 16, 30, 0);

      for (final rating in [1, 2, 3, 4, 5]) {
        final json = {
          'id': 'history-$rating',
          'topic_id': 'topic-test',
          'user_id': 'user-test',
          'rating': rating,
          'rated_at': ratedAt.toIso8601String(),
        };

        final history = TopicRatingHistoryModel.fromJson(json);
        expect(history.rating, rating);
      }
    });

    test('toJson converts TopicRatingHistoryModel to JSON correctly', () {
      final ratedAt = DateTime(2026, 4, 18, 16, 30, 0);
      final history = TopicRatingHistoryModel(
        id: 'history-2',
        topicId: 'topic-789',
        userId: 'user-999',
        rating: 5,
        ratedAt: ratedAt,
      );

      final json = history.toJson();

      expect(json['id'], 'history-2');
      expect(json['topic_id'], 'topic-789');
      expect(json['user_id'], 'user-999');
      expect(json['rating'], 5);
      expect(json['rated_at'], ratedAt.toIso8601String());
    });

    test('copyWith updates specified fields only', () {
      final ratedAt = DateTime(2026, 4, 18);
      final newRatedAt = DateTime(2026, 4, 25);
      final original = TopicRatingHistoryModel(
        id: 'history-1',
        topicId: 'topic-1',
        userId: 'user-1',
        rating: 2,
        ratedAt: ratedAt,
      );

      final updated = original.copyWith(rating: 4, ratedAt: newRatedAt);

      expect(updated.id, 'history-1');
      expect(updated.topicId, 'topic-1');
      expect(updated.userId, 'user-1');
      expect(updated.rating, 4);
      expect(updated.ratedAt, newRatedAt);
    });

    test('copyWith without args returns identical copy', () {
      final ratedAt = DateTime(2026, 4, 18);
      final history = TopicRatingHistoryModel(
        id: 'history-1',
        topicId: 'topic-1',
        userId: 'user-1',
        rating: 3,
        ratedAt: ratedAt,
      );

      final copy = history.copyWith();

      expect(copy.id, history.id);
      expect(copy.rating, history.rating);
      expect(copy.ratedAt, history.ratedAt);
    });
  });
}
