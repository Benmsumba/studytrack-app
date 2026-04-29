import 'package:flutter/foundation.dart';

typedef CrashReportCallback = void Function(Object error, StackTrace stack);

/// Lightweight crash-reporting abstraction.
///
/// Wire up a real reporter (Sentry, Firebase Crashlytics, etc.) once at
/// startup by calling [configure], then every unhandled error in the app
/// will route through [report] automatically.
///
/// Example with Sentry:
/// ```dart
/// CrashReporter.configure((error, stack) {
///   Sentry.captureException(error, stackTrace: stack);
/// });
/// ```
class CrashReporter {
  CrashReporter._();

  static CrashReportCallback? _callback;

  static void configure(CrashReportCallback callback) {
    _callback = callback;
  }

  static void report(Object error, StackTrace stack) {
    if (_callback != null) {
      try {
        _callback!(error, stack);
      } catch (_) {
        // Never let the reporter itself crash the app.
      }
      return;
    }
    // Fallback: log to console in all modes so nothing is silently swallowed.
    debugPrint('[CrashReporter] $error');
    debugPrintStack(stackTrace: stack, maxFrames: 20);
  }
}
