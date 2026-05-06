import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/module_model.dart';
import '../../../models/study_session_model.dart';
import '../../../models/topic_model.dart';
import '../../auth/controllers/auth_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ModuleRepository _moduleRepo = getIt<ModuleRepository>();
  final TopicRepository _topicRepo = getIt<TopicRepository>();
  final StudySessionRepository _sessionRepo = getIt<StudySessionRepository>();
  final ProfileRepository _profileRepo = getIt<ProfileRepository>();

  bool _isLoading = true;
  String? _loadError;

  int _streak = 0;
  int _mastered = 0;
  int _weeklySessions = 0;
  double _avgRating = 0;

  List<ModuleModel> _modules = [];
  List<TopicModel> _topics = [];
  final Map<String, int> _heatmapCounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    // Load profile for streak
    final profileResult = await _profileRepo.getProfileById(user.id);
    final streak = profileResult is Success<Map<String, dynamic>?>
        ? (profileResult.data?['streak_count'] as num?)?.toInt() ?? 0
        : 0;

    // Load modules + topics
    final modulesResult = await _moduleRepo.getAllModules();
    final modules = modulesResult is Success<List<ModuleModel>>
        ? modulesResult.data
        : <ModuleModel>[];

    final allTopics = <TopicModel>[];
    for (final module in modules) {
      final r = await _topicRepo.getTopicsByModule(module.id);
      if (r is Success<List<TopicModel>>) allTopics.addAll(r.data);
    }

    final ratings = allTopics
        .where((t) => t.currentRating != null)
        .map((t) => t.currentRating!.toDouble())
        .toList();
    final mastered =
        allTopics.where((t) => (t.currentRating ?? 0) >= 7).length;
    final avgRating = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;

    // Load sessions for heatmap (last 84 days) + this week count
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final heatmapStart = today.subtract(const Duration(days: 83));
    final heatmapEnd = today.add(const Duration(days: 1));
    final weekStart =
        today.subtract(Duration(days: today.weekday - 1));

    final sessionsResult = await _sessionRepo.getSessionsByDateRange(
      startDate: heatmapStart,
      endDate: heatmapEnd,
    );
    final sessions = sessionsResult is Success<List<StudySessionModel>>
        ? sessionsResult.data
        : <StudySessionModel>[];

    // Build heatmap counts
    final heatmapCounts = <String, int>{};
    for (final s in sessions) {
      final key = _dateKey(s.scheduledDate);
      heatmapCounts[key] = (heatmapCounts[key] ?? 0) + 1;
    }

    // Weekly session count
    final weeklySessions = sessions
        .where((s) => !s.scheduledDate.isBefore(weekStart))
        .length;

    if (!mounted) return;
    setState(() {
      _streak = streak;
      _mastered = mastered;
      _weeklySessions = weeklySessions;
      _avgRating = avgRating;
      _modules = modules;
      _topics = allTopics;
      _heatmapCounts
        ..clear()
        ..addAll(heatmapCounts);
      _isLoading = false;
      _loadError = null;
    });
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: SafeArea(
      child: _isLoading
          ? AppStateView.loadingList(itemCount: 4, itemHeight: 120)
          : RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxxl,
                ),
                children: [
                  if (_loadError != null)
                    AppStateView.error(
                      title: 'Analytics unavailable',
                      message: _loadError!,
                      onRetry: _load,
                    )
                  else ...[
                    _buildHeader(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatsRow(),
                    const SizedBox(height: AppSpacing.md),
                    _buildRadarCard(),
                    const SizedBox(height: AppSpacing.md),
                    _buildHeatmapCard(),
                    const SizedBox(height: AppSpacing.md),
                    _buildInsightCard(),
                  ],
                ],
              ),
            ),
    ),
  );

  Widget _buildHeader(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: AppTextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Your study snapshot',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
      GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/weekly-wrapped');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.violetGlowSoft,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wrapped ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text('✦', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildStatsRow() {
    final stats = [
      _StatData(icon: '🔥', label: 'Streak', value: '$_streak days'),
      _StatData(icon: '🏆', label: 'Mastered', value: '$_mastered'),
      _StatData(
        icon: '📚',
        label: 'This Week',
        value: '$_weeklySessions sessions',
      ),
      _StatData(
        icon: '⭐',
        label: 'Avg Rating',
        value: '${_avgRating.toStringAsFixed(1)}/10',
      ),
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < stats.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(s.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  s.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  s.value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadarCard() => GlassCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    backgroundColor: AppColors.cardDark,
    borderRadius: AppSpacing.cardRadius,
    borderColors: const [AppColors.border, AppColors.border],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.radar_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text(
              'Subject Radar',
              style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
            ),
            const Spacer(),
            Text(
              '${_modules.length} modules',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 240,
          child: _modules.isEmpty
              ? Center(
                  child: Text(
                    'Add modules to see your radar chart',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : CustomPaint(
                  painter: _RadarChartPainter(
                    subjects: _modules.take(6).map((m) => m.name).toList(),
                    values: _modules.take(6).map((module) {
                      final moduleTopics = _topics
                          .where((t) =>
                              t.moduleId == module.id &&
                              t.currentRating != null)
                          .toList();
                      if (moduleTopics.isEmpty) return 0.0;
                      return moduleTopics
                              .map((t) => t.currentRating!.toDouble())
                              .reduce((a, b) => a + b) /
                          moduleTopics.length /
                          10.0;
                    }).toList(),
                    accentColor: AppColors.neonViolet,
                    gridColor: AppColors.border,
                    labelColor: AppColors.textMuted,
                  ),
                  child: const SizedBox.expand(),
                ),
        ),
        if (_modules.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _modules.take(6).map((m) {
              final moduleTopics = _topics
                  .where((t) =>
                      t.moduleId == m.id && t.currentRating != null)
                  .toList();
              final avg = moduleTopics.isEmpty
                  ? 0.0
                  : moduleTopics
                          .map((t) => t.currentRating!.toDouble())
                          .reduce((a, b) => a + b) /
                      moduleTopics.length;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: m.subjectColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: m.subjectColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${m.name}  ${avg.toStringAsFixed(1)}',
                  style: AppTextStyles.caption.copyWith(
                    color: m.subjectColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    ),
  );

  Widget _buildHeatmapCard() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 83));

    // Build month labels (one per column-week)
    final monthLabels = <String>[];
    var lastMonth = -1;
    for (var w = 0; w < 12; w++) {
      final d = startDate.add(Duration(days: w * 7));
      if (d.month != lastMonth) {
        monthLabels.add(_monthShort(d.month));
        lastMonth = d.month;
      } else {
        monthLabels.add('');
      }
    }

    // Total sessions in heatmap window
    final total = _heatmapCounts.values.fold<int>(0, (a, b) => a + b);
    final activeDays = _heatmapCounts.values.where((v) => v > 0).length;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.cardDark,
      borderRadius: AppSpacing.cardRadius,
      borderColors: const [AppColors.border, AppColors.border],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.grid_view_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Study Consistency',
                style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Text(
                '$activeDays active days',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$total sessions in the last 12 weeks',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Month labels
          Row(
            children: List.generate(12, (w) {
              return Expanded(
                child: Text(
                  monthLabels[w],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          // Heatmap grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(12, (weekIndex) {
              final weekStart = startDate.add(Duration(days: weekIndex * 7));
              return Expanded(
                child: Column(
                  children: List.generate(7, (dayIndex) {
                    final date = weekStart.add(Duration(days: dayIndex));
                    final count = _heatmapCounts[_dateKey(date)] ?? 0;
                    final isToday = _dateKey(date) == _dateKey(DateTime.now());
                    return Container(
                      margin: const EdgeInsets.all(1.5),
                      height: 11,
                      decoration: BoxDecoration(
                        color: _heatmapColor(count),
                        borderRadius: BorderRadius.circular(2),
                        border: isToday
                            ? Border.all(color: AppColors.accent, width: 1)
                            : null,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Legend
          Row(
            children: [
              Text(
                'Less',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final intensity = i / 4.0;
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? Colors.grey.withValues(alpha: 0.25)
                        : Color.lerp(
                            AppColors.neonViolet.withValues(alpha: 0.35),
                            AppColors.neonViolet,
                            intensity,
                          ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                'More',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    final topModule = _modules.isEmpty
        ? null
        : _modules.reduce((a, b) {
            final aTopics = _topics
                .where((t) => t.moduleId == a.id && t.currentRating != null);
            final bTopics = _topics
                .where((t) => t.moduleId == b.id && t.currentRating != null);
            final aAvg = aTopics.isEmpty
                ? 0.0
                : aTopics.map((t) => t.currentRating!.toDouble()).reduce(
                      (x, y) => x + y,
                    ) /
                    aTopics.length;
            final bAvg = bTopics.isEmpty
                ? 0.0
                : bTopics.map((t) => t.currentRating!.toDouble()).reduce(
                      (x, y) => x + y,
                    ) /
                    bTopics.length;
            return aAvg >= bAvg ? a : b;
          });

    final weakModule = _modules.isEmpty
        ? null
        : _modules.reduce((a, b) {
            final aTopics = _topics
                .where((t) => t.moduleId == a.id && t.currentRating != null);
            final bTopics = _topics
                .where((t) => t.moduleId == b.id && t.currentRating != null);
            final aAvg = aTopics.isEmpty
                ? 11.0
                : aTopics.map((t) => t.currentRating!.toDouble()).reduce(
                      (x, y) => x + y,
                    ) /
                    aTopics.length;
            final bAvg = bTopics.isEmpty
                ? 11.0
                : bTopics.map((t) => t.currentRating!.toDouble()).reduce(
                      (x, y) => x + y,
                    ) /
                    bTopics.length;
            return aAvg <= bAvg ? a : b;
          });

    if (topModule == null) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.cardDark,
      borderRadius: AppSpacing.cardRadius,
      borderColors: const [AppColors.border, AppColors.border],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Insights',
                style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InsightRow(
            icon: '🏆',
            label: 'Strongest Subject',
            value: topModule.name,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (weakModule != null && weakModule.id != topModule.id)
            _InsightRow(
              icon: '📌',
              label: 'Needs Attention',
              value: weakModule.name,
              color: AppColors.warning,
            ),
          const SizedBox(height: AppSpacing.sm),
          _InsightRow(
            icon: '📊',
            label: 'Total Topics',
            value: '${_topics.length} topics across ${_modules.length} modules',
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Color _heatmapColor(int count) {
    if (count <= 0) return Colors.grey.withValues(alpha: 0.25);
    if (count == 1) return AppColors.neonViolet.withValues(alpha: 0.45);
    if (count == 2) return AppColors.neonViolet.withValues(alpha: 0.65);
    return AppColors.neonViolet;
  }

  String _monthShort(int month) {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return labels[month - 1];
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
  });
  final String icon;
  final String label;
  final String value;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ──────────────────────────────────────────────
// Radar Chart CustomPainter
// ──────────────────────────────────────────────

class _RadarChartPainter extends CustomPainter {
  const _RadarChartPainter({
    required this.subjects,
    required this.values,
    required this.accentColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<String> subjects;
  final List<double> values;
  final Color accentColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (subjects.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    final n = subjects.length;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric grid rings
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = _angle(i, n);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw spoke lines
    for (var i = 0; i < n; i++) {
      final angle = _angle(i, n);
      canvas.drawLine(
        center,
        Offset(center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle)),
        gridPaint,
      );
    }

    // Draw filled data polygon
    final clampedValues = values.map((v) => v.clamp(0.0, 1.0)).toList();
    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final angle = _angle(i, n);
      final r = radius * clampedValues[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      i == 0 ? dataPath.moveTo(x, y) : dataPath.lineTo(x, y);
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Dots + labels
    for (var i = 0; i < n; i++) {
      final angle = _angle(i, n);
      final r = radius * clampedValues[i];
      canvas.drawCircle(
        Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)),
        4,
        dotPaint,
      );

      // Truncate long module names
      final rawLabel = subjects[i];
      final label = rawLabel.length > 10 ? '${rawLabel.substring(0, 9)}…' : rawLabel;
      final labelR = radius + 22;
      final lx = center.dx + labelR * math.cos(angle);
      final ly = center.dy + labelR * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: labelColor, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  double _angle(int i, int n) =>
      (i * 2 * math.pi / n) - math.pi / 2;

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) =>
      old.subjects != subjects || old.values != values;
}
