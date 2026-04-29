import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/core/constants/app_constants.dart';
import 'package:studytrack/models/user_model.dart';

void main() {
  test('supabase defaults are treated as unconfigured', () {
    expect(AppConstants.isSupabaseConfigured, isFalse);
    expect(AppConstants.resolvedSupabaseUrl, 'YOUR_SUPABASE_URL');
    expect(AppConstants.resolvedSupabaseAnonKey, 'YOUR_SUPABASE_ANON_KEY');
  });

  test('profile model maps verification payloads correctly', () {
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
    expect(encoded['course'], 'MBBS');
    expect(encoded['year_level'], 3);
    expect(encoded['prime_study_time'], 'night');
    expect(encoded['study_hours_per_day'], 4);
    expect(encoded['study_preference'], 'alone');
    expect(encoded['avatar_url'], 'https://example.com/avatar.png');
    expect(encoded['streak_count'], 7);
    expect(encoded['last_study_date'], '2026-04-29');
  });
}
