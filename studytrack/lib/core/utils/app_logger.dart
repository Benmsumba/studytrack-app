import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
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
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'StudyTrack',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'StudyTrack',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
