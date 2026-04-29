import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/crash_reporter.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync_service.dart';
import 'core/utils/service_locator.dart';
import 'core/services/app_update_service.dart';
import 'features/auth/controllers/auth_provider.dart';
import 'features/groups/controllers/groups_provider.dart';
import 'features/modules/controllers/modules_provider.dart';
import 'features/notifications/controllers/notification_provider.dart';
import 'features/profile/controllers/profile_provider.dart';
import 'features/progress/controllers/progress_provider.dart';
import 'features/settings/controllers/settings_provider.dart';
import 'features/timetable/controllers/timetable_provider.dart';
import 'features/update/controllers/update_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // To route crashes to Sentry, Firebase Crashlytics, or any other service,
  // call CrashReporter.configure() here before runZonedGuarded:
  //
  //   CrashReporter.configure((error, stack) {
  //     Sentry.captureException(error, stackTrace: stack);
  //   });

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReporter.report(details.exception, details.stack ?? StackTrace.empty);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashReporter.report(error, stack);
    return true;
  };

  await runZonedGuarded(
    () async {
      await _bootstrapApp();
    },
    CrashReporter.report,
  );
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
    } catch (error, stack) {
      CrashReporter.report(error, stack);
    }
  } else {
    debugPrint(
      'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define or update AppConstants.',
    );
  }

  await _safeInit(OfflineSyncService.instance.initialize);

  final notificationService = NotificationService();
  await _safeInit(notificationService.initialize);

  if (AppConstants.isSupabaseConfigured) {
    await _safeInit(notificationService.bootstrapForCurrentUser);

    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        unawaited(_safeInit(notificationService.bootstrapForCurrentUser));
      }
    });
  }

  final updateProvider = UpdateProvider(AppUpdateService());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: OfflineSyncService.instance),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ModulesProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider<UpdateProvider>.value(value: updateProvider),
      ],
      child: const StudyTrackApp(),
    ),
  );

  unawaited(updateProvider.checkForUpdate());
}

Future<void> _safeInit(Future<void> Function() action) async {
  try {
    await action();
  } catch (error, stack) {
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
  } catch (error, stack) {
    CrashReporter.report(error, stack);
  }
}
