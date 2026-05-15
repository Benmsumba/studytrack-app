import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/module_model.dart';
import '../../../models/study_session_model.dart';
import '../../../models/topic_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  List<ModuleModel> _modules = [];
  List<TopicModel> _topics = [];

  int _currentStreak = 0;
  int _weeklySessions = 0;

  final Map<int, int> _weeklyTopicCounts = {};
  final Map<String, int> _heatmapCounts = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  /// Loads all analytics data in 2 network round-trips instead of 91+.
  ///
  /// Round-trip 1 (parallel): modules + sessions (84-day window) + profile.
  /// Round-trip 2: batch topics for all module IDs.
  /// Everything else is computed client-side from those three lists.
  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final heatmapStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 83));

    // Round-trip 1 — fire modules, sessions, and profile in parallel.
    late final moduleResult = getIt<ModuleRepository>().getAllModules();
    late final sessionResult = getIt<StudySessionRepository>()
        .getSessionsByDateRange(startDate: heatmapStart, endDate: now);
    late final profileResult = getIt<ProfileRepository>().getCurrentProfile();

    final (modules, allSessions, profile) = await (
      moduleResult,
      sessionResult,
      profileResult,
    ).wait;

    final resolvedModules = modules.fold((_) => <ModuleModel>[], (m) => m);
    final resolvedSessions = allSessions.fold(
      (_) => const <StudySessionModel>[],
      (s) => s,
    );
    final resolvedProfile = profile.fold((_) => null, (p) => p);

    // Round-trip 2 — batch topics (needs module IDs from round-trip 1).
    final moduleIds = resolvedModules.map((m) => m.id).toList();
    final topicResult = await getIt<TopicRepository>().getTopicsByModuleIds(
      moduleIds,
    );
    final allTopics = topicResult.fold((_) => <TopicModel>[], (t) => t);

    final currentStreak =
        (resolvedProfile?['streak_count'] as num?)?.toInt() ?? 0;

    final weekStart = _startOfWeek(DateTime(now.year, now.month, now.day));
    final weeklyTopicIds = <int, Set<String>>{};
    var weeklySessions = 0;
    final heatmapCounts = <String, int>{};

    for (final session in resolvedSessions) {
      final dateOnly = DateTime(
        session.scheduledDate.year,
        session.scheduledDate.month,
        session.scheduledDate.day,
      );

      // Heatmap — count all sessions in the 84-day window.
      final key = _dateKey(dateOnly);
      heatmapCounts[key] = (heatmapCounts[key] ?? 0) + 1;

      // Weekly — count unique topics per day within the current week.
      final dayDiff = dateOnly.difference(weekStart).inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        weeklySessions++;
        final topicId = session.topicId;
        if (topicId != null && topicId.isNotEmpty) {
          (weeklyTopicIds[dayDiff] ??= {}).add(topicId);
        }
      }
    }

    final weeklyTopicCounts = {
      for (var i = 0; i < 7; i++) i: weeklyTopicIds[i]?.length ?? 0,
    };

    if (!mounted) return;
    setState(() {
      _modules = resolvedModules;
      _topics = allTopics;
      _currentStreak = currentStreak;
      _weeklySessions = weeklySessions;
      _weeklyTopicCounts
        ..clear()
        ..addAll(weeklyTopicCounts);
      _heatmapCounts
        ..clear()
        ..addAll(heatmapCounts);
      _isLoading = false;
    });
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _dateStr(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  Widget _buildHeatmap() {
    final now = DateTime.now();
    const weeks = 12;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xCC1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Activity Heatmap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'High activity (5+ hrs)',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(weeks, (w) {
                  return Expanded(
                    child: Column(
                      children: List.generate(7, (d) {
                        final date = now.subtract(
                          Duration(days: (weeks - 1 - w) * 7 + (6 - d)),
                        );
                        final key =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final count = _heatmapCounts[key] ?? 0;
                        final intensity = (count / 5.0).clamp(0.0, 1.0);
                        return Container(
                          margin: const EdgeInsets.all(1),
                          width: double.infinity,
                          height: 10,
                          decoration: BoxDecoration(
                            color: count == 0
                                ? Colors.white.withValues(alpha: 0.05)
                                : Color.lerp(
                                    const Color(0xFF312E81),
                                    const Color(0xFFA78BFA),
                                    intensity,
                                  )!,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    final streakStart = DateTime.now().subtract(
      Duration(days: _currentStreak > 0 ? _currentStreak - 1 : 0),
    );
    final motivational = _currentStreak >= 30
        ? "You're unstoppable! Keep the momentum."
        : _currentStreak >= 7
        ? "Great consistency! Keep going."
        : "Every day counts. Build your streak!";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_currentStreak Day Streak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('🔥 ', style: TextStyle(fontSize: 14)),
              Text(
                '${_dateStr(streakStart)} - ${_dateStr(DateTime.now())}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            motivational,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHoursCard() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // _weeklyTopicCounts uses 0-indexed keys (0=Mon..6=Sun)
    final values = List.generate(
      7,
      (i) => (_weeklyTopicCounts[i] ?? 0).toDouble(),
    );
    final maxVal =
        values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    final totalHours = values.fold(0.0, (a, b) => a + b);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xCC1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Study Hours per Week',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'This Week: ${totalHours.toStringAsFixed(0)} Sessions',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final val = values[i];
                    final barH = maxVal > 0 ? (val / maxVal) * 80 : 0.0;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (val > 0)
                            Text(
                              '${val.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: barH.clamp(4.0, 80.0),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days[i],
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCompletionRow() {
    final displayModules = _modules.take(3).toList();
    if (displayModules.isEmpty) return const SizedBox.shrink();

    return Row(
      children: displayModules.asMap().entries.map((entry) {
        final module = entry.value;
        final moduleTopics =
            _topics.where((t) => t.moduleId == module.id).toList();
        final mastered =
            moduleTopics.where((t) => (t.currentRating ?? 0) >= 7).length;
        final total = moduleTopics.length;
        final progress = total > 0 ? mastered / total : 0.0;
        final percent = (progress * 100).round();

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: entry.key > 0 ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xCC1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white38,
                    size: 16,
                  ),
                ),
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: _ModuleRingPainter(
                          progress: progress,
                          color: const Color(0xFF6366F1),
                        ),
                        size: const Size(70, 70),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  module.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 4),
                Text(
                  '$mastered/$total topics mastered',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : RefreshIndicator(
              color: const Color(0xFF4F46E5),
              onRefresh: _loadProgress,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'StudyTrack',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Progress & Insights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildHeatmap(),
                      const SizedBox(height: 16),
                      _buildStreakCard(),
                      const SizedBox(height: 16),
                      _buildWeeklyHoursCard(),
                      const SizedBox(height: 16),
                      _buildModuleCompletionRow(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ModuleRingPainter extends CustomPainter {
  const _ModuleRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const pi = 3.14159265359;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    if (progress <= 0) return;
    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ModuleRingPainter old) =>
      old.progress != progress || old.color != color;
}
