import 'dart:async';
import 'package:flutter/foundation.dart';
import 'crash_reporter.dart';

/// Error severity levels for categorization
enum ErrorSeverity { info, warning, error, critical }

/// Represents a tracked error event
class ErrorEvent {
  ErrorEvent({
    required this.timestamp,
    required this.message,
    required this.severity,
    this.exception,
    this.stackTrace,
    this.context,
    this.userId,
  });

  final DateTime timestamp;
  final String message;
  final ErrorSeverity severity;
  final Object? exception;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final String? userId;

  @override
  String toString() =>
      '''
ErrorEvent(
  timestamp: $timestamp,
  severity: $severity,
  message: $message,
  exception: $exception,
  context: $context,
)''';
}

/// Comprehensive error handling and monitoring service
/// Tracks errors, monitors app health, and integrates with crash reporting
class ErrorHandler {
  factory ErrorHandler() => _instance;

  ErrorHandler._internal();
  static final ErrorHandler _instance = ErrorHandler._internal();

  final List<ErrorEvent> _errorHistory = [];
  final List<StreamController<ErrorEvent>> _errorListeners = [];
  bool _initialized = false;
  String? _currentUserId;

  // Configuration
  static const int maxErrorHistorySize = 100;

  /// Initialize error handler
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('ErrorHandler initialized');
  }

  /// Set current user ID for error tracking context
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Record an error event
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.error,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final errorMessage = message ?? error.toString();
    final event = ErrorEvent(
      timestamp: DateTime.now(),
      message: errorMessage,
      severity: severity,
      exception: error,
      stackTrace: stackTrace,
      context: context,
      userId: _currentUserId,
    );

    // Add to history
    _errorHistory.add(event);
    if (_errorHistory.length > maxErrorHistorySize) {
      _errorHistory.removeAt(0);
    }

    // Notify listeners
    for (final listener in _errorListeners) {
      listener.add(event);
    }

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('🚨 ERROR [${severity.name.toUpperCase()}]: $errorMessage');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }

    // Report critical errors to crash reporter
    if (severity == ErrorSeverity.critical) {
      try {
        CrashReporter.report(error, stackTrace ?? StackTrace.current);
      } catch (e) {
        debugPrint('Failed to report crash: $e');
      }
    }
  }

  /// Record a warning event
  Future<void> recordWarning(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    await recordError(
      message,
      message: message,
      context: context,
      severity: ErrorSeverity.warning,
    );
  }

  /// Record an info event
  Future<void> recordInfo(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    await recordError(
      message,
      message: message,
      context: context,
      severity: ErrorSeverity.info,
    );
  }

  /// Get error history
  List<ErrorEvent> get errorHistory => List.unmodifiable(_errorHistory);

  /// Get recent errors
  List<ErrorEvent> getRecentErrors({int limit = 10}) {
    final errors = _errorHistory
        .where((e) => e.severity.index >= ErrorSeverity.error.index)
        .toList();
    return errors.length > limit
        ? errors.sublist(errors.length - limit)
        : errors;
  }

  /// Get error summary statistics
  Map<String, dynamic> getErrorSummary() {
    final totalErrors = _errorHistory.length;
    final bySeverity = <String, int>{};

    for (final severity in ErrorSeverity.values) {
      bySeverity[severity.name] = _errorHistory
          .where((e) => e.severity == severity)
          .length;
    }

    final recentErrors = getRecentErrors(limit: 10);
    final errorRatePerMinute = recentErrors.isEmpty
        ? 0.0
        : recentErrors.length /
              (DateTime.now()
                      .difference(recentErrors.first.timestamp)
                      .inMinutes +
                  1);

    return {
      'total_errors': totalErrors,
      'by_severity': bySeverity,
      'recent_errors_count': recentErrors.length,
      'error_rate_per_minute': errorRatePerMinute,
      'last_error': recentErrors.isNotEmpty
          ? {
              'message': recentErrors.last.message,
              'timestamp': recentErrors.last.timestamp.toIso8601String(),
              'severity': recentErrors.last.severity.name,
            }
          : null,
    };
  }

  /// Subscribe to error events
  Stream<ErrorEvent> onErrorOccurred() {
    final controller = StreamController<ErrorEvent>.broadcast();
    _errorListeners.add(controller);
    return controller.stream;
  }

  /// Clear error history
  void clearHistory() {
    _errorHistory.clear();
  }

  /// Get errors by severity
  List<ErrorEvent> getErrorsBySeverity(ErrorSeverity severity) =>
      _errorHistory.where((e) => e.severity == severity).toList();

  /// Check if there are critical errors
  bool hasCriticalErrors() =>
      _errorHistory.any((e) => e.severity == ErrorSeverity.critical);

  /// Dispose of all listeners
  void dispose() {
    for (final listener in _errorListeners) {
      listener.close();
    }
    _errorListeners.clear();
  }
}

/// Global error handler instance
final errorHandler = ErrorHandler();
