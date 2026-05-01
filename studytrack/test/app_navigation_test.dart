import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/app.dart';

void main() {
  group('StudyTrackApp Navigation', () {
    testWidgets('resolveAppRedirect allows public routes without auth', (
      tester,
    ) async {
      const publicRoutes = ['/splash', '/login', '/signup'];

      for (final route in publicRoutes) {
        final result = resolveAppRedirect(
          location: route,
          isSupabaseConfigured: false,
          hasUser: false,
          onboardingComplete: false,
        );
        expect(
          result,
          isNull,
          reason: 'Public route $route should not redirect',
        );
      }
    });

    test('resolveAppRedirect redirects unauthenticated users to login', () {
      final result = resolveAppRedirect(
        location: '/home',
        isSupabaseConfigured: true,
        hasUser: false,
        onboardingComplete: false,
      );
      expect(result, '/login');
    });

    test(
      'resolveAppRedirect redirects incomplete onboarding to /onboarding',
      () {
        final result = resolveAppRedirect(
          location: '/home',
          isSupabaseConfigured: true,
          hasUser: true,
          onboardingComplete: false,
        );
        expect(result, '/onboarding');
      },
    );

    test(
      'resolveAppRedirect redirects completed onboarding away from /onboarding',
      () {
        final result = resolveAppRedirect(
          location: '/onboarding',
          isSupabaseConfigured: true,
          hasUser: true,
          onboardingComplete: true,
        );
        expect(result, '/home/timetable');
      },
    );

    test(
      'resolveAppRedirect allows authenticated + onboarded users to access routes',
      () {
        final result = resolveAppRedirect(
          location: '/home/modules',
          isSupabaseConfigured: true,
          hasUser: true,
          onboardingComplete: true,
        );
        expect(result, isNull);
      },
    );

    test('resolveAppRedirect redirects Supabase not configured to login', () {
      final result = resolveAppRedirect(
        location: '/home',
        isSupabaseConfigured: false,
        hasUser: true,
        onboardingComplete: true,
      );
      expect(result, '/login');
    });

    test('resolveAppRedirect normalizes /home to /home/timetable', () {
      final result = resolveAppRedirect(
        location: '/home',
        isSupabaseConfigured: true,
        hasUser: true,
        onboardingComplete: true,
      );
      expect(result, '/home/timetable');
    });
  });
}
