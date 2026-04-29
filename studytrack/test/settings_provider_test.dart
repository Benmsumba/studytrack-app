import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studytrack/features/settings/controllers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads default settings when preferences are empty', () async {
    final provider = SettingsProvider();

    await provider.load();

    expect(provider.dailyBriefing, isTrue);
    expect(provider.studyReminders, isTrue);
    expect(provider.examAlerts, isTrue);
    expect(provider.weeklyReport, isTrue);
    expect(provider.darkMode, isTrue);
  });

  test('persists toggled settings across instances', () async {
    final provider = SettingsProvider();

    await provider.setDailyBriefing(false);
    await provider.setStudyReminders(false);
    await provider.setExamAlerts(false);
    await provider.setWeeklyReport(false);
    await provider.setDarkMode(false);

    final reloaded = SettingsProvider();
    await reloaded.load();

    expect(reloaded.dailyBriefing, isFalse);
    expect(reloaded.studyReminders, isFalse);
    expect(reloaded.examAlerts, isFalse);
    expect(reloaded.weeklyReport, isFalse);
    expect(reloaded.darkMode, isFalse);
  });
}
