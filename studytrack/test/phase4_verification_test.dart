import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/core/constants/app_constants.dart';
import 'package:studytrack/core/utils/validators.dart';
import 'package:studytrack/models/module_model.dart';
import 'package:studytrack/models/user_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // AppConstants
  // ---------------------------------------------------------------------------

  test('supabase defaults are treated as unconfigured', () {
    expect(AppConstants.isSupabaseConfigured, isFalse);
    expect(AppConstants.resolvedSupabaseUrl, 'YOUR_SUPABASE_URL');
    expect(AppConstants.resolvedSupabaseAnonKey, 'YOUR_SUPABASE_ANON_KEY');
  });

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  group('Validators — email', () {
    test('accepts standard email addresses', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('first.last+tag@sub.domain.org'), isNull);
    });

    test('rejects empty and whitespace', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('rejects addresses without a proper domain', () {
      expect(Validators.email('no-at-sign'), isNotNull);
      expect(Validators.email('missing@'), isNotNull);
      expect(Validators.email('@nodomain.com'), isNotNull);
    });
  });

  group('Validators — password', () {
    test('accepts passwords with 8+ characters', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('StrongP@ss1'), isNull);
    });

    test('rejects passwords shorter than 8 characters', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
    });

    test('rejects null and empty', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
    });
  });

  group('Validators — confirmPassword', () {
    test('returns null when value matches password', () {
      expect(Validators.confirmPassword('Secret1!', 'Secret1!'), isNull);
    });

    test('returns error when values differ', () {
      expect(Validators.confirmPassword('abc', 'xyz'), isNotNull);
    });

    test('returns error when empty', () {
      expect(Validators.confirmPassword('', 'Secret1!'), isNotNull);
      expect(Validators.confirmPassword(null, 'Secret1!'), isNotNull);
    });
  });

  group('Validators — minLength', () {
    test('returns null when length meets minimum', () {
      expect(Validators.minLength('Hello', 5, 'Name'), isNull);
      expect(Validators.minLength('Hello World', 5, 'Name'), isNull);
    });

    test('returns error when length is below minimum', () {
      expect(Validators.minLength('Hi', 5, 'Name'), isNotNull);
      expect(Validators.minLength(null, 5, 'Name'), isNotNull);
    });

    test('error message includes the field name', () {
      final msg = Validators.minLength('ab', 5, 'Username');
      expect(msg, contains('Username'));
    });
  });

  // ---------------------------------------------------------------------------
  // ModuleModel
  // ---------------------------------------------------------------------------

  group('ModuleModel — serialisation', () {
    test('fromJson / toJson round-trip is stable', () {
      final now = DateTime.now().toUtc();
      final json = {
        'id': 'mod-1',
        'user_id': 'user-1',
        'name': 'Anatomy',
        'color': '#FF0000',
        'semester': 'Semester 1',
        'is_active': true,
        'created_at': now.toIso8601String(),
      };
      final model = ModuleModel.fromJson(json);
      final restored = ModuleModel.fromJson(model.toJson());

      expect(restored.id, model.id);
      expect(restored.name, model.name);
      expect(restored.color, model.color);
      expect(restored.semester, model.semester);
      expect(restored.isActive, model.isActive);
    });

    test('copyWith overrides only specified fields', () {
      final original = ModuleModel(
        id: 'mod-1',
        userId: 'u-1',
        name: 'Anatomy',
        isActive: true,
        createdAt: DateTime(2024),
      );
      final copy = original.copyWith(name: 'Physiology');

      expect(copy.name, 'Physiology');
      expect(copy.id, original.id);
      expect(copy.isActive, original.isActive);
    });
  });

  // ---------------------------------------------------------------------------
  // ProfileModel
  // ---------------------------------------------------------------------------

  group('ProfileModel — serialisation', () {
    test('fromJson handles optional fields gracefully', () {
      final json = {
        'id': 'user-1',
        'streak_count': 3,
        'created_at': DateTime(2024).toIso8601String(),
        'updated_at': DateTime(2024).toIso8601String(),
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, 'user-1');
      expect(profile.streakCount, 3);
      expect(profile.name, isNull);
      expect(profile.course, isNull);
    });

    test('fromJson maps all fields and toJson round-trips correctly', () {
      final payload = {
        'id': 'user-1',
        'name': 'Test Student',
        'course': 'MBBS',
        'year_level': 3,
        'prime_study_time': 'night',
        'study_hours_per_day': 4,
        'study_preference': 'alone',
        'avatar_url': 'https://example.com/avatar.png',
        'streak_count': 7,
        'last_study_date': '2026-04-29',
        'created_at': '2026-04-28T10:00:00.000Z',
        'updated_at': '2026-04-29T10:00:00.000Z',
      };

      final profile = ProfileModel.fromJson(payload);

      expect(profile.id, 'user-1');
      expect(profile.name, 'Test Student');
      expect(profile.course, 'MBBS');
      expect(profile.yearLevel, 3);
      expect(profile.primeStudyTime, 'night');
      expect(profile.studyHoursPerDay, 4);
      expect(profile.studyPreference, 'alone');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.streakCount, 7);
      expect(profile.lastStudyDate, DateTime.parse('2026-04-29'));

      final encoded = profile.toJson();
      expect(encoded['id'], 'user-1');
      expect(encoded['name'], 'Test Student');
      expect(encoded['streak_count'], 7);
      expect(encoded['last_study_date'], '2026-04-29');
    });
  });
}
