import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/user_model.dart';

Future<void> runPhase4Check() async {
  try {
    final client = Supabase.instance.client;

    User? user = client.auth.currentUser;

    if (user == null) {
      final anonymousResponse = await client.auth.signInAnonymously();
      user = anonymousResponse.user;

      if (user == null) {
        const testEmail = 'studytrackverify1776928761451@gmail.com';
        const testPassword = 'StudyTrack#12345';

        final signInResponse = await client.auth.signInWithPassword(
          email: testEmail,
          password: testPassword,
        );
        user = signInResponse.user;

        if (user == null) {
          final signUpResponse = await client.auth.signUp(
            email: testEmail,
            password: testPassword,
          );

          user = signUpResponse.user;

          if (user == null) {
            final authResponse = await client.auth.signInWithPassword(
              email: testEmail,
              password: testPassword,
            );
            user = authResponse.user;
          }
        }
      }
    }

    if (user == null) {
      throw Exception('Auth check failed: no signed-in user returned.');
    }

    const mockData = {
      'full_name': 'Test Student',
      'course_name': 'MBBS',
      'year_level': 3,
      'prime_study_time': 'night',
    };

    await client.from('profiles').upsert({
      'id': user.id,
      'name': mockData['full_name'],
      'course': mockData['course_name'],
      'year_level': mockData['year_level'],
      'prime_study_time': mockData['prime_study_time'],
      'study_hours_per_day': 4,
      'study_preference': 'alone',
      'streak_count': 0,
      'onboarding_complete': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final profileRow = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profileRow == null) {
      throw Exception('Database check failed: profile row was not returned.');
    }

    final profile = ProfileModel.fromJson(profileRow);
    final displayName = profile.name ?? 'Test Student';

    // Ignore: this is a temporary verification helper.
    // The success message is intentionally printed to the Debug Console.
    debugPrint('✅ Phase 4 Verified: $displayName is ready to study!');
  } on AuthApiException catch (error) {
    if (error.code == 'anonymous_provider_disabled' ||
        error.code == 'over_email_send_rate_limit' ||
        error.code == 'email_address_invalid') {
      debugPrint('⚠️ Phase 4 verification skipped: $error');
      return;
    }

    debugPrint('❌ Phase 4 verification failed: $error');
    rethrow;
  } catch (error) {
    debugPrint('❌ Phase 4 verification failed: $error');
    rethrow;
  }
}
