import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyDailyBriefing = 'settings_daily_briefing';
  static const _keyStudyReminders = 'settings_study_reminders';
  static const _keyExamAlerts = 'settings_exam_alerts';
  static const _keyWeeklyReport = 'settings_weekly_report';
  static const _keyDarkMode = 'settings_dark_mode';

  bool dailyBriefing = true;
  bool studyReminders = true;
  bool examAlerts = true;
  bool weeklyReport = true;
  bool darkMode = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    dailyBriefing = prefs.getBool(_keyDailyBriefing) ?? true;
    studyReminders = prefs.getBool(_keyStudyReminders) ?? true;
    examAlerts = prefs.getBool(_keyExamAlerts) ?? true;
    weeklyReport = prefs.getBool(_keyWeeklyReport) ?? true;
    darkMode = prefs.getBool(_keyDarkMode) ?? true;
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
    darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }
}
