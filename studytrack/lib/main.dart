import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/controllers/auth_provider.dart';
import 'features/groups/controllers/groups_provider.dart';
import 'features/modules/controllers/modules_provider.dart';
import 'features/progress/controllers/progress_provider.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ModulesProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
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
