import 'dart:async';
import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  await runZonedGuarded(
    () async {
      await _bootstrapApp();
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stack);
    },
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
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stack);
    }
  } else {
    debugPrint(
      'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define or update AppConstants.',
    );
  }

  await _safeInit(() => OfflineSyncService.instance.initialize());

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
      ],
      child: const StudyTrackApp(),
    ),
  );
}

Future<void> _safeInit(Future<void> Function() action) async {
  try {
    await action();
  } catch (error, stack) {
    debugPrint('Startup step failed: $error');
    debugPrintStack(stackTrace: stack);
  }
}

Future<void> _completeAuthCodeExchangeIfPresent() async {
  final authCode = Uri.base.queryParameters['code'];
  if (authCode == null || authCode.isEmpty) {
    return;
  }

  try {
    await Supabase.instance.client.auth.exchangeCodeForSession(authCode);
  } catch (error) {
    debugPrint('Auth code exchange failed: $error');
  }
}
