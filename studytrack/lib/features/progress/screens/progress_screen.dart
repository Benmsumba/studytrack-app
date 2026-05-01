import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/service_locator.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/utils/result.dart';
import '../../../models/topic_rating_history_model.dart';
import '../../../models/study_session_model.dart';
import '../../auth/controllers/auth_provider.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ModuleRepository _moduleRepo = getIt<ModuleRepository>();
  final TopicRepository _topicRepo = getIt<TopicRepository>();
  final StudySessionRepository _sessionRepo = getIt<StudySessionRepository>();
  final ProfileRepository _profileRepo = getIt<ProfileRepository>();

  bool _isLoading = true;
  List<ModuleModel> _modules = [];
  List<TopicModel> _topics = [];
  TopicModel? _selectedTopic;

  int _topicsMastered = 0;
  int _currentStreak = 0;
  int _weeklySessions = 0;
  double _averageRating = 0;

  final Map<int, int> _weeklyTopicCounts = {};
  final Map<String, int> _heatmapCounts = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    final modulesResult = await _moduleRepo.getAllModules();
    final modules = modulesResult is Success<List<ModuleModel>>
        ? modulesResult.data
        : <ModuleModel>[];

    final allTopics = <TopicModel>[];
    for (final module in modules) {
      final topicsResult = await _topicRepo.getTopicsByModule(module.id);
      if (topicsResult is Success<List<TopicModel>>) {
        allTopics.addAll(topicsResult.data);
      }
    }

    final ratings = allTopics
        .where((topic) => topic.currentRating != null)
        .map((topic) => topic.currentRating!)
        .toList();

    final topicsMastered = allTopics
        .where((topic) => (topic.currentRating ?? 0) >= 7)
        .length;
    final averageRating = ratings.isEmpty
        ? 0.0
        : (ratings.reduce((a, b) => a + b) / ratings.length).toDouble();

    final profileResult = await _profileRepo.getProfileById(user.id);
    final currentStreak = profileResult is Success<Map<String, dynamic>?>
        ? (profileResult.data?['streak_count'] as num?)?.toInt() ?? 0
        : 0;

    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final heatmapStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 83));
    final heatmapEnd = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final sessionsResult = await _sessionRepo.getSessionsByDateRange(
      startDate: heatmapStart,
      endDate: heatmapEnd,
    );
    final sessions = sessionsResult is Success<List<StudySessionModel>>
        ? sessionsResult.data
        : <StudySessionModel>[];

    final sessionsByDay = <String, List<StudySessionModel>>{};
    for (final session in sessions) {
      final dayKey = _dateKey(session.scheduledDate);
      sessionsByDay
          .putIfAbsent(dayKey, () => <StudySessionModel>[])
          .add(session);
    }

    final weeklyTopicCounts = <int, int>{};
    var weeklySessions = 0;
    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = weekStart.add(Duration(days: dayIndex));
      final daySessions = sessionsByDay[_dateKey(date)] ?? const [];

      final topicIds = daySessions
          .map((s) => s.topicId)
          .where((id) => id != null && id.isNotEmpty)
          .map((id) => id!)
          .toSet();

      weeklyTopicCounts[dayIndex] = topicIds.length;
      weeklySessions += daySessions.length;
    }

    final heatmapCounts = <String, int>{};
    for (var offset = 0; offset < 84; offset++) {
      final date = heatmapStart.add(Duration(days: offset));
      heatmapCounts[_dateKey(date)] =
          sessionsByDay[_dateKey(date)]?.length ?? 0;
    }

    if (!mounted) return;
    setState(() {
      _modules = modules;
      _topics = allTopics;
      _selectedTopic = allTopics.isEmpty
          ? null
          : (_selectedTopic ?? allTopics.first);
      _topicsMastered = topicsMastered;
      _currentStreak = currentStreak;
      _weeklySessions = weeklySessions;
      _averageRating = averageRating;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadProgress,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildQuickStats(),
                const SizedBox(height: 16),
                _buildWeeklyBarChart(),
                const SizedBox(height: 16),
                _buildRadarChart(),
                const SizedBox(height: 16),
                _buildHeatmap(),
                const SizedBox(height: 16),
                _buildTopicRatingHistory(),
                const SizedBox(height: 16),
                _buildModuleDonuts(),
              ],
            ),
          ),
  );

  Widget _buildQuickStats() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.5,
    children: [
      _statCard('Topics Mastered', '$_topicsMastered', Icons.school_rounded),
      _statCard(
        'Current Streak',
        '$_currentStreak',
        Icons.local_fire_department,
      ),
      _statCard(
        "This Week's Sessions",
        '$_weeklySessions',
        Icons.menu_book_rounded,
      ),
      _statCard(
        'Average Rating',
        _averageRating.toStringAsFixed(1),
        Icons.star_rounded,
      ),
    ],
  );

  Widget _statCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _buildSectionShell(
    String title,
    Widget child, {
    double? fixedHeight,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (fixedHeight != null)
          SizedBox(height: fixedHeight, child: child)
        else
          child,
      ],
    ),
  );

  Widget _buildWeeklyBarChart() {
    final maxValue = _weeklyTopicCounts.values.fold<int>(
      0,
      (a, b) => a > b ? a : b,
    );

    return _buildSectionShell(
      'Weekly Performance (Topics Studied)',
      BarChart(
        BarChartData(
          maxY: (maxValue + 1).toDouble(),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(drawVerticalLine: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${rod.toY.toInt()} topics',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
          barGroups: List.generate(7, (index) {
            final value = (_weeklyTopicCounts[index] ?? 0).toDouble();
            final color =
                Color.lerp(AppColors.deepViolet, AppColors.cyan, index / 6) ??
                AppColors.deepViolet;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  color: color,
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[index],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      fixedHeight: 220,
    );
  }

  Widget _buildRadarChart() {
    if (_modules.isEmpty) {
      return _buildSectionShell(
        'Subject Radar Chart',
        Center(
          child: Text(
            'Add modules to view your radar chart.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        fixedHeight: 180,
      );
    }

    final radarModules = _modules.take(6).toList();
    final entries = radarModules.map((module) {
      final moduleTopics = _topics
          .where(
            (topic) =>
                topic.moduleId == module.id && topic.currentRating != null,
          )
          .toList();
      if (moduleTopics.isEmpty) {
        return const RadarEntry(value: 0);
      }
      final avg =
          moduleTopics
              .map((topic) => topic.currentRating!.toDouble())
              .reduce((a, b) => a + b) /
          moduleTopics.length;
      return RadarEntry(value: avg);
    }).toList();

    return _buildSectionShell(
      'Subject Radar Chart',
      RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.deepViolet.withValues(alpha: 0.35),
              borderColor: AppColors.cyan,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: entries,
            ),
          ],
          radarShape: RadarShape.polygon,
          ticksTextStyle: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
          tickCount: 5,
          titlePositionPercentageOffset: 0.2,
          tickBorderData: BorderSide(
            color: AppColors.border.withValues(alpha: 0.55),
          ),
          gridBorderData: BorderSide(
            color: AppColors.border.withValues(alpha: 0.7),
          ),
          getTitle: (index, angle) {
            if (index < 0 || index >= radarModules.length) {
              return const RadarChartTitle(text: '');
            }
            return RadarChartTitle(
              text: radarModules[index].name,
              angle: angle,
            );
          },
        ),
      ),
      fixedHeight: 260,
    );
  }

  Widget _buildHeatmap() {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 83));
    final monthLabels = <String>[];
    var lastMonth = -1;

    for (var week = 0; week < 12; week++) {
      final date = startDate.add(Duration(days: week * 7));
      if (date.month != lastMonth) {
        monthLabels.add(_monthShort(date.month));
        lastMonth = date.month;
      } else {
        monthLabels.add('');
      }
    }

    return _buildSectionShell(
      'Study Consistency (12 Weeks)',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              12,
              (index) => Expanded(
                child: Text(
                  monthLabels[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(12, (weekIndex) {
              final weekStart = startDate.add(Duration(days: weekIndex * 7));
              return Expanded(
                child: Column(
                  children: List.generate(7, (dayIndex) {
                    final date = weekStart.add(Duration(days: dayIndex));
                    final count = _heatmapCounts[_dateKey(date)] ?? 0;
                    return Container(
                      margin: const EdgeInsets.all(1.5),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _heatmapColor(count),
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
    );
  }

  Color _heatmapColor(int count) {
    if (count <= 0) return Colors.grey.withValues(alpha: 0.25);
    if (count == 1) return AppColors.deepViolet.withValues(alpha: 0.45);
    return AppColors.deepViolet;
  }

  String _monthShort(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }

  Widget _buildTopicRatingHistory() => _buildSectionShell(
    'Topic Rating History',
    _topics.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Add topics to unlock rating trends.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          )
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TopicModel>(
                    value: _selectedTopic,
                    dropdownColor: AppColors.surfaceDark,
                    isExpanded: true,
                    style: GoogleFonts.inter(color: Colors.white),
                    items: _topics
                        .map(
                          (topic) => DropdownMenuItem<TopicModel>(
                            value: topic,
                            child: Text(topic.name),
                          ),
                        )
                        .toList(),
                    onChanged: (next) {
                      if (next == null) return;
                      setState(() => _selectedTopic = next);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _selectedTopic == null
                    ? const SizedBox.shrink()
                    : _TopicLineChart(
                        topic: _selectedTopic!,
                        topicRepo: _topicRepo,
                      ),
              ),
            ],
          ),
  );

  Widget _buildModuleDonuts() => _buildSectionShell(
    'Module Progress Donut Charts',
    _modules.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Create modules to view progress donuts.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          )
        : SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _modules.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final module = _modules[index];
                final moduleTopics = _topics
                    .where((topic) => topic.moduleId == module.id)
                    .toList();
                final masteredCount = moduleTopics
                    .where((topic) => (topic.currentRating ?? 0) >= 7)
                    .length;
                final percentage = moduleTopics.isEmpty
                    ? 0.0
                    : masteredCount * 100 / moduleTopics.length;

                return _ModuleDonutCard(
                  moduleName: module.name,
                  color: module.subjectColor,
                  percentage: percentage,
                );
              },
            ),
          ),
  );
}

class _TopicLineChart extends StatelessWidget {
  const _TopicLineChart({required this.topic, required this.topicRepo});

  final TopicModel topic;
  final TopicRepository topicRepo;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<TopicRatingHistoryModel>?>(
        future: topicRepo.getTopicRatingHistory(topic.id).then((result) {
          if (result is Success<List<TopicRatingHistoryModel>>) {
            return result.data;
          }
          return <TopicRatingHistoryModel>[];
        }),
        builder: (context, snapshot) {
          final values = snapshot.data ?? <TopicRatingHistoryModel>[];
          if (values.isEmpty) {
            return Center(
              child: Text(
                'No ratings yet for this topic.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }

          final points = values.asMap().entries.map((entry) {
            final rating = entry.value.rating.toDouble();
            return FlSpot(entry.key.toDouble(), rating);
          }).toList();

          return LineChart(
            LineChartData(
              minY: 0,
              maxY: 10,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(drawVerticalLine: false),
              lineTouchData: const LineTouchData(enabled: true),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: true,
                  color: AppColors.cyan,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.deepViolet,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.deepViolet.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _ModuleDonutCard extends StatelessWidget {
  const _ModuleDonutCard({
    required this.moduleName,
    required this.color,
    required this.percentage,
  });

  final String moduleName;
  final Color color;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final clampedPercentage = percentage.clamp(0, 100).toDouble();

    return Container(
      width: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 25,
                    sections: [
                      PieChartSectionData(
                        value: clampedPercentage,
                        color: color,
                        title: '',
                        radius: 14,
                      ),
                      PieChartSectionData(
                        value: 100 - clampedPercentage,
                        color: Colors.grey.withValues(alpha: 0.25),
                        title: '',
                        radius: 14,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${clampedPercentage.round()}%',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            moduleName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
