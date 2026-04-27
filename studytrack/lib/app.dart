import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import 'features/profile/screens/profile_screen.dart';
import 'features/progress/screens/progress_screen.dart';
import 'features/progress/screens/weekly_wrapped_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/timetable/screens/exam_countdown_screen.dart';
import 'features/timetable/screens/study_session_screen.dart';
import 'features/timetable/screens/timetable_screen.dart';

class StudyTrackApp extends StatelessWidget {
  const StudyTrackApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final location = state.matchedLocation;
      const publicRoutes = {
        '/splash',
        '/login',
        '/signup',
        '/onboarding-welcome',
      };

      if (publicRoutes.contains(location)) {
        return null;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return '/login';
      }

      final preferences = await SharedPreferences.getInstance();
      final onboardingComplete =
          preferences.getBool('onboarding_complete') ?? false;

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
      GoRoute(path: '/home', redirect: (context, state) => '/home/timetable'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
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
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      title: 'StudyTrack',
    );
  }
}
