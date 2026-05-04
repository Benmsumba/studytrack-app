import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/exam_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/repositories/weekly_report_repository.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_shimmer_widget.dart';
import '../../../models/exam_model.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';
import '../../../models/weekly_report_model.dart';

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

  bool _isLoading = true;
  bool _isExporting = false;
  bool _isBackingUp = false;
  Map<String, dynamic>? _profile;
  WeeklyReportModel? _lastWeeklyReport;
  int _totalTopics = 0;
  int _masteredTopics = 0;
  int _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
          _lastWeeklyReport = null;
          _totalTopics = 0;
          _masteredTopics = 0;
          _longestStreak = 0;
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
        mastered += topics.where((t) => (t.currentRating ?? 0) >= 7).length;
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _lastWeeklyReport = lastReport;
        _totalTopics = total;
        _masteredTopics = mastered;
        _longestStreak = (profile['streak_count'] as num?)?.toInt() ?? 0;
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

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl + AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: AppTextStyles.displayMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: AppTextStyles.displayMedium),
              const SizedBox(height: 4),
              Text(
                '$course • Year $yearLevel',
                style: AppTextStyles.bodyMediumSecondary,
              ),
              const SizedBox(height: 32),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Topics',
                      value: _totalTopics.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Mastered',
                      value: _masteredTopics.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Best Streak',
                      value: '$_longestStreak 🔥',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _SocialCard(
                name: name,
                masteredTopics: _masteredTopics,
                totalTopics: _totalTopics,
                streak: _longestStreak,
                onShare: _shareSocialCard,
              ),
              const SizedBox(height: 20),

              // Badges
              Text('Achievements', style: AppTextStyles.headingSmall),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  const _BadgeWidget(
                    emoji: '🌱',
                    label: 'First Step',
                    earned: true,
                  ),
                  _BadgeWidget(
                    emoji: '🔥',
                    label: 'Week Warrior',
                    earned: _longestStreak >= 7,
                  ),
                  _BadgeWidget(
                    emoji: '🏆',
                    label: 'Perfectionist',
                    earned: _masteredTopics >= 5,
                  ),
                  _BadgeWidget(
                    emoji: '📚',
                    label: 'Bookworm',
                    earned: _totalTopics >= 50,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Export Data
              GlowingButton(
                label: _isExporting ? 'Preparing PDF...' : 'Export Weekly Report (PDF)',
                onPressed: _isExporting ? null : _exportWeeklyReport,
                isLoading: _isExporting,
                width: double.infinity,
                icon: const Icon(Icons.download, color: Colors.white, size: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              CustomButton(
                label: _isBackingUp ? 'Preparing Backup...' : 'Backup to Google Drive',
                onPressed: _isBackingUp ? null : _backupToGoogleDrive,
                isLoading: _isBackingUp,
                width: double.infinity,
                gradient: AppColors.cardGradient,
                glowColor: AppColors.neonViolet,
                icon: const Icon(Icons.backup, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
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
      if (mounted) {
        setState(() => _isExporting = false);
      }
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
        modules: modules.map((module) => module.toJson()).toList(),
        exams: exams.map((exam) => exam.toJson()).toList(),
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
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _shareSocialCard() async {
    final name = (_profile?['name'] as String?) ?? 'Student';
    final message =
        '📘 $name on StudyTrack\n'
        'Mastered topics: $_masteredTopics/$_totalTopics\n'
        'Current streak: $_longestStreak days 🔥';

    await SharePlus.instance.share(ShareParams(text: message));
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.name,
    required this.masteredTopics,
    required this.totalTopics,
    required this.streak,
    required this.onShare,
  });

  final String name;
  final int masteredTopics;
  final int totalTopics;
  final int streak;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shareable Social Card', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Text(
          '$name • $masteredTopics/$totalTopics topics mastered • $streak day streak',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
          label: const Text(
            'Share Card',
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white70),
          ),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      border: Border.all(color: AppColors.border, width: 1),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: AppTextStyles.statValue),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.captionMuted),
      ],
    ),
  );
}

class _BadgeWidget extends StatelessWidget {
  const _BadgeWidget({
    required this.emoji,
    required this.label,
    required this.earned,
  });
  final String emoji;
  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.96, end: earned ? 1 : 0.98),
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) =>
        Transform.scale(scale: scale, child: child),
    child: Container(
      decoration: BoxDecoration(
        color: earned
            ? AppColors.cardDark
            : AppColors.cardDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        border: Border.all(
          color: earned ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 28,
              color: earned
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionMuted.copyWith(
              color: earned ? Colors.white : AppColors.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}
