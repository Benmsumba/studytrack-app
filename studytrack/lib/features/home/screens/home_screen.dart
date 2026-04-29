import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/module_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  String _userName = 'Student';
  String? _avatarUrl;
  int _streakCount = 0;
  String _topicName = 'No active session';
  String _moduleName = 'Add a study session';
  int _targetHours = 3;
  double _dailyHoursFilled = 0;
  double _sessionProgress = 0;
  String _examName = 'No upcoming exam';
  int _daysRemaining = 0;
  double _examReadiness = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final user = _service.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await _service.getProfile(user.id);
      final modules =
          await _service.getModules(user.id) ?? const <ModuleModel>[];
      final todaySessions =
          await _service.getStudySessions(user.id, DateTime.now()) ??
          <Map<String, dynamic>>[];
      final upcomingExams =
          await _service.getUpcomingExams(user.id) ?? <Map<String, dynamic>>[];

      final activeSession = _firstMap(todaySessions);
      final upcomingExam = _firstMap(upcomingExams);
      final examDate = _parseDate(
        upcomingExam?['exam_date'] ??
            upcomingExam?['date'] ??
            upcomingExam?['scheduled_date'],
      );

      final completedMinutes = todaySessions.fold<int>(
        0,
        (total, session) => total + _sessionMinutes(session),
      );

      final name = _displayName(profile, user.email);
      final avatarUrl = profile?['avatar_url']?.toString().trim();
      final streakCount = (profile?['streak_count'] as num?)?.toInt() ?? 0;
      final targetHours =
          (profile?['study_hours_per_day'] as num?)?.toInt() ?? 3;
      final sessionProgress = targetHours <= 0
          ? 0.0
          : math.min(completedMinutes.toDouble() / (targetHours * 60), 1.0);

      final topicName =
          _firstText(activeSession, ['topic_name', 'title', 'name']) ??
          'No active session';
      final moduleName =
          _resolveModuleName(activeSession, modules) ?? 'Add a study session';

      final examName =
          _firstText(upcomingExam, ['title', 'name']) ?? 'No upcoming exam';
      final daysRemaining = examDate == null
          ? 0
          : math.max(examDate.difference(DateTime.now()).inDays, 0);
      final examReadiness = examDate == null
          ? 0.0
          : (1 - (daysRemaining / 21)).clamp(0.0, 1.0).toDouble();

      if (!mounted) return;
      setState(() {
        _userName = name;
        _avatarUrl = avatarUrl;
        _streakCount = streakCount;
        _topicName = topicName;
        _moduleName = moduleName;
        _targetHours = targetHours;
        _dailyHoursFilled = completedMinutes.toDouble() / 60.0;
        _sessionProgress = sessionProgress;
        _examName = examName;
        _daysRemaining = daysRemaining;
        _examReadiness = examReadiness;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _displayName(Map<String, dynamic>? profile, String? email) {
    final candidates = [
      profile?['display_name'],
      profile?['name'],
      profile?['full_name'],
      email?.split('@').first,
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return 'Student';
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

  String? _resolveModuleName(
    Map<String, dynamic>? session,
    List<ModuleModel> modules,
  ) {
    final direct = _firstText(session, ['module_name', 'module']);
    if (direct != null) {
      return direct;
    }

    final moduleId = session?['module_id']?.toString();
    if (moduleId == null || moduleId.isEmpty) {
      return null;
    }

    for (final module in modules) {
      if (module.id == moduleId) {
        return module.name;
      }
    }

    return null;
  }

  int _sessionMinutes(Map<String, dynamic> session) {
    final values = [
      session['actual_duration_minutes'],
      session['planned_duration_minutes'],
      session['duration_minutes'],
    ];

    for (final value in values) {
      if (value is num) {
        return value.toInt();
      }
    }

    return 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surfaceDark,
          onRefresh: _loadHomeData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStudySessionCard(),
                const SizedBox(height: 14),
                _buildDailyGoalCard(),
                const SizedBox(height: 14),
                _buildExamCountdownCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final initials = _userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StudyTrack',
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Good Morning,\n$_userName!',
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 26,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                color: AppColors.cardDark,
              ),
              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            initials.isEmpty ? 'S' : initials,
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials.isEmpty ? 'S' : initials,
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            Positioned(
              bottom: -4,
              right: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.backgroundDark,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 9)),
                    const SizedBox(width: 2),
                    Text(
                      '$_streakCount',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudySessionCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Text(
          'START STUDY SESSION',
          style: AppTextStyles.labelSecondary.copyWith(
            letterSpacing: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: _sessionProgress,
                  strokeWidth: 7,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(_sessionProgress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.displayMedium.copyWith(fontSize: 26),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Topic: $_topicName',
          style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'from $_moduleName module',
          style: AppTextStyles.bodySmallSecondary,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => context.push('/study-session'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'START SESSION',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildDailyGoalCard() {
    final progress = _targetHours <= 0
        ? 0.0
        : (_dailyHoursFilled / _targetHours).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Goal: ${_dailyHoursFilled.toStringAsFixed(1)}/$_targetHours Hours',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.headingSmall.copyWith(
                  fontSize: 14,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCountdownCard() {
    final examLabel = _daysRemaining <= 0 && _examName == 'No upcoming exam'
        ? 'No exams scheduled'
        : '$_examName: $_daysRemaining Days';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examLabel,
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  _examName == 'No upcoming exam'
                      ? 'Add your next exam to start a countdown'
                      : 'Readiness pulse',
                  style: AppTextStyles.bodySmallSecondary,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _examReadiness,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.warning,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    value: _examReadiness,
                    strokeWidth: 5,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.warning,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(_examReadiness * 100).toInt()}%',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
