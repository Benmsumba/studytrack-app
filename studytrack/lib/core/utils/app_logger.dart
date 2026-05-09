import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralised logger. Use the static helpers — never call debugPrint directly.
/// Routes to dart:developer (visible in DevTools) and optionally to Sentry.
class AppLogger {
  AppLogger._();

  static bool _sentryEnabled = false;

  /// Call once during bootstrap after Sentry is initialised.
  static void enableSentry() => _sentryEnabled = true;

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) return;
    developer.log(
      message,
      name: 'StudyTrack',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'StudyTrack',
      error: error,
      stackTrace: stackTrace,
    );
    if (_sentryEnabled) {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(message: message, level: SentryLevel.info),
        ),
      );
    }
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'StudyTrack',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    if (_sentryEnabled) {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: message,
            level: SentryLevel.warning,
            data: error != null ? {'error': error.toString()} : null,
          ),
        ),
      );
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'StudyTrack',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (_sentryEnabled && error != null) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    }
  }
}
