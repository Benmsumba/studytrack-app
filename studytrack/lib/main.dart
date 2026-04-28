import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync_service.dart';
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

  if (AppConstants.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConstants.resolvedSupabaseUrl,
      anonKey: AppConstants.resolvedSupabaseAnonKey,
    );
    await _completeAuthCodeExchangeIfPresent();
  } else {
    debugPrint(
      'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define or update AppConstants.',
    );
  }

  await OfflineSyncService.instance.initialize();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.bootstrapForCurrentUser();

  Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    if (event.session != null) {
      unawaited(notificationService.bootstrapForCurrentUser());
    }
  });

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
