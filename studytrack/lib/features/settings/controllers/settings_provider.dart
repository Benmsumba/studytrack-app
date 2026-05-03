import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class SettingsProvider extends ChangeNotifier {
  static const _keyDailyBriefing = 'settings_daily_briefing';
  static const _keyStudyReminders = 'settings_study_reminders';
  static const _keyExamAlerts = 'settings_exam_alerts';
  static const _keyWeeklyReport = 'settings_weekly_report';
  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyDarkMode = 'settings_dark_mode';

  bool dailyBriefing = true;
  bool studyReminders = true;
  bool examAlerts = true;
  bool weeklyReport = true;
  AppThemeMode themeMode = AppThemeMode.system;

  ThemeMode get materialThemeMode => switch (themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  bool get darkMode => themeMode == AppThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    dailyBriefing = prefs.getBool(_keyDailyBriefing) ?? true;
    studyReminders = prefs.getBool(_keyStudyReminders) ?? true;
    examAlerts = prefs.getBool(_keyExamAlerts) ?? true;
    weeklyReport = prefs.getBool(_keyWeeklyReport) ?? true;
    final savedThemeMode = prefs.getString(_keyThemeMode);
    if (savedThemeMode != null && savedThemeMode.isNotEmpty) {
      themeMode = AppThemeMode.values.firstWhere(
        (value) => value.name == savedThemeMode,
        orElse: () => AppThemeMode.system,
      );
    } else {
      final legacyDarkMode = prefs.getBool(_keyDarkMode);
      if (legacyDarkMode != null) {
        themeMode = legacyDarkMode ? AppThemeMode.dark : AppThemeMode.light;
      } else {
        themeMode = AppThemeMode.system;
      }
    }
    notifyListeners();
  }

  Future<void> setDailyBriefing(bool value) async {
    dailyBriefing = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyBriefing, value);
  }

  Future<void> setStudyReminders(bool value) async {
    studyReminders = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStudyReminders, value);
  }

  Future<void> setExamAlerts(bool value) async {
    examAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExamAlerts, value);
  }

  Future<void> setWeeklyReport(bool value) async {
    weeklyReport = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyReport, value);
  }

  Future<void> setDarkMode(bool value) async {
    await setThemeMode(value ? AppThemeMode.dark : AppThemeMode.light);
  }

  Future<void> setThemeMode(AppThemeMode value) async {
    themeMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, value.name);
    await prefs.remove(_keyDarkMode);
  }
}
