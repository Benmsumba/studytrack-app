import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/class_timetable_repository.dart';
import '../../../core/repositories/exam_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../models/class_slot_model.dart';
import '../../../models/exam_model.dart';
import '../../../models/study_session_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final ProfileRepository _profileRepository;
  late final ClassTimetableRepository _classTimetableRepository;
  late final StudySessionRepository _studySessionRepository;
  late final ExamRepository _examRepository;

  bool _isLoading = true;
  String? _loadError;
  List<_NotificationTileData> _items = const [];

  @override
  void initState() {
    super.initState();
    _profileRepository = getIt<ProfileRepository>();
    _classTimetableRepository = getIt<ClassTimetableRepository>();
    _studySessionRepository = getIt<StudySessionRepository>();
    _examRepository = getIt<ExamRepository>();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final profileResult = await _profileRepository.getCurrentProfile();
    Map<String, dynamic>? profile;
    profileResult.fold((error) {}, (value) => profile = value);
    if (profile == null) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loadError = 'We could not load notifications right now.';
        _isLoading = false;
      });
      return;
    }

    final userId = profile!['id']?.toString() ?? '';
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loadError = 'We could not load notifications right now.';
        _isLoading = false;
      });
      return;
    }

    try {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      final timetableResult = await _classTimetableRepository
          .getClassSlotsByDay(userId: userId, dayOfWeek: today.weekday);
      final todaySessionsResult = await _studySessionRepository
          .getSessionsByDateRange(startDate: startOfToday, endDate: endOfToday);
      final upcomingExamsResult = await _examRepository.getUpcomingExams();

      var modules = const <ClassSlotModel>[];
      var todaySessions = const <StudySessionModel>[];
      var upcomingExams = const <ExamModel>[];

      timetableResult.fold((error) {}, (value) => modules = value);
      todaySessionsResult.fold((error) {}, (value) => todaySessions = value);
      upcomingExamsResult.fold((error) {}, (value) => upcomingExams = value);

      final todayClassCount = modules.length;
      final weeklySessions = await _weeklySessionCount(userId);
      final streak = (profile!['streak_count'] as num?)?.toInt() ?? 0;
      final activeSession = todaySessions.isEmpty ? null : todaySessions.first;
      final exam = upcomingExams.isEmpty ? null : upcomingExams.first;
      final examDate = exam?.examDate;
      final daysRemaining = examDate == null
          ? null
          : math.max(examDate.difference(DateTime.now()).inDays, 0);

      final items = <_NotificationTileData>[
        _NotificationTileData(
          title: 'Daily Briefing Ready',
          body:
              'You have $todayClassCount classes and ${todaySessions.length} study sessions today.',
          timeLabel: 'Today',
          icon: Icons.wb_sunny_outlined,
          iconColor: AppColors.accent,
          unread: true,
        ),
        if (activeSession != null)
          _NotificationTileData(
            title: 'Study Session Coming Up',
            body: _sessionNotificationBody(activeSession),
            timeLabel: _sessionTimeLabel(activeSession),
            icon: Icons.timer_outlined,
            iconColor: AppColors.primary,
            unread: true,
          ),
        if (exam != null)
          _NotificationTileData(
            title: 'Exam Countdown Alert',
            body:
                '${exam.title} is in ${daysRemaining ?? 0} days. Keep momentum high.',
            timeLabel: 'Latest',
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
          ),
        _NotificationTileData(
          title: 'Weekly Wrapped Available',
          body:
              'You logged $weeklySessions sessions this week and kept a $streak-day streak.',
          timeLabel: 'This week',
          icon: Icons.insights_outlined,
          iconColor: AppColors.success,
        ),
      ];

      if (!mounted) return;
      setState(() {
        _items = items;
        _loadError = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loadError = 'We could not load notifications right now.';
        _isLoading = false;
      });
    }
  }

  Future<int> _weeklySessionCount(String userId) async {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final result = await _studySessionRepository.getSessionsByDateRange(
      startDate: weekStart,
      endDate: weekEnd,
    );
    return result.fold((error) => 0, (sessions) => sessions.length);
  }

  String _sessionNotificationBody(StudySessionModel session) {
    final topic = session.title;
    final time = _sessionTimeLabel(session);
    return '$topic starts at $time.';
  }

  String _sessionTimeLabel(StudySessionModel session) {
    final raw = session.startTime;
    if (raw == null) return 'Today';
    return _formatTimeLabel(raw);
  }

  String _formatTimeLabel(String raw) {
    final normalized = raw.trim();
    final dateTime = DateTime.tryParse(normalized);
    if (dateTime != null) {
      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
    }

    final parts = normalized.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
    }

    return normalized;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: AppTextStyles.headingLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _loadNotifications,
                  child: Text(
                    'Refresh',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _loadNotifications,
              child: _isLoading
                  ? AppStateView.loadingList(itemCount: 4, itemHeight: 88)
                  : _loadError != null
                  ? AppStateView.error(
                      title: 'Notifications unavailable',
                      message: _loadError!,
                      onRetry: _loadNotifications,
                    )
                  : _items.isEmpty
                  ? AppStateView.empty(
                      icon: Icons.notifications_none_rounded,
                      title: 'No new notifications',
                      message:
                          'You’re all caught up. New reminders will appear here.',
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                      children: _items
                          .map(
                            (item) => _NotificationTile(
                              title: item.title,
                              body: item.body,
                              timeLabel: item.timeLabel,
                              icon: item.icon,
                              iconColor: item.iconColor,
                              unread: item.unread,
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _NotificationTileData {
  const _NotificationTileData({
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    required this.iconColor,
    this.unread = false,
  });

  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final bool unread;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    required this.iconColor,
    this.unread = false,
  });

  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final bool unread;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      border: Border.all(
        color: unread ? AppColors.primary : AppColors.border,
        width: unread ? 1.2 : 1,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (unread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.neonCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(body, style: AppTextStyles.bodySmallSecondary),
              const SizedBox(height: AppSpacing.xs),
              Text(timeLabel, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    ),
  );
}
