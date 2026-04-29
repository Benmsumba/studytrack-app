import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/models/badge_model.dart';

void main() {
  group('BadgeModel', () {
    test('fromJson creates BadgeModel with correct values', () {
      final earnedAt = DateTime(2026, 4, 15, 10, 30, 0);
      final json = {
        'id': 'badge-1',
        'user_id': 'user-123',
        'badge_type': 'first_study',
        'earned_at': earnedAt.toIso8601String(),
      };

      final badge = BadgeModel.fromJson(json);

      expect(badge.id, 'badge-1');
      expect(badge.userId, 'user-123');
      expect(badge.badgeType, 'first_study');
      expect(badge.earnedAt, earnedAt);
    });

    test('toJson converts BadgeModel to JSON with correct format', () {
      final earnedAt = DateTime(2026, 4, 15, 10, 30, 0);
      final badge = BadgeModel(
        id: 'badge-1',
        userId: 'user-123',
        badgeType: 'milestone_100h',
        earnedAt: earnedAt,
      );

      final json = badge.toJson();

      expect(json['id'], 'badge-1');
      expect(json['user_id'], 'user-123');
      expect(json['badge_type'], 'milestone_100h');
      expect(json['earned_at'], earnedAt.toIso8601String());
    });

    test('copyWith updates only specified fields', () {
      final earnedAt = DateTime(2026, 4, 15);
      final newEarnedAt = DateTime(2026, 4, 20);
      final original = BadgeModel(
        id: 'badge-1',
        userId: 'user-123',
        badgeType: 'streak_7days',
        earnedAt: earnedAt,
      );

      final updated = original.copyWith(
        badgeType: 'perfect_rating',
        earnedAt: newEarnedAt,
      );

      expect(updated.id, 'badge-1');
      expect(updated.userId, 'user-123');
      expect(updated.badgeType, 'perfect_rating');
      expect(updated.earnedAt, newEarnedAt);
    });

    test('copyWith without args returns identical copy', () {
      final earnedAt = DateTime(2026, 4, 15);
      final badge = BadgeModel(
        id: 'badge-1',
        userId: 'user-123',
        badgeType: 'first_study',
        earnedAt: earnedAt,
      );

      final copy = badge.copyWith();

      expect(copy.id, badge.id);
      expect(copy.userId, badge.userId);
      expect(copy.badgeType, badge.badgeType);
      expect(copy.earnedAt, badge.earnedAt);
    });
  });
}
