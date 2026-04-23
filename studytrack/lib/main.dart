import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConstants.supabaseUrl != 'YOUR_SUPABASE_URL' &&
      AppConstants.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY') {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  runApp(const StudyTrackApp());
}
