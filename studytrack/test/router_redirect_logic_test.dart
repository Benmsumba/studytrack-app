import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/app.dart';

void main() {
  group('resolveAppRedirect', () {
    test('allows public routes', () {
      expect(
        resolveAppRedirect(
          location: '/login',
          isSupabaseConfigured: false,
          hasUser: false,
          onboardingComplete: false,
        ),
        isNull,
      );

      expect(
        resolveAppRedirect(
          location: '/splash',
          isSupabaseConfigured: false,
          hasUser: false,
          onboardingComplete: false,
        ),
        isNull,
      );
    });

    test('redirects to login when supabase is not configured', () {
      expect(
        resolveAppRedirect(
          location: '/home/timetable',
          isSupabaseConfigured: false,
          hasUser: true,
          onboardingComplete: true,
        ),
        '/login',
      );
    });

    test('redirects to login when user is not authenticated', () {
      expect(
        resolveAppRedirect(
          location: '/home/timetable',
          isSupabaseConfigured: true,
          hasUser: false,
          onboardingComplete: true,
        ),
        '/login',
      );
    });

    test('redirects to onboarding when onboarding is incomplete', () {
      expect(
        resolveAppRedirect(
          location: '/home/modules',
          isSupabaseConfigured: true,
          hasUser: true,
          onboardingComplete: false,
        ),
        '/onboarding',
      );

      expect(
        resolveAppRedirect(
          location: '/onboarding',
          isSupabaseConfigured: true,
          hasUser: true,
          onboardingComplete: false,
        ),
        isNull,
      );
    });

    test('redirects onboarding route to home when complete', () {
      expect(
        resolveAppRedirect(
          location: '/onboarding',
          isSupabaseConfigured: true,
          hasUser: true,
          onboardingComplete: true,
        ),
        '/home/timetable',
      );
    });

    test('redirects home shell root to timetable', () {
      expect(
        resolveAppRedirect(
          location: '/home',
          isSupabaseConfigured: true,
          hasUser: true,
          onboardingComplete: true,
        ),
        '/home/timetable',
      );
    });

    test('allows authenticated and onboarded private routes', () {
      expect(
        resolveAppRedirect(
          location: '/home/progress',
          isSupabaseConfigured: true,
          hasUser: true,
          onboardingComplete: true,
        ),
        isNull,
      );
    });
  });
}
