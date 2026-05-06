import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_spacing.dart';
import 'core/constants/app_text_styles.dart';
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
import 'features/home/screens/main_shell.dart';
import 'features/modules/screens/module_detail_screen.dart';
import 'features/modules/screens/modules_screen.dart';
import 'features/modules/screens/topic_detail_screen.dart';
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
    return '/home/timetable';
  }

  if (location == '/home') {
    return '/home/timetable';
  }

  return null;
}

class StudyTrackApp extends StatelessWidget {
  const StudyTrackApp({required this.authProvider, super.key});

  final AuthProvider authProvider;

  static ThemeData _buildDarkTheme({ColorScheme? colorScheme}) {
    final scheme =
        colorScheme ??
        const ColorScheme.dark(
          primary: AppColors.neonViolet,
          onPrimary: Colors.white,
          secondary: AppColors.neonCyan,
          onSecondary: Colors.white,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimary,
          error: AppColors.danger,
          onError: Colors.white,
          surfaceContainerHighest: AppColors.surfaceElevated,
          outline: AppColors.border,
          outlineVariant: AppColors.borderSoft,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      canvasColor: AppColors.backgroundDark,
      dividerColor: scheme.outlineVariant,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.headingMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        actionTextColor: AppColors.neonCyan,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.bodyMediumSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonViolet,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.neonCyan,
          textStyle: AppTextStyles.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textGlow,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.neonViolet.withValues(alpha: 0.22),
        disabledColor: AppColors.surfaceElevated,
        labelStyle: AppTextStyles.label,
        secondaryLabelStyle: AppTextStyles.label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        modalBackgroundColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.neonCyan,
        linearTrackColor: AppColors.borderSoft,
        circularTrackColor: AppColors.borderSoft,
      ),
    );

    final baseTextTheme = base.textTheme;
    final basePrimaryTextTheme = base.primaryTextTheme;

    return base.copyWith(
      textTheme: baseTextTheme.copyWith(
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
      primaryTextTheme: basePrimaryTextTheme.copyWith(
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
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData _buildLightTheme({ColorScheme? colorScheme}) {
    final scheme =
        colorScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.neonViolet,
          brightness: Brightness.light,
          surface: const Color(0xFFF7F8FC),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      canvasColor: const Color(0xFFF7F8FC),
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );

    return base.copyWith(visualDensity: VisualDensity.standard);
  }

  // refreshListenable is intentionally omitted; redirect decisions are based
  // on AuthProvider state updates triggered by auth flows and splash refresh.
  GoRouter _buildRouter() => GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
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
    ],
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>(
      (settings) => settings.materialThemeMode,
    );

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightTheme = _buildLightTheme(colorScheme: lightDynamic);
        final darkTheme = _buildDarkTheme(colorScheme: darkDynamic);

        return MaterialApp.router(
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
        );
      },
    );
  }
}
