import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/exam_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/expandable_fab.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/progress_ring.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthRepository _authRepository = getIt<AuthRepository>();
  late final ExamRepository _examRepository = getIt<ExamRepository>();
  late final StudySessionRepository _sessionRepository =
      getIt<StudySessionRepository>();

  String _greeting = 'Welcome';
  String? _userName;
  double _dailyGoalProgress = 2.5;
  final double _dailyGoalTarget = 3;
  String? _nextEventTitle;
  String? _nextEventTime;
  int? _examCountdownDays;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get greeting based on time
      _updateGreeting();

      // Get current user
      final userResult = await _authRepository.getCurrentUser();
      _userName = userResult.fold(
        (error) => null,
        (user) => user?.name ?? 'Student',
      );

      // Get upcoming exams
      final examsResult = await _examRepository.getUpcomingExams();
      await examsResult.fold((error) => null, (exams) async {
        if (exams.isNotEmpty) {
          final nextExam = exams.first;
          _nextEventTitle = nextExam.title;
          _examCountdownDays = nextExam.examDate
              .difference(DateTime.now())
              .inDays;
          _nextEventTime = _examCountdownDays == 0
              ? 'Today'
              : _examCountdownDays == 1
              ? 'Tomorrow'
              : 'In $_examCountdownDays days';
        }
        return null;
      });

      // Get daily study sessions for today
      final sessionsResult = await _sessionRepository.getSessionsToday();
      await sessionsResult.fold((error) => null, (sessions) async {
        double totalHours = 0;
        for (final session in sessions) {
          totalHours +=
              ((session.actualDurationMinutes ?? session.durationMinutes) ??
                  0) /
              60;
        }

        _dailyGoalProgress = totalHours;
        return null;
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning ☀️';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon ☀️';
    } else if (hour < 21) {
      _greeting = 'Good Evening 🌆';
    } else {
      _greeting = 'Good Night 🌙';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with greeting
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting, style: AppTextStyles.headingLarge),
                        Text(
                          _userName ?? 'Student',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Daily Goal
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Goal',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: ProgressRing(
                            progress: _dailyGoalProgress,
                            goal: _dailyGoalTarget,
                            unit: 'hours',
                            size: 140,
                            completed: _dailyGoalProgress >= _dailyGoalTarget,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Up Next Card
                    if (_nextEventTitle != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Up Next',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GestureDetector(
                            onTap: () => context.push('/exams'),
                            child: GlassCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              borderRadius: AppSpacing.cardRadius,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nextEventTitle!,
                                    style: AppTextStyles.headingSmall.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        _nextEventTime ?? 'N/A',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (_examCountdownDays != null &&
                                      _examCountdownDays! < 2)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.md,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Exam approaching! Start preparing now',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.xl),

                    // Quick actions section
                    Text(
                      'Quick Start',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Column(
                      children: [
                        _QuickActionCard(
                          icon: Icons.calendar_month_rounded,
                          label: 'View Timetable',
                          onTap: () => context.go('/home/timetable'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _QuickActionCard(
                          icon: Icons.menu_book_rounded,
                          label: 'Browse Modules',
                          onTap: () => context.go('/home/modules'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _QuickActionCard(
                          icon: Icons.auto_graph_rounded,
                          label: 'Check Progress',
                          onTap: () => context.go('/home/progress'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _QuickActionCard(
                          icon: Icons.groups_rounded,
                          label: 'Join Study Group',
                          onTap: () => context.go('/home/groups'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
    floatingActionButton: ExpandableFAB(
      actions: [
        (
          label: 'Voice Note',
          icon: Icons.mic_rounded,
          onTap: () => context.push('/voice-notes'),
        ),
        (
          label: 'Quick Quiz',
          icon: Icons.quiz_rounded,
          onTap: () => context.go('/home/modules'),
        ),
        (
          label: 'Study Session',
          icon: Icons.timer_rounded,
          onTap: () => context.push('/study-session'),
        ),
      ],
    ),
  );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.cardRadius,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.neonViolet.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.neonViolet, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}
