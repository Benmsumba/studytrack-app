import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/loading_shimmer_widget.dart';
import '../../../models/weekly_report_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _service = SupabaseService();
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
      final user = _service.getCurrentUser();
      if (user == null) return;

      final profile = await _service.getProfile(user.id);
      final modules = await _service.getModules(user.id) ?? [];
      final lastReport = await _service.getLastWeekReport(user.id);

      var total = 0;
      var mastered = 0;

      for (final module in modules) {
        final topics = await _service.getTopics(module.id) ?? [];
        total += topics.length;
        mastered += topics.where((t) => (t.currentRating ?? 0) >= 7).length;
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _lastWeeklyReport = lastReport == null
            ? null
            : WeeklyReportModel.fromJson(lastReport);
        _totalTopics = total;
        _masteredTopics = mastered;
        _longestStreak = (profile?['streak_count'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
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
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
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
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$course • Year $yearLevel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
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
              Text(
                'Achievements',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportWeeklyReport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isExporting
                        ? 'Preparing PDF...'
                        : 'Export Weekly Report (PDF)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBackingUp ? null : _backupToGoogleDrive,
                  icon: _isBackingUp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.backup),
                  label: Text(
                    _isBackingUp
                        ? 'Preparing Backup...'
                        : 'Backup to Google Drive',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportWeeklyReport() async {
    final user = _service.getCurrentUser();
    if (user == null) {
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
    final user = _service.getCurrentUser();
    if (user == null || _profile == null) {
      SnackbarHelper.show(
        context,
        'Please sign in to back up your data.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    setState(() => _isBackingUp = true);
    try {
      final modules = await _service.getModules(user.id) ?? [];
      final exams = await _service.getUpcomingExams(user.id) ?? [];

      final backup = await _exportService.createBackupJson(
        userId: user.id,
        profile: _profile!,
        modules: modules.map((module) => module.toJson()).toList(),
        exams: exams,
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shareable Social Card',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$name • $masteredTopics/$totalTopics topics mastered • $streak day streak',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
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
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 1),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textSecondary,
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
        borderRadius: BorderRadius.circular(12),
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
            style: GoogleFonts.inter(
              fontSize: 8,
              color: earned ? Colors.white : AppColors.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}
