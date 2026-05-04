import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/services/supabase_service.dart';
import '../../models/exam_model.dart';
import '../../models/study_session_model.dart';
import '../../models/topic_model.dart';

class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final SupabaseService _supabaseService = SupabaseService();

  static const String _dailyBriefingChannel = 'daily_briefing';
  static const String _studyRemindersChannel = 'study_reminders';
  static const String _examCountdownChannel = 'exam_countdown';
  static const String _weeklyReportChannel = 'weekly_report';
  static const String _spacedRepetitionChannel = 'spaced_repetition';

  Future<void> initialize() async {
    tzdata.initializeTimeZones();

    const androidInitSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await _createAndroidChannels(androidPlugin);
  }

  Future<void> bootstrapForCurrentUser() async {
    final user = _supabaseService.getCurrentUser();
    if (user == null) {
      return;
    }

    try {
      await cancelAll();

      final profile = await _supabaseService.getProfile(user.id);
      final sessions = await _supabaseService.getStudySessions(
        user.id,
        DateTime.now(),
      );
      final topics = await _supabaseService.getTopicsNeedingReview(user.id);
      final exams = await _supabaseService.getUpcomingExams(user.id);

      final studentName =
          (profile?['name'] as String?)?.trim().isNotEmpty == true
          ? profile!['name'] as String
          : 'Student';

      await scheduleDailyBriefing(
        hour: '07',
        minute: '00',
        studentName: studentName,
      );
      await scheduleWeeklyReport();
      await scheduleStreakReminder();

      for (final row in sessions ?? const <Map<String, dynamic>>[]) {
        final session = StudySessionModel.fromJson(row);
        if (session.status != 'completed') {
          await scheduleStudySession(session: session);
        }
        if (session.isOverdue) {
          await scheduleMissedSessionFollowUp(session: session);
        }
      }

      for (final topic in topics ?? const <TopicModel>[]) {
        await scheduleSpacedRepetitionReminder(topic: topic);
      }

      for (final row in exams ?? const <Map<String, dynamic>>[]) {
        final exam = ExamModel.fromJson(row);
        await scheduleExamCountdown(exam: exam);
      }
    } on Object catch (error) {
      debugPrint('Notification bootstrap failed: $error');
    }
  }

  Future<void> scheduleDailyBriefing({
    required String hour,
    required String minute,
    required String studentName,
  }) async {
    try {
      final timeOfDay = _parseTime(hour, minute);
      final now = DateTime.now();
      late DateTime scheduledDate;

      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      if (scheduledTime.isAfter(now)) {
        scheduledDate = scheduledTime;
      } else {
        scheduledDate = scheduledTime.add(const Duration(days: 1));
      }

      final greeting = _getGreeting();

      await _plugin.zonedSchedule(
        id: 0,
        title: 'Good $greeting, $studentName! 📚',
        body:
            'Your study schedule is ready. Tap to see your classes and sessions.',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyBriefingChannel,
            'Daily Briefing',
            channelDescription: 'Morning study briefing notifications',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Object catch (e) {
      debugPrint('Error scheduling daily briefing: $e');
    }
  }

  Future<void> scheduleWeeklyReport() async {
    try {
      final sundayEightPM = _getNextSunday8PM();

      await _plugin.zonedSchedule(
        id: 1,
        title: '📊 Your weekly wrapped is ready!',
        body: 'See how your week went. Your progress is impressive!',
        scheduledDate: tz.TZDateTime.from(sundayEightPM, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _weeklyReportChannel,
            'Weekly Report',
            channelDescription: 'Sunday weekly wrapped reports',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } on Object catch (e) {
      debugPrint('Error scheduling weekly report: $e');
    }
  }

  Future<void> scheduleStudySession({
    required StudySessionModel session,
  }) async {
    try {
      if (session.startTime == null || session.startTime!.trim().isEmpty) {
        return;
      }

      final time = _parseClock(session.startTime!);
      final sessionStart = DateTime(
        session.scheduledDate.year,
        session.scheduledDate.month,
        session.scheduledDate.day,
        time.hour,
        time.minute,
      );
      final notificationTime = sessionStart.subtract(
        const Duration(minutes: 15),
      );
      if (notificationTime.isBefore(DateTime.now())) {
        return;
      }

      await _plugin.zonedSchedule(
        id: _notificationId('study_${session.id}'),
        title: '⏰ Study Session Starting Soon!',
        body: 'Get ready for: ${session.title}',
        scheduledDate: tz.TZDateTime.from(notificationTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _studyRemindersChannel,
            'Study Reminders',
            channelDescription: 'Study session reminders',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } on Object catch (e) {
      debugPrint('Error scheduling study session: $e');
    }
  }

  Future<void> scheduleSpacedRepetitionReminder({
    required TopicModel topic,
  }) async {
    try {
      if (topic.nextReviewAt == null) return;

      final reviewDate = topic.nextReviewAt is String
          ? DateTime.parse(topic.nextReviewAt! as String)
          : topic.nextReviewAt;

      await _plugin.zonedSchedule(
        id: _notificationId('review_${topic.id}'),
        title: '🧠 Time to Review: ${topic.name}',
        body: 'You rated it ${topic.currentRating}/10 — let\'s keep it fresh!',
        scheduledDate: tz.TZDateTime.from(reviewDate!, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _spacedRepetitionChannel,
            'Spaced Repetition',
            channelDescription: 'Topic review reminders',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } on Object catch (e) {
      debugPrint('Error scheduling spaced repetition reminder: $e');
    }
  }

  Future<void> scheduleExamCountdown({required ExamModel exam}) async {
    try {
      final examDate = exam.examDate is String
          ? DateTime.parse(exam.examDate as String)
          : exam.examDate;
      final now = DateTime.now();

      await _scheduleExamNotification(
        examDate.subtract(const Duration(days: 7)),
        '📅 Exam in 7 days!',
        '${exam.title} — start your prep now',
        _notificationId('exam7_${exam.id}'),
      );

      if (examDate.subtract(const Duration(days: 3)).isAfter(now)) {
        await _scheduleExamNotification(
          examDate.subtract(const Duration(days: 3)),
          '📅 Exam in 3 days!',
          '${exam.title} — final push!',
          _notificationId('exam3_${exam.id}'),
        );
      }

      if (examDate.subtract(const Duration(days: 1)).isAfter(now)) {
        await _scheduleExamNotification(
          examDate.subtract(const Duration(days: 1)),
          '🚨 Exam tomorrow!',
          '${exam.title} — get some rest!',
          _notificationId('exam1_${exam.id}'),
        );
      }

      if (examDate.isAfter(now)) {
        final morning = DateTime(
          examDate.year,
          examDate.month,
          examDate.day,
          7,
        );
        await _scheduleExamNotification(
          morning,
          '🎯 Exam day!',
          '${exam.title} at ${exam.examTime} in ${exam.venue}',
          _notificationId('exam0_${exam.id}'),
        );
      }
    } on Object catch (e) {
      debugPrint('Error scheduling exam countdown: $e');
    }
  }

  Future<void> scheduleStreakReminder() async {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 20, 30);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _notificationId('streak_daily'),
      title: '🔥 Keep your streak alive',
      body: 'Even a 15-minute review today keeps your streak going.',
      scheduledDate: tz.TZDateTime.from(target, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _studyRemindersChannel,
          'Study Reminders',
          channelDescription: 'Study session reminders',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleMissedSessionFollowUp({
    required StudySessionModel session,
  }) async {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 18, 30);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _notificationId('missed_${session.id}'),
      title: '📌 Catch-up reminder',
      body: 'You missed ${session.title}. Reschedule it to stay on track.',
      scheduledDate: tz.TZDateTime.from(target, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _studyRemindersChannel,
          'Study Reminders',
          channelDescription: 'Study session reminders',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  Future<void> _scheduleExamNotification(
    DateTime dateTime,
    String title,
    String body,
    int id,
  ) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(dateTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _examCountdownChannel,
            'Exam Countdown',
            channelDescription: 'Exam warning notifications',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } on Object catch (e) {
      debugPrint('Error scheduling exam notification: $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  void _onSelectNotification(NotificationResponse? response) {
    if (response != null && response.payload != null) {
      debugPrint('Notification tapped: ${response.payload}');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  DateTime _getNextSunday8PM() {
    final now = DateTime.now();
    var sundayEightPM = DateTime(now.year, now.month, now.day, 20);

    while (sundayEightPM.weekday != 7) {
      sundayEightPM = sundayEightPM.add(const Duration(days: 1));
    }

    if (sundayEightPM.isBefore(now)) {
      sundayEightPM = sundayEightPM.add(const Duration(days: 7));
    }

    return sundayEightPM;
  }

  _TimeOfDay _parseTime(String hour, String minute) =>
      _TimeOfDay(int.parse(hour), int.parse(minute));

  _TimeOfDay _parseClock(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      return _TimeOfDay(8, 0);
    }

    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    return _TimeOfDay(hour.clamp(0, 23), minute.clamp(0, 59));
  }

  int _notificationId(String seed) => seed.hashCode & 0x7fffffff;

  Future<void> _createAndroidChannels(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) {
      return;
    }

    const channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        _dailyBriefingChannel,
        'Daily Briefing',
        description: 'Morning study briefing notifications',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        _studyRemindersChannel,
        'Study Reminders',
        description: 'Study sessions, streak nudges and catch-up reminders',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _examCountdownChannel,
        'Exam Countdown',
        description: 'Exam alerts and countdown milestones',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _weeklyReportChannel,
        'Weekly Report',
        description: 'Sunday weekly wrapped report notifications',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        _spacedRepetitionChannel,
        'Spaced Repetition',
        description: 'Topic review reminders based on self ratings',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }
}

class _TimeOfDay {
  _TimeOfDay(this.hour, this.minute);
  final int hour;
  final int minute;
}
