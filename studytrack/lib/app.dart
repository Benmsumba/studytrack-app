import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_welcome_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/ai_tutor/screens/ai_tutor_screen.dart';
import 'features/ai_tutor/screens/quiz_screen.dart';
import 'features/groups/screens/group_chat_screen.dart';
import 'features/groups/screens/group_detail_screen.dart';
import 'features/groups/screens/groups_screen.dart';
import 'features/groups/screens/topic_chat_screen.dart';
import 'features/home/screens/main_shell.dart';
import 'features/modules/screens/module_detail_screen.dart';
import 'features/modules/screens/modules_screen.dart';
import 'features/modules/screens/topic_detail_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/screens/onboarding_steps_2356.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/progress/screens/progress_screen.dart';
import 'features/progress/screens/weekly_wrapped_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/timetable/screens/exam_countdown_screen.dart';
import 'features/timetable/screens/study_session_screen.dart';
import 'features/timetable/screens/timetable_screen.dart';
import 'core/widgets/offline_status_banner.dart';
import 'features/update/widgets/update_overlay.dart';

const _publicRoutes = {'/splash', '/login', '/signup', '/onboarding-welcome'};

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
    return '/home/timetable';
  }

  if (location == '/home') {
    return '/home/timetable';
  }

  return null;
}

// Bridges a Stream into a ChangeNotifier so GoRouter re-evaluates its
// redirect function whenever the auth state changes (e.g. email confirmed).
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class StudyTrackApp extends StatelessWidget {
  const StudyTrackApp({super.key});

  static ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7C3AED),
        secondary: Color(0xFF06B6D4),
        surface: Color(0xFF16161E),
        error: Color(0xFFFF5252),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        headlineSmall: AppTextStyles.headingSmall,
        titleLarge: AppTextStyles.headingSmall,
        titleMedium: AppTextStyles.label,
        titleSmall: AppTextStyles.labelSecondary,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),
    );
  }

  // refreshListenable is set only when Supabase is configured so we don't
  // access Supabase.instance before it has been initialized.
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: AppConstants.isSupabaseConfigured
        ? _GoRouterRefreshStream(
            Supabase.instance.client.auth.onAuthStateChange,
          )
        : null,
    redirect: (context, state) async {
      final location = state.matchedLocation;

      if (_publicRoutes.contains(location)) {
        return null;
      }

      final isSupabaseConfigured = AppConstants.isSupabaseConfigured;
      final hasUser =
          isSupabaseConfigured &&
          Supabase.instance.client.auth.currentUser != null;

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
        path: '/onboarding-welcome',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding-steps-2356',
        builder: (context, state) => const OnboardingSteps2356Screen(),
      ),
      GoRoute(path: '/home', redirect: (context, state) => '/home/timetable'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
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
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    routerConfig: _router,
    title: 'StudyTrack',
    theme: _buildTheme(),
    builder: (context, child) => Stack(
      children: [
        OfflineStatusBanner(child: child ?? const SizedBox.shrink()),
        const UpdateOverlay(),
      ],
    ),
  );
}
