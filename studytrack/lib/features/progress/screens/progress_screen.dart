import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  List<ModuleModel> _modules = [];
  List<TopicModel> _topics = [];
  TopicModel? _selectedTopic;
  Map<int, int> _weeklySessionCounts = {};
  Map<String, int> _heatmapCounts = {};

  int _mastered = 0;
  int _streak = 0;
  int _weekSessions = 0;
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = _service.getCurrentUser();
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final modules = await _service.getModules(user.id) ?? [];

      final allTopics = <TopicModel>[];
      for (final module in modules) {
        final topics = await _service.getTopics(module.id) ?? [];
        allTopics.addAll(topics);
      }

      final ratedTopics = allTopics.where((t) => t.currentRating != null).toList();
      final mastered = allTopics.where((t) => (t.currentRating ?? 0) >= 7).length;
      final avg = ratedTopics.isEmpty
          ? 0.0
          : ratedTopics.fold<double>(0, (sum, t) => sum + (t.currentRating ?? 0)) /
              ratedTopics.length;

      final profile = await _service.getProfile(user.id);
      final streak = (profile?['streak_count'] as num?)?.toInt() ?? 0;

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekly = <int, int>{};
      var weekSessions = 0;

      for (var i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final sessions = await _service.getStudySessions(user.id, day) ?? [];
        weekly[i] = sessions.length;
        weekSessions += sessions.length;
      }

      final heat = <String, int>{};
      for (var dayOffset = 0; dayOffset < 84; dayOffset++) {
        final date = now.subtract(Duration(days: dayOffset));
        final sessions = await _service.getStudySessions(user.id, date) ?? [];
        final key = _dateKey(date);
        heat[key] = sessions.length;
      }

      if (!mounted) return;
      setState(() {
        _modules = modules;
        _topics = allTopics;
        _selectedTopic = allTopics.isNotEmpty ? allTopics.first : null;
        _mastered = mastered;
        _averageRating = double.parse(avg.toStringAsFixed(1));
        _streak = streak;
        _weeklySessionCounts = weekly;
        _weekSessions = weekSessions;
        _heatmapCounts = heat;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Progress load error: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress & Analytics',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/weekly-wrapped'),
                  icon: const Icon(Icons.auto_graph, color: Colors.white),
                  label: Text(
                    'See Wrapped',
                    style: GoogleFonts.outfit(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Weekly Performance',
              height: 220,
              child: _WeeklyBarChart(counts: _weeklySessionCounts),
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'Subject Radar',
              height: 260,
              child: _SubjectRadarChart(modules: _modules, topics: _topics),
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'Study Consistency Heatmap',
              height: 190,
              child: _StudyHeatmap(counts: _heatmapCounts),
            ),
            const SizedBox(height: 20),
            _buildTopicTrendSection(),
            const SizedBox(height: 20),
            _buildModuleDonuts(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'Topics Mastered', value: '$_mastered', icon: '🏆'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(label: 'Current Streak', value: '$_streak', icon: '🔥'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(label: "This Week's Sessions", value: '$_weekSessions', icon: '📚'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(label: 'Average Rating', value: '$_averageRating', icon: '⭐'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required double height,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  Widget _buildTopicTrendSection() {
    if (_topics.isEmpty) {
      return _buildSectionCard(
        title: 'Topic Rating History',
        height: 120,
        child: Center(
          child: Text(
            'Add topics to unlock history charts.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return _buildSectionCard(
      title: 'Topic Rating History',
      height: 260,
      child: Column(
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
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                style: GoogleFonts.inter(color: Colors.white),
                items: _topics
                    .map(
                      (topic) => DropdownMenuItem<TopicModel>(
                        value: topic,
                        child: Text(topic.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedTopic = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedTopic == null
                ? const SizedBox.shrink()
                : _TopicTrendChart(topic: _selectedTopic!, service: _service),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleDonuts() {
    return _buildSectionCard(
      title: 'Module Progress Donuts',
      height: 155,
      child: _modules.isEmpty
          ? Center(
              child: Text(
                'No modules yet.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _modules.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final module = _modules[index];
                final moduleTopics = _topics.where((t) => t.moduleId == module.id).toList();
                final mastered = moduleTopics.where((t) => (t.currentRating ?? 0) >= 7).length;
                final pct = moduleTopics.isEmpty ? 0.0 : mastered * 100 / moduleTopics.length;
                return _ModuleDonut(module: module, percentage: pct);
              },
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Text(icon),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.counts});

  final Map<int, int> counts;

  @override
  Widget build(BuildContext context) {
    final maxY = counts.values.fold<int>(1, (max, value) => value > max ? value : max).toDouble() + 1;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${rod.toY.toInt()} sessions',
              GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          final value = (counts[index] ?? 0).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: Color.lerp(AppColors.primary, AppColors.accent, index / 6),
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final i = value.toInt();
                if (i < 0 || i > 6) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectRadarChart extends StatelessWidget {
  const _SubjectRadarChart({required this.modules, required this.topics});

  final List<ModuleModel> modules;
  final List<TopicModel> topics;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return Center(
        child: Text(
          'Add modules to see your radar chart.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    final trimmedModules = modules.take(6).toList();
    final entries = trimmedModules.map((module) {
      final moduleTopics = topics.where((t) => t.moduleId == module.id && t.currentRating != null).toList();
      final avg = moduleTopics.isEmpty
          ? 0.0
          : moduleTopics.fold<double>(0, (sum, t) => sum + (t.currentRating ?? 0)) / moduleTopics.length;
      return RadarEntry(value: avg);
    }).toList();

    return RadarChart(
      RadarChartData(
        radarTouchData: RadarTouchData(enabled: true),
        dataSets: [
          RadarDataSet(
            fillColor: AppColors.primary.withValues(alpha: 0.35),
            borderColor: AppColors.accent,
            entryRadius: 3,
            borderWidth: 2,
            dataEntries: entries,
          ),
        ],
        tickCount: 5,
        ticksTextStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
        tickBorderData: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        gridBorderData: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        titlePositionPercentageOffset: 0.15,
        getTitle: (index, _) {
          if (index < 0 || index >= trimmedModules.length) {
            return const RadarChartTitle(text: '');
          }
          return RadarChartTitle(
            text: trimmedModules[index].name,
            angle: 0,
          );
        },
      ),
    );
  }
}

class _StudyHeatmap extends StatelessWidget {
  const _StudyHeatmap({required this.counts});

  final Map<String, int> counts;

  String _key(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _cellColor(int count) {
    if (count <= 0) return Colors.grey.withValues(alpha: 0.25);
    if (count == 1) return AppColors.primary.withValues(alpha: 0.45);
    if (count == 2) return AppColors.primary.withValues(alpha: 0.7);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 83));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 12 weeks',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(12, (weekIndex) {
                final weekStart = start.add(Duration(days: weekIndex * 7));
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (dayIndex) {
                      final day = weekStart.add(Duration(days: dayIndex));
                      final count = counts[_key(day)] ?? 0;
                      return Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: _cellColor(count),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicTrendChart extends StatelessWidget {
  const _TopicTrendChart({required this.topic, required this.service});

  final TopicModel topic;
  final SupabaseService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: service.getTopicRatingHistory(topic.id, limit: 20),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Center(
            child: Text(
              'No ratings yet for this topic.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          );
        }

        final history = data.reversed.toList();
        final spots = history.asMap().entries.map((entry) {
          final rating = (entry.value['rating'] as num?)?.toDouble() ?? 0;
          return FlSpot(entry.key.toDouble(), rating);
        }).toList();

        return LineChart(
          LineChartData(
            minY: 0,
            maxY: 10,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, _) => Text(
                    '${value.toInt()}',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.accent,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.primary,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.2)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModuleDonut extends StatelessWidget {
  const _ModuleDonut({required this.module, required this.percentage});

  final ModuleModel module;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0, 100).toDouble();
    return SizedBox(
      width: 120,
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
                    centerSpaceRadius: 24,
                    sections: [
                      PieChartSectionData(
                        value: clamped,
                        color: module.subjectColor,
                        title: '',
                        radius: 16,
                      ),
                      PieChartSectionData(
                        value: 100 - clamped,
                        color: Colors.grey.withValues(alpha: 0.28),
                        title: '',
                        radius: 16,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${clamped.toInt()}%',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            module.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}