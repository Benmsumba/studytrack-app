import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../constants/app_constants.dart';

/// Lightweight analytics wrapper.
///
/// Backed by Sentry breadcrumbs so every event is automatically attached to
/// crash reports — giving instant context on "what did the user do right
/// before the crash?" without a separate analytics SDK.
///
/// All calls are fire-and-forget and never throw; they are no-ops in debug
/// mode unless [debugForceEnabled] is set.
///
/// Usage:
/// ```dart
/// Analytics.track('viewed_timetable');
/// Analytics.track('joined_group', data: {'group_id': group.id});
/// Analytics.setUser(userId: userId, email: email);
/// Analytics.clearUser();
/// ```
abstract final class Analytics {
  /// Override in tests to verify events.
  @visibleForTesting
  static bool debugForceEnabled = false;

  static bool get _enabled =>
      debugForceEnabled ||
      (!kDebugMode && AppConstants.isSentryConfigured);

  // ── Core API ──────────────────────────────────────────────────────────────

  /// Record a named event with optional metadata.
  ///
  /// [name] should be snake_case, e.g. `'viewed_timetable'`.
  static void track(String name, {Map<String, dynamic>? data}) {
    if (!_enabled) return;
    _addBreadcrumb(
      type: 'user',
      category: 'action',
      message: name,
      data: data,
    );
  }

  /// Record a screen view.
  static void screen(String screenName) {
    if (!_enabled) return;
    _addBreadcrumb(
      type: 'navigation',
      category: 'screen',
      message: screenName,
    );
  }

  /// Record a non-fatal error with additional context.
  static void error(String description, {Object? exception, Map<String, dynamic>? data}) {
    if (!_enabled) return;
    _addBreadcrumb(
      type: 'error',
      category: 'non_fatal',
      message: description,
      data: data,
      level: SentryLevel.warning,
    );
  }

  /// Attach the authenticated user to future events and crash reports.
  static void setUser({required String userId, String? email, String? name}) {
    if (!_enabled) return;
    Sentry.configureScope(
      (scope) => scope.setUser(
        SentryUser(id: userId, email: email, name: name),
      ),
    );
  }

  /// Clear user identity on sign-out.
  static void clearUser() {
    if (!_enabled) return;
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  // ── Pre-defined event helpers (prevents typo-prone string literals) ───────

  /// Call when the user completes onboarding.
  static void onboardingCompleted() =>
      track('onboarding_completed');

  /// Call when the user views a screen by name.
  static void viewedScreen(String name) => screen(name);

  /// Call when a study session is started.
  static void sessionStarted({String? moduleId, String? topicId}) =>
      track('session_started', data: {
        if (moduleId != null) 'module_id': moduleId,
        if (topicId != null) 'topic_id': topicId,
      });

  /// Call when a session ends and is saved.
  static void sessionCompleted({required int durationMinutes, int? rating}) =>
      track('session_completed', data: {
        'duration_minutes': durationMinutes,
        if (rating != null) 'rating': rating,
      });

  /// Call when the user joins or creates a study group.
  static void joinedGroup({required String groupId}) =>
      track('joined_group', data: {'group_id': groupId});

  /// Call when the user sends a chat message.
  static void sentMessage({required String groupId}) =>
      track('sent_message', data: {'group_id': groupId});

  /// Call when the user earns a badge.
  static void badgeEarned({required String badgeType}) =>
      track('badge_earned', data: {'badge_type': badgeType});

  /// Call when an exam is added.
  static void examAdded() => track('exam_added');

  /// Call when the AI tutor is opened.
  static void aiTutorOpened({String? topicId}) =>
      track('ai_tutor_opened', data: {
        if (topicId != null) 'topic_id': topicId,
      });

  /// Call when a voice note is recorded.
  static void voiceNoteRecorded() => track('voice_note_recorded');

  /// Call when data is exported.
  static void dataExported() => track('data_exported');

  // ── Internal ──────────────────────────────────────────────────────────────

  static void _addBreadcrumb({
    required String type,
    required String category,
    required String message,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    try {
      Sentry.addBreadcrumb(
        Breadcrumb(
          type: type,
          category: category,
          message: message,
          data: data,
          level: level,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    } on Object {
      // Analytics must never crash the app.
    }
  }
}
