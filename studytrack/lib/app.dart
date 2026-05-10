import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/services/analytics_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_error_boundary.dart';
import 'core/widgets/offline_status_banner.dart';
import 'features/ai_tutor/screens/ai_tutor_screen.dart';
import 'features/ai_tutor/screens/quiz_screen.dart';
import 'features/auth/controllers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/groups/screens/group_chat_screen.dart';
import 'features/groups/screens/group_detail_screen.dart';
import 'features/groups/screens/groups_screen.dart';
import 'features/groups/screens/topic_chat_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/main_shell.dart';
import 'features/modules/screens/module_detail_screen.dart';
import 'features/modules/screens/modules_screen.dart';
import 'features/modules/screens/topic_detail_screen.dart';
import 'features/legal/screens/privacy_policy_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/progress/screens/analytics_screen.dart';
import 'features/progress/screens/exam_countdown_screen.dart';
import 'features/progress/screens/progress_screen.dart';
import 'features/progress/screens/weekly_wrapped_screen.dart';
import 'features/settings/controllers/settings_provider.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/timetable/screens/study_session_screen.dart';
import 'features/timetable/screens/timetable_screen.dart';
import 'features/update/widgets/update_overlay.dart';
import 'features/voice_notes/screens/voice_notes_screen.dart';

const _publicRoutes = {'/splash', '/login', '/signup', '/otp-login'};

String? resolveAppRedirect({
  required String location,
  required bool isSupabaseConfigured,
  required bool hasUser,
  required bool onboardingComplete,
}) {
  if (_publicRoutes.contains(location)) {
    return null;
  }

  if (!isSupabaseConfigured || !hasUser) {
    return '/login';
  }

  if (!onboardingComplete && location != '/onboarding') {
    return '/onboarding';
  }

  if (onboardingComplete && location == '/onboarding') {
    return '/home/dashboard';
  }

  if (location == '/home') {
    return '/home/dashboard';
  }

  return null;
}

class StudyTrackApp extends StatelessWidget {
  const StudyTrackApp({required this.authProvider, super.key});

  final AuthProvider authProvider;


  // refreshListenable is intentionally omitted; redirect decisions are based
  // on AuthProvider state updates triggered by auth flows and splash refresh.
  GoRouter _buildRouter() => GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    observers: [_AnalyticsObserver()],
    redirect: (context, state) async {
      final location = state.matchedLocation;

      if (_publicRoutes.contains(location)) {
        return null;
      }

      final isSupabaseConfigured = AppConstants.isSupabaseConfigured;
      final hasUser = isSupabaseConfigured && authProvider.isAuthenticated;
      final isAuthUnknown = authProvider.status == AuthStatus.unknown;

      if (isAuthUnknown) {
        return null;
      }

      if (!isSupabaseConfigured || !hasUser) {
        return '/login';
      }

      final preferences = await SharedPreferences.getInstance();
      final onboardingComplete =
          preferences.getBool('onboarding_complete') ?? false;

      return resolveAppRedirect(
        location: location,
        isSupabaseConfigured: isSupabaseConfigured,
        hasUser: hasUser,
        onboardingComplete: onboardingComplete,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp-login',
        builder: (context, state) => const OtpLoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),
      GoRoute(path: '/home', redirect: (context, state) => '/home/dashboard'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/dashboard',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/timetable',
                builder: (context, state) => const TimetableScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/modules',
                builder: (context, state) => const ModulesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/groups',
                builder: (context, state) => const GroupsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/modules/:moduleId',
        builder: (context, state) =>
            ModuleDetailScreen(moduleId: state.pathParameters['moduleId']!),
      ),
      GoRoute(
        path: '/topics/:topicId',
        builder: (context, state) =>
            TopicDetailScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: '/topics/:topicId/ai-tutor',
        builder: (context, state) =>
            AiTutorScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: '/topics/:topicId/quiz',
        builder: (context, state) =>
            QuizScreen(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: '/study-session',
        builder: (context, state) => const StudySessionScreen(),
      ),
      GoRoute(
        path: '/exam-countdown',
        builder: (context, state) => const ExamCountdownScreen(),
      ),
      GoRoute(
        path: '/weekly-wrapped',
        builder: (context, state) => const WeeklyWrappedScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/voice-notes',
        builder: (context, state) => const VoiceNotesScreen(),
      ),
      GoRoute(
        path: '/group/:groupId',
        builder: (context, state) => GroupDetailScreen(
          groupId: state.pathParameters['groupId']!,
          group: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/group/:groupId/chat',
        builder: (context, state) => GroupChatScreen(
          groupId: state.pathParameters['groupId']!,
          group: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/topics/:topicId/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TopicChatScreen(
            topicId: state.pathParameters['topicId']!,
            topicName: extra?['topicName']?.toString(),
            moduleName: extra?['moduleName']?.toString(),
            groupName: extra?['groupName']?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>(
      (settings) => settings.materialThemeMode,
    );

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightTheme = AppTheme.light(dynamicColorScheme: lightDynamic);
        final darkTheme = AppTheme.dark(dynamicColorScheme: darkDynamic);

        return AppErrorBoundary(
          child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: _buildRouter(),
          title: 'StudyTrack',
          themeMode: themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: isDark
                    ? Brightness.dark
                    : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
              child: Stack(
                children: [
                  OfflineStatusBanner(child: child ?? const SizedBox.shrink()),
                  const UpdateOverlay(),
                ],
              ),
            );
          },
        ),  // MaterialApp.router
        );  // AppErrorBoundary
      },
    );
  }
}

// ── Analytics screen-view observer ───────────────────────────────────────────

class _AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _record(newRoute);
  }

  void _record(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      Analytics.screen(name);
    }
  }
}
