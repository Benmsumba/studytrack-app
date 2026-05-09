import 'package:flutter/foundation.dart';

import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralised logger. Use the static helpers — never call debugPrint directly.
///
/// Log levels:
///   d → debug   (dev builds only)
///   i → info    (always shown in debug; stripped in release)
///   w → warning (always captured; forwarded to Sentry as breadcrumb)
///   e → error   (always captured; forwarded to Sentry with stack trace)
class AppLogger {
  AppLogger._();

  static bool _sentryEnabled = false;

  /// Call once during bootstrap after Sentry is initialised.
  static void enableSentry() => _sentryEnabled = true;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static void d(String tag, String message) {
    assert(() {
      _print('D', tag, message);
      return true;
    }());
  }

  static void i(String tag, String message) {
    if (kDebugMode) _print('I', tag, message);
    if (_sentryEnabled) {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(message: '[$tag] $message', level: SentryLevel.info),
        ),
      );
    }
  }

  static void w(String tag, String message, [Object? error]) {
    _print('W', tag, error != null ? '$message — $error' : message);
    if (_sentryEnabled) {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: '[$tag] $message',
            level: SentryLevel.warning,
            data: error != null ? {'error': error.toString()} : null,
          ),
        ),
      );
    }
  }

  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) {
    _print('E', tag, error != null ? '$message\n$error' : message);
    if (stack != null) _print('E', tag, stack.toString());
    if (_sentryEnabled && error != null) {
      unawaited(Sentry.captureException(error, stackTrace: stack));
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  static void _print(String level, String tag, String message) {
    // debugPrint handles long strings by splitting across log lines.
    debugPrint('[$level/$tag] $message');
  }
}
