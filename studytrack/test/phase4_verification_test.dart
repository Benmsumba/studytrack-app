import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studytrack/core/constants/app_constants.dart';
import 'package:studytrack/verification_test.dart';

void main() {
  test('Phase 4 verification helper runs', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );

    await runPhase4Check();
  });
}