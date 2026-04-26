import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

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

  runApp(const StudyTrackApp());
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
