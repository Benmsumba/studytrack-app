import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/exam_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/module_model.dart';
import '../../../models/study_session_model.dart';
import '../../../models/exam_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProfileRepository _profileRepository;
  late final ModuleRepository _moduleRepository;
  late final StudySessionRepository _studySessionRepository;
  late final ExamRepository _examRepository;

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
    _profileRepository = getIt<ProfileRepository>();
    _moduleRepository = getIt<ModuleRepository>();
    _studySessionRepository = getIt<StudySessionRepository>();
    _examRepository = getIt<ExamRepository>();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final profileResult = await _profileRepository.getCurrentProfile();
      Map<String, dynamic>? profile;
      profileResult.fold((error) {}, (value) => profile = value);
      final userId = profile?['id']?.toString() ?? '';

      if (profile == null || userId.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final currentProfile = profile!;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final modulesResult = await _moduleRepository.getAllModules();
      final sessionsResult = await _studySessionRepository
          .getSessionsByDateRange(startDate: startOfDay, endDate: endOfDay);
      final examsResult = await _examRepository.getUpcomingExams();

      List<ModuleModel> modules = const [];
      List<StudySessionModel> todaySessions = const [];
      List<ExamModel> upcomingExams = const [];

      modulesResult.fold((error) {}, (value) => modules = value);
      sessionsResult.fold((error) {}, (value) => todaySessions = value);
      examsResult.fold((error) {}, (value) => upcomingExams = value);

      final activeSession = todaySessions.isEmpty ? null : todaySessions.first;
      final upcomingExam = upcomingExams.isEmpty ? null : upcomingExams.first;

      final completedMinutes = todaySessions.fold<int>(
        0,
        (int total, StudySessionModel session) =>
            total + _sessionMinutes(session),
      );

      final name = _displayName(currentProfile);
      final avatarUrl = currentProfile['avatar_url']?.toString().trim();
      final streakCount =
          (currentProfile['streak_count'] as num?)?.toInt() ?? 0;
      final targetHours =
          (currentProfile['study_hours_per_day'] as num?)?.toInt() ?? 3;
      final sessionProgress = targetHours <= 0
          ? 0.0
          : math
                .min(completedMinutes.toDouble() / (targetHours * 60.0), 1.0)
                .toDouble();

      final topicName = activeSession?.title ?? 'No active session';
      final moduleName =
          _resolveModuleName(activeSession, modules) ?? 'Add a study session';

      final examName = upcomingExam?.title ?? 'No upcoming exam';
      final examDate = upcomingExam?.examDate;
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
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _displayName(Map<String, dynamic> profile) {
    final candidates = [
      profile['display_name'],
      profile['name'],
      profile['full_name'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return 'Student';
  }

  String? _resolveModuleName(
    StudySessionModel? session,
    List<ModuleModel> modules,
  ) {
    final moduleId = session?.moduleId;
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

  int _sessionMinutes(StudySessionModel session) {
    return session.actualDurationMinutes ?? session.durationMinutes ?? 0;
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
