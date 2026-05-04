import 'dart:async';
import 'package:flutter/foundation.dart';

/// Represents a tracked user event for analytics and monitoring
class UserEvent {
  UserEvent({
    required this.timestamp,
    required this.eventName,
    this.userId,
    this.properties,
  });

  final DateTime timestamp;
  final String eventName;
  final String? userId;
  final Map<String, dynamic>? properties;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'event_name': eventName,
    'user_id': userId,
    'properties': properties,
  };
}

/// User event tracking and analytics service
/// Monitors key user interactions for app usage insights
class UserEventTracker {
  factory UserEventTracker() => _instance;

  UserEventTracker._internal();
  static final UserEventTracker _instance = UserEventTracker._internal();

  final List<UserEvent> _eventHistory = [];
  bool _initialized = false;
  String? _currentUserId;
  DateTime? _sessionStart;

  static const int maxEventHistorySize = 500;

  /// Initialize event tracker
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _sessionStart = DateTime.now();
    debugPrint('UserEventTracker initialized');
  }

  /// Set current user ID
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      trackEvent('user_identified', properties: {'user_id': userId});
    }
  }

  /// Track a user event
  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    if (!_initialized) {
      return;
    }

    final event = UserEvent(
      timestamp: DateTime.now(),
      eventName: eventName,
      userId: _currentUserId,
      properties: properties,
    );

    _eventHistory.add(event);
    if (_eventHistory.length > maxEventHistorySize) {
      _eventHistory.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('📊 EVENT: $eventName ${properties ?? ''}');
    }
  }

  /// Track screen view
  void trackScreenView(String screenName) {
    trackEvent('screen_view', properties: {'screen_name': screenName});
  }

  /// Track button tap
  void trackButtonTap(String buttonName) {
    trackEvent('button_tap', properties: {'button_name': buttonName});
  }

  /// Track form submission
  void trackFormSubmission(String formName, {bool success = true}) {
    trackEvent(
      'form_submission',
      properties: {'form_name': formName, 'success': success},
    );
  }

  /// Track error occurrence
  void trackError(String errorName, {Map<String, dynamic>? details}) {
    trackEvent(
      'error_occurred',
      properties: {'error_name': errorName, ...?details},
    );
  }

  /// Track data sync event
  void trackSyncEvent(String syncType, {bool success = true, int? itemCount}) {
    trackEvent(
      'data_sync',
      properties: {
        'sync_type': syncType,
        'success': success,
        'item_count': itemCount,
      },
    );
  }

  /// Get event history
  List<UserEvent> get eventHistory => List.unmodifiable(_eventHistory);

  /// Get session duration
  Duration get sessionDuration => _sessionStart != null
      ? DateTime.now().difference(_sessionStart!)
      : Duration.zero;

  /// Get event count by name
  Map<String, int> getEventCounts() {
    final counts = <String, int>{};
    for (final event in _eventHistory) {
      counts[event.eventName] = (counts[event.eventName] ?? 0) + 1;
    }
    return counts;
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() => {
    'total_events': _eventHistory.length,
    'session_duration_seconds': sessionDuration.inSeconds,
    'user_id': _currentUserId,
    'event_counts': getEventCounts(),
    'session_start': _sessionStart?.toIso8601String(),
    'session_end': DateTime.now().toIso8601String(),
  };

  /// Export events as JSON
  List<Map<String, dynamic>> exportEventsAsJson() =>
      _eventHistory.map((event) => event.toJson()).toList();

  /// Clear event history
  void clearHistory() {
    _eventHistory.clear();
  }

  /// Get events by name
  List<UserEvent> getEventsByName(String eventName) =>
      _eventHistory.where((e) => e.eventName == eventName).toList();

  /// Get recent events
  List<UserEvent> getRecentEvents({int limit = 20}) =>
      _eventHistory.length > limit
      ? _eventHistory.sublist(_eventHistory.length - limit)
      : _eventHistory;

  /// End session and get summary
  Map<String, dynamic> endSession() {
    final summary = getAnalyticsSummary();
    trackEvent('session_end', properties: summary);
    return summary;
  }
}

/// Global event tracker instance
final userEventTracker = UserEventTracker();
