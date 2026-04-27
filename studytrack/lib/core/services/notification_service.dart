import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import '../../models/exam_model.dart';
import '../../models/study_session_model.dart';
import '../../models/topic_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
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
            'daily_briefing',
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
    } catch (e) {
      print('Error scheduling daily briefing: $e');
    }
  }

  Future<void> scheduleWeeklyReport() async {
    try {
      var sundayEightPM = _getNextSunday8PM();

      await _plugin.zonedSchedule(
        id: 1,
        title: '📊 Your weekly wrapped is ready!',
        body: 'See how your week went. Your progress is impressive!',
        scheduledDate: tz.TZDateTime.from(sundayEightPM, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_report',
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
    } catch (e) {
      print('Error scheduling weekly report: $e');
    }
  }

  Future<void> scheduleStudySession({
    required StudySessionModel session,
  }) async {
    try {
      final sessionStart = DateTime.parse(
          '${session.scheduledDate} ${session.startTime}');
      final notificationTime = sessionStart.subtract(
        const Duration(minutes: 15),
      );

      await _plugin.zonedSchedule(
        id: session.id.hashCode,
        title: '⏰ Study Session Starting Soon!',
        body: 'Get ready for: ${session.title}',
        scheduledDate: tz.TZDateTime.from(notificationTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminders',
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
    } catch (e) {
      print('Error scheduling study session: $e');
    }
  }

  Future<void> scheduleSpacedRepetitionReminder({
    required TopicModel topic,
  }) async {
    try {
      if (topic.nextReviewAt == null) return;

      final reviewDate = topic.nextReviewAt is String
          ? DateTime.parse(topic.nextReviewAt as String)
          : topic.nextReviewAt;

      await _plugin.zonedSchedule(
        id: topic.id.hashCode,
        title: '🧠 Time to Review: ${topic.name}',
        body:
            'You rated it ${topic.currentRating}/10 — let\'s keep it fresh!',
        scheduledDate: tz.TZDateTime.from(reviewDate as DateTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'spaced_repetition',
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
    } catch (e) {
      print('Error scheduling spaced repetition reminder: $e');
    }
  }

  Future<void> scheduleExamCountdown({
    required ExamModel exam,
  }) async {
    try {
      final examDate = exam.examDate is String
          ? DateTime.parse(exam.examDate as String)
          : exam.examDate;
      final now = DateTime.now();

      await _scheduleExamNotification(
        examDate.subtract(const Duration(days: 7)),
        '📅 Exam in 7 days!',
        '${exam.title} — start your prep now',
        2,
      );

      if (examDate.subtract(const Duration(days: 3)).isAfter(now)) {
        await _scheduleExamNotification(
          examDate.subtract(const Duration(days: 3)),
          '📅 Exam in 3 days!',
          '${exam.title} — final push!',
          3,
        );
      }

      if (examDate.subtract(const Duration(days: 1)).isAfter(now)) {
        await _scheduleExamNotification(
          examDate.subtract(const Duration(days: 1)),
          '🚨 Exam tomorrow!',
          '${exam.title} — get some rest!',
          4,
        );
      }

      if (examDate.isAfter(now)) {
        final morning = DateTime(examDate.year, examDate.month, examDate.day, 7);
        await _scheduleExamNotification(
          morning,
          '🎯 Exam day!',
          '${exam.title} at ${exam.examTime} in ${exam.venue}',
          5,
        );
      }
    } catch (e) {
      print('Error scheduling exam countdown: $e');
    }
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
            'exam_countdown',
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
    } catch (e) {
      print('Error scheduling exam notification: $e');
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
      print('Notification tapped: ${response.payload}');
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

  _TimeOfDay _parseTime(String hour, String minute) {
    return _TimeOfDay(int.parse(hour), int.parse(minute));
  }
}

class _TimeOfDay {
  final int hour;
  final int minute;

  _TimeOfDay(this.hour, this.minute);
}
