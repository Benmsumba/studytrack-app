import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/exam_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/repositories/weekly_report_repository.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/loading_shimmer_widget.dart';
import '../../../models/badge_model.dart';
import '../../../models/exam_model.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';
import '../../../models/weekly_report_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Badge catalogue — every badge type the achievement_service can award.
// ─────────────────────────────────────────────────────────────────────────────
class _BadgeMeta {
  const _BadgeMeta({
    required this.type,
    required this.emoji,
    required this.label,
    required this.description,
  });
  final String type;
  final String emoji;
  final String label;
  final String description;
}

const List<_BadgeMeta> _allBadges = [
  _BadgeMeta(
    type: 'first_step',
    emoji: '🌱',
    label: 'First Step',
    description: 'Added your first topic',
  ),
  _BadgeMeta(
    type: 'week_warrior',
    emoji: '🔥',
    label: 'Week Warrior',
    description: '7-day study streak',
  ),
  _BadgeMeta(
    type: 'perfectionist',
    emoji: '💎',
    label: 'Perfectionist',
    description: 'Rated a topic 10/10',
  ),
  _BadgeMeta(
    type: 'bookworm',
    emoji: '📚',
    label: 'Bookworm',
    description: 'Studied 50 topics',
  ),
  _BadgeMeta(
    type: 'master',
    emoji: '🏆',
    label: 'Master',
    description: '10 topics rated 8+',
  ),
  _BadgeMeta(
    type: 'month_streak',
    emoji: '🌙',
    label: 'Night Owl',
    description: '30-day study streak',
  ),
  _BadgeMeta(
    type: 'century',
    emoji: '💯',
    label: 'Century',
    description: '100 topics created',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// XP / Level helpers
// ─────────────────────────────────────────────────────────────────────────────
int _xpFromMastered(int mastered) => mastered * 25;

int _levelFromXp(int xp) => (xp ~/ 100) + 1;

String _levelTitle(int level) {
  if (level >= 30) return 'Grand Master';
  if (level >= 20) return 'Scholar';
  if (level >= 15) return 'Expert';
  if (level >= 10) return 'Advanced';
  if (level >= 5) return 'Intermediate';
  return 'Beginner';
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = getIt<ProfileRepository>();
  final ModuleRepository _moduleRepository = getIt<ModuleRepository>();
  final TopicRepository _topicRepository = getIt<TopicRepository>();
  final WeeklyReportRepository _weeklyReportRepository =
      getIt<WeeklyReportRepository>();
  final ExamRepository _examRepository = getIt<ExamRepository>();
  final ExportService _exportService = ExportService();
  late final AchievementService _achievementService =
      AchievementService(supabaseService: getIt<SupabaseService>());

  bool _isLoading = true;
  bool _isExporting = false;
  bool _isBackingUp = false;

  Map<String, dynamic>? _profile;
  WeeklyReportModel? _lastWeeklyReport;
  int _totalTopics = 0;
  int _masteredTopics = 0;
  int _longestStreak = 0;
  Set<String> _earnedBadgeTypes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profileResult = await _profileRepository.getCurrentProfile();
      final profile = switch (profileResult) {
        Success(data: final data) => data,
        Failure(error: final _) => null,
      };

      if (profile == null) {
        if (!mounted) return;
        setState(() {
          _profile = <String, dynamic>{};
          _isLoading = false;
        });
        return;
      }

      final modules = await _loadModules();
      final lastReport = await _loadLastWeeklyReport();

      var total = 0;
      var mastered = 0;

      for (final module in modules) {
        final topics = await _loadTopics(module.id);
        total += topics.length;
        mastered +=
            topics.where((t) => (t.currentRating ?? 0) >= 7).length;
      }

      // Load earned badges
      final userId = profile['id']?.toString() ?? '';
      var earnedTypes = <String>{};
      if (userId.isNotEmpty) {
        try {
          final badges =
              await _achievementService.checkAllBadges(userId);
          earnedTypes = badges.map((b) => b.badgeType).toSet();
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _lastWeeklyReport = lastReport;
        _totalTopics = total;
        _masteredTopics = mastered;
        _longestStreak = (profile['streak_count'] as num?)?.toInt() ?? 0;
        _earnedBadgeTypes = earnedTypes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _profile = <String, dynamic>{};
          _isLoading = false;
        });
      }
    }
  }

  String? get _userId => (_profile?['id'] as String?)?.trim();

  Future<List<ModuleModel>> _loadModules() async {
    final result = await _moduleRepository.getAllModules();
    return switch (result) {
      Success(data: final data) => data,
      Failure(error: final _) => <ModuleModel>[],
    };
  }

  Future<List<TopicModel>> _loadTopics(String moduleId) async {
    final result = await _topicRepository.getTopicsByModule(moduleId);
    return switch (result) {
      Success(data: final data) => data,
      Failure(error: final _) => <TopicModel>[],
    };
  }

  Future<WeeklyReportModel?> _loadLastWeeklyReport() async {
    final result = await _weeklyReportRepository.getLastWeeklyReport();
    return switch (result) {
      Success(data: final data) => data,
      Failure(error: final _) => null,
    };
  }

  Future<List<ExamModel>> _loadUpcomingExams() async {
    final result = await _examRepository.getUpcomingExams();
    return switch (result) {
      Success(data: final data) => data,
      Failure(error: final _) => <ExamModel>[],
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: LoadingShimmerWidget.profile(),
      );
    }

    final name = (_profile?['name'] as String?) ?? 'Student';
    final course = (_profile?['course'] as String?) ?? 'N/A';
    final yearLevel = (_profile?['year_level'] as num?)?.toInt() ?? 0;
    final xp = _xpFromMastered(_masteredTopics);
    final level = _levelFromXp(xp);
    final xpToNext = 100 - (xp % 100);
    final xpProgress = (xp % 100) / 100.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.xxxl + AppSpacing.lg,
              AppSpacing.screenHorizontal,
              AppSpacing.xxxl + AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar + Level Badge ──
                _AvatarWithRing(
                  name: name,
                  masteryProgress: _totalTopics == 0
                      ? 0
                      : _masteredTopics / _totalTopics,
                ),
                const SizedBox(height: 16),

                // Name + Course
                Text(
                  name,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course,
                      style: AppTextStyles.bodyMediumSecondary,
                    ),
                    if (yearLevel > 0) ...[
                      Text(
                        ' • ',
                        style: AppTextStyles.bodyMediumSecondary,
                      ),
                      Text(
                        'Year $yearLevel',
                        style: AppTextStyles.bodyMediumSecondary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // XP / Level pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.violetGlowSoft,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✦ ', style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text(
                        'Level $level · ${_levelTitle(level)}',
                        style: AppTextStyles.label.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // XP progress bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$xp XP',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$xpToNext XP to next level',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: xpProgress,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.neonViolet,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Stats row ──
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.library_books_rounded,
                        label: 'Topics',
                        value: _totalTopics.toString(),
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.school_rounded,
                        label: 'Mastered',
                        value: _masteredTopics.toString(),
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Streak',
                        value: '$_longestStreak 🔥',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Social Share Card ──
                _SocialCard(
                  name: name,
                  masteredTopics: _masteredTopics,
                  totalTopics: _totalTopics,
                  streak: _longestStreak,
                  level: level,
                  levelTitle: _levelTitle(level),
                  onShare: _shareSocialCard,
                ),
                const SizedBox(height: 28),

                // ── Badges ──
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Achievements',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_earnedBadgeTypes.length}/${_allBadges.length} earned',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.85,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _allBadges.length,
                  itemBuilder: (context, index) {
                    final meta = _allBadges[index];
                    final earned = _earnedBadgeTypes.contains(meta.type);
                    return _BadgeWidget(
                      emoji: meta.emoji,
                      label: meta.label,
                      description: meta.description,
                      earned: earned,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showBadgeTooltip(context, meta, earned);
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),

                // ── Actions ──
                _ActionButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: _isExporting
                      ? 'Preparing PDF…'
                      : 'Export Weekly Report (PDF)',
                  gradient: AppColors.primaryGradient,
                  loading: _isExporting,
                  onTap: _isExporting ? null : _exportWeeklyReport,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.backup_rounded,
                  label:
                      _isBackingUp ? 'Preparing Backup…' : 'Backup to Google Drive',
                  gradient: const LinearGradient(
                    colors: [AppColors.surfaceDark, AppColors.cardDark],
                  ),
                  loading: _isBackingUp,
                  onTap: _isBackingUp ? null : _backupToGoogleDrive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBadgeTooltip(
    BuildContext context,
    _BadgeMeta meta,
    bool earned,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(
            color: earned ? AppColors.primary : AppColors.border,
            width: earned ? 1.5 : 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              meta.emoji,
              style: TextStyle(
                fontSize: 48,
                color: earned ? Colors.white : Colors.white38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              meta.label,
              style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              meta.description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: earned
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: earned ? AppColors.success : AppColors.border,
                ),
              ),
              child: Text(
                earned ? '✓ Earned' : 'Not yet earned',
                style: AppTextStyles.caption.copyWith(
                  color: earned ? AppColors.success : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: AppTextStyles.button.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportWeeklyReport() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      SnackbarHelper.show(
        context,
        'Please sign in to export your report.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final file = await _exportService.createWeeklyReportPdf(
        studentName: (_profile?['name'] as String?) ?? 'Student',
        course: (_profile?['course'] as String?) ?? 'N/A',
        yearLevel: (_profile?['year_level'] as num?)?.toInt() ?? 0,
        weeklyReport: _lastWeeklyReport,
        totalTopics: _totalTopics,
        masteredTopics: _masteredTopics,
        streakCount: _longestStreak,
      );
      await _exportService.shareFileToGoogleDrive(
        file: file,
        message:
            'Weekly report from StudyTrack. Choose Google Drive from the share sheet to save a copy.',
      );
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Weekly report PDF is ready to share.',
        type: AppSnackbarType.success,
      );
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Failed to export report: $error',
        type: AppSnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _backupToGoogleDrive() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty || _profile == null) {
      SnackbarHelper.show(
        context,
        'Please sign in to back up your data.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    setState(() => _isBackingUp = true);
    try {
      final modules = await _loadModules();
      final exams = await _loadUpcomingExams();
      final backup = await _exportService.createBackupJson(
        userId: userId,
        profile: _profile!,
        modules: modules.map((m) => m.toJson()).toList(),
        exams: exams.map((e) => e.toJson()).toList(),
      );
      await _exportService.shareFileToGoogleDrive(
        file: backup,
        message:
            'StudyTrack backup JSON. Select Google Drive from share options to store this backup.',
      );
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Backup file ready. Save it to Google Drive from share options.',
        type: AppSnackbarType.success,
      );
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Backup failed: $error',
        type: AppSnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _shareSocialCard() async {
    final name = (_profile?['name'] as String?) ?? 'Student';
    final xp = _xpFromMastered(_masteredTopics);
    final level = _levelFromXp(xp);
    final message =
        '📘 $name on StudyTrack\n'
        '🏆 Level $level · ${_levelTitle(level)}\n'
        '✅ Mastered topics: $_masteredTopics/$_totalTopics\n'
        '🔥 Streak: $_longestStreak days\n'
        '⭐ Badges earned: ${_earnedBadgeTypes.length}/${_allBadges.length}';
    await SharePlus.instance.share(ShareParams(text: message));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarWithRing extends StatelessWidget {
  const _AvatarWithRing({
    required this.name,
    required this.masteryProgress,
  });

  final String name;
  final double masteryProgress;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 100,
    height: 100,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Mastery ring
        CustomPaint(
          size: const Size(100, 100),
          painter: _RingPainter(progress: masteryProgress),
        ),
        // Avatar circle
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.displayMedium.copyWith(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        // Mastery % badge (bottom-right)
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.backgroundDark, width: 2),
            ),
            child: Center(
              child: Text(
                '${(masteryProgress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.neonViolet, AppColors.neonCyan],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.statValue.copyWith(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.captionMuted.copyWith(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.name,
    required this.masteredTopics,
    required this.totalTopics,
    required this.streak,
    required this.level,
    required this.levelTitle,
    required this.onShare,
  });

  final String name;
  final int masteredTopics;
  final int totalTopics;
  final int streak;
  final int level;
  final String levelTitle;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      boxShadow: const [
        BoxShadow(
          color: AppColors.violetGlowSoft,
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('✦ ', style: TextStyle(color: Colors.white, fontSize: 13)),
            Text(
              'Share Your Progress',
              style: AppTextStyles.label.copyWith(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: AppTextStyles.headingSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Level $level · $levelTitle  •  $masteredTopics/$totalTopics mastered  •  $streak day streak 🔥',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onShare();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white38),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.ios_share_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Share Card',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _BadgeWidget extends StatelessWidget {
  const _BadgeWidget({
    required this.emoji,
    required this.label,
    required this.description,
    required this.earned,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String description;
  final bool earned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        decoration: BoxDecoration(
          color: earned
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.border,
            width: earned ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 26,
                color: earned ? Colors.white : Colors.white38,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionMuted.copyWith(
                  color: earned ? Colors.white : AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: earned ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    this.loading = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      onTap?.call();
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: onTap == null ? null : gradient,
        color: onTap == null ? AppColors.cardDark : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ) else Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.button.copyWith(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}
