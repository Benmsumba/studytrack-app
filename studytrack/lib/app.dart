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
import 'features/home/screens/home_screen.dart';
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
    return '/home/dashboard';
  }

  if (location == '/home') {
    return '/home/dashboard';
  }

  return null;
}

/// 300 ms Fade Through transition — incoming page fades in while the outgoing
/// page fades out simultaneously, with a brief overlap that feels intentional
/// rather than mechanical. Replaces FadeUpwards/slide for a quieter feel.
class _FadeThroughTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeThroughTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      // Incoming: ease in over the full 300 ms.
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
      child: FadeTransition(
        // Outgoing: fade out quickly in the first third, leaving a brief
        // clean canvas before the next screen appears.
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
          ),
        ),
        child: child,
      ),
    );
  }
}

class StudyTrackApp extends StatelessWidget {
  const StudyTrackApp({required this.authProvider, super.key});

  final AuthProvider authProvider;

  // Quiet Luxury: always use the curated palette.
  // DynamicColorBuilder is kept as the structural wrapper but its generated
  // schemes are ignored — Material You would overwrite the chosen ochre signal.
  static ThemeData _buildDarkTheme() {
    const scheme = ColorScheme.dark(
      primary: AppColors.signal,
      onPrimary: AppColors.parchment,
      secondary: AppColors.signal,
      onSecondary: AppColors.parchment,
      tertiary: AppColors.signalLight,
      onTertiary: AppColors.parchment,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.parchment,
      surfaceContainerHighest: AppColors.surfaceElevated,
      onSurfaceVariant: AppColors.parchmentSecondary,
      error: AppColors.danger,
      onError: AppColors.parchment,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderDarkSoft,
      scrim: AppColors.obsidian,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.obsidian,
      canvasColor: AppColors.obsidian,
      dividerColor: AppColors.borderDarkSoft,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughTransitionsBuilder(),
          TargetPlatform.iOS: _FadeThroughTransitionsBuilder(),
          TargetPlatform.linux: _FadeThroughTransitionsBuilder(),
          TargetPlatform.macOS: _FadeThroughTransitionsBuilder(),
          TargetPlatform.windows: _FadeThroughTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.parchment,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.headingMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          // 0.5 px hairline border — materiality without shadow
          side: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.signalMuted,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.signal, size: 22);
          }
          return const IconThemeData(color: AppColors.parchmentMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.overlineSignal;
          }
          return AppTextStyles.caption;
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          side: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
        actionTextColor: AppColors.signal,
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
          borderSide: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.signal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 0.5),
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
          backgroundColor: AppColors.signal,
          foregroundColor: AppColors.parchment,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.signal,
          foregroundColor: AppColors.parchment,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.signal,
          textStyle: AppTextStyles.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.parchment,
          side: const BorderSide(color: AppColors.borderDark, width: 0.5),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.signalMuted,
        disabledColor: AppColors.surfaceElevated,
        labelStyle: AppTextStyles.label,
        secondaryLabelStyle: AppTextStyles.label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          side: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        modalBackgroundColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.signal,
        linearTrackColor: AppColors.borderDarkSoft,
        circularTrackColor: AppColors.borderDarkSoft,
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
      splashFactory: InkRipple.splashFactory,
    );
  }

  static ThemeData _buildLightTheme() {
    const scheme = ColorScheme.light(
      primary: AppColors.signal,
      onPrimary: Colors.white,
      secondary: AppColors.signal,
      onSecondary: Colors.white,
      tertiary: AppColors.signalLight,
      onTertiary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.inkPrimary,
      surfaceContainerHighest: AppColors.surfaceElevatedLight,
      onSurfaceVariant: AppColors.inkSecondary,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderLightSoft,
      scrim: AppColors.inkPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paperWhite,
      canvasColor: AppColors.paperWhite,
      dividerColor: AppColors.borderLightSoft,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughTransitionsBuilder(),
          TargetPlatform.iOS: _FadeThroughTransitionsBuilder(),
          TargetPlatform.linux: _FadeThroughTransitionsBuilder(),
          TargetPlatform.macOS: _FadeThroughTransitionsBuilder(),
          TargetPlatform.windows: _FadeThroughTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.inkPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.headingMediumLight,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.signalSubtle,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.signal, size: 22);
          }
          return IconThemeData(color: AppColors.inkMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.overlineSignal;
          }
          return AppTextStyles.caption.copyWith(color: AppColors.inkMuted);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevatedLight,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inkPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          side: const BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
        actionTextColor: AppColors.signal,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.signal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.inkSecondary),
        hintStyle: AppTextStyles.bodyMediumSecondary.copyWith(
          color: AppColors.inkMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.signal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.signal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.signal,
          textStyle: AppTextStyles.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkPrimary,
          side: const BorderSide(color: AppColors.borderLight, width: 0.5),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.inkPrimary),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevatedLight,
        selectedColor: AppColors.signalSubtle,
        disabledColor: AppColors.surfaceElevatedLight,
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.inkPrimary),
        secondaryLabelStyle: AppTextStyles.label.copyWith(
          color: AppColors.inkPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          side: const BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        modalBackgroundColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevatedLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.signal,
        linearTrackColor: AppColors.borderLightSoft,
        circularTrackColor: AppColors.borderLightSoft,
      ),
    );

    final baseTextTheme = base.textTheme;

    return base.copyWith(
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.inkPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.inkPrimary,
        ),
        headlineLarge: AppTextStyles.headingLargeLight,
        headlineMedium: AppTextStyles.headingMediumLight,
        headlineSmall: AppTextStyles.headingSmallLight,
        titleLarge: AppTextStyles.headingSmallLight,
        titleMedium: AppTextStyles.label.copyWith(color: AppColors.inkPrimary),
        titleSmall: AppTextStyles.labelSecondary.copyWith(
          color: AppColors.inkSecondary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.inkPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inkPrimary,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.inkPrimary,
        ),
        labelLarge: AppTextStyles.button.copyWith(color: AppColors.inkPrimary),
        labelMedium: AppTextStyles.label.copyWith(color: AppColors.inkPrimary),
        labelSmall: AppTextStyles.caption.copyWith(color: AppColors.inkMuted),
      ),
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
    );
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/profile',
                builder: (context, state) => const ProfileScreen(),
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
      // Quiet Luxury: ignore Material You dynamic schemes entirely.
      // Passing them would overwrite the curated Deep Ochre signal palette.
      builder: (_, __) {
        final lightTheme = _buildLightTheme();
        final darkTheme = _buildDarkTheme();

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
