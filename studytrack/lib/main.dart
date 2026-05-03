import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/app_update_service.dart';
import 'core/services/crash_reporter.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync_service.dart';
import 'core/utils/service_locator.dart';
import 'features/auth/controllers/auth_provider.dart';
import 'features/groups/controllers/groups_provider.dart';
import 'features/modules/controllers/modules_provider.dart';
import 'features/notifications/controllers/notification_provider.dart';
import 'features/profile/controllers/profile_provider.dart';
import 'features/progress/controllers/progress_provider.dart';
import 'features/settings/controllers/settings_provider.dart';
import 'features/timetable/controllers/timetable_provider.dart';
import 'features/timetable/controllers/topic_module_provider.dart';
import 'features/update/controllers/update_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  if (kReleaseMode) {
    debugPrint = (message, {wrapWidth}) {};
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Color(0xFF1F1F2B),
    ),
  );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReporter.report(details.exception, details.stack ?? StackTrace.empty);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashReporter.report(error, stack);
    return true;
  };

  await runZonedGuarded(() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConstants.resolvedSentryDsn;
        options.tracesSampleRate = 0.0;
        options.sendDefaultPii = false;
        options.enableAutoSessionTracking = false;
      },
      appRunner: () async {
        CrashReporter.configure((error, stack) {
          if (!AppConstants.isSentryConfigured) {
            return;
          }
          unawaited(Sentry.captureException(error, stackTrace: stack));
        });
        await _bootstrapApp();
      },
    );
  }, CrashReporter.report);
}

Future<void> _bootstrapApp() async {
  // Initialize service locator for dependency injection
  await setupServiceLocator();

  if (AppConstants.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConstants.resolvedSupabaseUrl,
        anonKey: AppConstants.resolvedSupabaseAnonKey,
      );
      await _completeAuthCodeExchangeIfPresent();
    } on Object catch (error, stack) {
      CrashReporter.report(error, stack);
    }
  } else {
    if (kReleaseMode) {
      throw StateError(
        'Supabase configuration is required for release builds.',
      );
    }
    debugPrint(
      'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY '
      'via --dart-define or update AppConstants.',
    );
  }

  await _safeInit(OfflineSyncService.instance.initialize);

  final notificationService = NotificationService();
  await _safeInit(notificationService.initialize);

  final authProvider = AuthProvider();
  var lastAuthState = authProvider.isAuthenticated;

  if (AppConstants.isSupabaseConfigured && lastAuthState) {
    await _safeInit(notificationService.bootstrapForCurrentUser);
  }

  authProvider.addListener(() {
    final currentAuthState = authProvider.isAuthenticated;
    if (!lastAuthState && currentAuthState) {
      unawaited(_safeInit(notificationService.bootstrapForCurrentUser));
    }
    lastAuthState = currentAuthState;
  });

  final updateProvider = UpdateProvider(AppUpdateService());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: OfflineSyncService.instance),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ModulesProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        ChangeNotifierProvider(create: (_) => TopicModuleProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider<UpdateProvider>.value(value: updateProvider),
      ],
      child: StudyTrackApp(authProvider: authProvider),
    ),
  );

  unawaited(updateProvider.checkForUpdate());
}

Future<void> _safeInit(Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (error, stack) {
    CrashReporter.report(error, stack);
  }
}

Future<void> _completeAuthCodeExchangeIfPresent() async {
  final authCode = Uri.base.queryParameters['code'];
  if (authCode == null || authCode.isEmpty) {
    return;
  }

  try {
    await Supabase.instance.client.auth.exchangeCodeForSession(authCode);
  } on Object catch (error, stack) {
    CrashReporter.report(error, stack);
  }
}
