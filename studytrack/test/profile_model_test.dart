import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/models/user_model.dart';

void main() {
  group('ProfileModel', () {
    test('fromJson applies defaults for optional fields', () {
      final profile = ProfileModel.fromJson({
        'id': 'user-123',
        'created_at': '2026-04-28T10:00:00.000Z',
        'updated_at': '2026-04-29T10:00:00.000Z',
      });

      expect(profile.id, 'user-123');
      expect(profile.name, isNull);
      expect(profile.course, isNull);
      expect(profile.yearLevel, isNull);
      expect(profile.streakCount, 0);
      expect(profile.lastStudyDate, isNull);
    });

    test('toJson formats last_study_date as yyyy-mm-dd', () {
      final profile = ProfileModel(
        id: 'user-123',
        name: 'Jane',
        course: 'MBBS',
        yearLevel: 2,
        primeStudyTime: 'night',
        studyHoursPerDay: 3,
        studyPreference: 'alone',
        avatarUrl: 'https://example.com/avatar.jpg',
        streakCount: 4,
        lastStudyDate: DateTime.parse('2026-04-29T12:34:56.000Z'),
        createdAt: DateTime.parse('2026-04-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-04-29T00:00:00.000Z'),
      );

      final json = profile.toJson();
      expect(json['last_study_date'], '2026-04-29');
      expect(json['streak_count'], 4);
      expect(json['name'], 'Jane');
    });

    test('copyWith overrides only provided fields', () {
      final original = ProfileModel(
        id: 'user-123',
        name: 'Jane',
        course: 'MBBS',
        yearLevel: 2,
        primeStudyTime: 'night',
        studyHoursPerDay: 3,
        studyPreference: 'alone',
        avatarUrl: null,
        streakCount: 4,
        lastStudyDate: null,
        createdAt: DateTime.parse('2026-04-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-04-29T00:00:00.000Z'),
      );

      final updated = original.copyWith(name: 'Janet', streakCount: 5);

      expect(updated.id, 'user-123');
      expect(updated.name, 'Janet');
      expect(updated.streakCount, 5);
      expect(updated.course, 'MBBS');
      expect(updated.yearLevel, 2);
      expect(updated.createdAt, original.createdAt);
      expect(updated.updatedAt, original.updatedAt);
    });
  });
}
