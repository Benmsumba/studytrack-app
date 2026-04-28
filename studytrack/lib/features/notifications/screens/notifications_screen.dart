import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  List<_NotificationTileData> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = _service.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await _service.getProfile(user.id);
      final modules =
          await _service.getClassTimetable(user.id) ?? <Map<String, dynamic>>[];
      final todaySessions =
          await _service.getStudySessions(user.id, DateTime.now()) ??
          <Map<String, dynamic>>[];
      final upcomingExams =
          await _service.getUpcomingExams(user.id) ?? <Map<String, dynamic>>[];

      final todayClassCount = modules.where((row) {
        final day = (row['day_of_week'] as num?)?.toInt();
        return day == DateTime.now().weekday;
      }).length;

      final weeklySessions = await _weeklySessionCount(user.id);
      final streak = (profile?['streak_count'] as num?)?.toInt() ?? 0;
      final activeSession = _firstMap(todaySessions);
      final exam = _firstMap(upcomingExams);
      final examDate = _parseDate(
        exam?['exam_date'] ?? exam?['date'] ?? exam?['scheduled_date'],
      );
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
                '${_firstText(exam, ['title', 'name']) ?? 'Your exam'} is in ${daysRemaining ?? 0} days. Keep momentum high.',
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
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
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
    var count = 0;

    for (var offset = 0; offset < 7; offset++) {
      final sessions =
          await _service.getStudySessions(
            userId,
            weekStart.add(Duration(days: offset)),
          ) ??
          <Map<String, dynamic>>[];
      count += sessions.length;
    }

    return count;
  }

  Map<String, dynamic>? _firstMap(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return null;
    return items.first;
  }

  String? _firstText(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return null;
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String _sessionNotificationBody(Map<String, dynamic> session) {
    final topic =
        _firstText(session, ['topic_name', 'title', 'name']) ??
        'A study session';
    final time = _sessionTimeLabel(session);
    return '$topic starts at $time.';
  }

  String _sessionTimeLabel(Map<String, dynamic> session) {
    final raw = _firstText(session, ['start_time', 'time']);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: AppTextStyles.headingLarge.copyWith(fontSize: 28),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _loadNotifications,
                    child: Text(
                      'Refresh',
                      style: GoogleFonts.inter(
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
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 120),
                            child: Center(
                              child: Text(
                                'No new notifications',
                                style: AppTextStyles.bodyMediumSecondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF06B6D4),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.bodySmallSecondary),
                const SizedBox(height: 6),
                Text(timeLabel, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
