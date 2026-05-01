import 'package:flutter/foundation.dart';

/// Environment configuration for the application.
///
/// This class reads configuration from dart-define variables passed at
/// build time.
class Environment {
  static const String _supabaseUrlKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  static const String _geminiApiKeyKey = 'GEMINI_API_KEY';
  static const String _appEnvKey = 'APP_ENV';

  // Fallback values for local development
  static const String _defaultSupabaseUrl = String.fromEnvironment(
    _supabaseUrlKey,
    defaultValue: '',
  );

  static const String _defaultSupabaseAnonKey = String.fromEnvironment(
    _supabaseAnonKeyKey,
    defaultValue: '',
  );

  static const String _defaultGeminiApiKey = String.fromEnvironment(
    _geminiApiKeyKey,
    defaultValue: '',
  );

  static const String _defaultAppEnv = String.fromEnvironment(
    _appEnvKey,
    defaultValue: 'development',
  );

  /// Get Supabase URL
  static String get supabaseUrl => _defaultSupabaseUrl;

  /// Get Supabase anonymous key
  static String get supabaseAnonKey => _defaultSupabaseAnonKey;

  /// Get Gemini API key
  static String get geminiApiKey => _defaultGeminiApiKey;

  /// Get application environment
  static String get appEnv => _defaultAppEnv;

  /// Check if running in production
  static bool get isProduction => appEnv == 'production';

  /// Check if running in test
  static bool get isTest => appEnv == 'test';

  /// Check if all required environment variables are configured
  static bool get isFullyConfigured {
    final validUrl =
        supabaseUrl.isNotEmpty &&
        supabaseUrl.startsWith('https://') &&
        supabaseUrl.contains('supabase.co');

    final validAnonKey = supabaseAnonKey.isNotEmpty;

    return validUrl && validAnonKey;
  }

  /// Validate environment configuration
  /// Throws [StateError] if configuration is invalid
  static void validate() {
    if (!isFullyConfigured) {
      throw StateError(
        'Environment configuration is incomplete. '
        'Please provide SUPABASE_URL and SUPABASE_ANON_KEY via '
        '--dart-define-from-file=.env or update AppConstants.',
      );
    }

    debugPrint('✓ Environment configuration is valid');
  }

  /// Debug log environment status
  static void logStatus() {
    debugPrint('========== Environment Status ==========');
    debugPrint('App Environment: $appEnv');
    debugPrint('Is Production: $isProduction');
    debugPrint(
      'Supabase URL: '
      '${supabaseUrl.contains('https') ? '✓ Configured' : '✗ Missing'}',
    );
    debugPrint(
      'Supabase Anon Key: '
      '${supabaseAnonKey.isNotEmpty ? '✓ Configured' : '✗ Missing'}',
    );
    debugPrint(
      'Gemini API Key: '
      '${geminiApiKey.isNotEmpty ? '✓ Configured' : '✗ Missing'}',
    );
    debugPrint('========================================');
  }
}
