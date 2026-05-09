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
    backgroundColor: AppColors.backgroundDeep,
    body: _isLoading
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                Text('Loading your study dashboard...'),
              ],
            ),
          )
        : SingleChildScrollView(
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: _AmbientGlow(
                    color: AppColors.neonViolet.withValues(alpha: 0.22),
                  ),
                ),
                Positioned(
                  top: 180,
                  left: -70,
                  child: _AmbientGlow(
                    size: 160,
                    color: AppColors.neonCyan.withValues(alpha: 0.16),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.sm,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          animateEntrance: true,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          borderRadius: AppSpacing.cardRadius,
                          borderColors: const [
                            AppColors.neonViolet,
                            AppColors.neonCyan,
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting.toUpperCase(),
                                style: AppTextStyles.sectionOverline,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _userName ?? 'Student',
                                style: AppTextStyles.displayMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Your study cockpit for today is ready. Pick up where you left off or start a fresh sprint.',
                                style: AppTextStyles.bodyMediumSecondary,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          context.push('/study-session'),
                                      child: const Text('Start Session'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          context.push('/weekly-wrapped'),
                                      child: const Text('Weekly Wrapped'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Today',
                                value:
                                    '${_dailyGoalProgress.toStringAsFixed(1)}h',
                                helper: 'of $_dailyGoalTarget h goal',
                                accent: AppColors.neonViolet,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _MetricCard(
                                label: 'Next exam',
                                value: _nextEventTime ?? 'Ready',
                                helper: _nextEventTitle ?? 'No exam queued',
                                accent: AppColors.neonCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _MetricCard(
                          label: 'Momentum',
                          value: _dailyGoalProgress >= _dailyGoalTarget
                              ? 'Goal met'
                              : '${(_dailyGoalTarget - _dailyGoalProgress).toStringAsFixed(1)}h left',
                          helper: _dailyGoalProgress >= _dailyGoalTarget
                              ? 'You already hit your target for today.'
                              : 'One focused block gets you closer to the target.',
                          accent: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        GlassCard(
                          animateEntrance: true,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          borderRadius: AppSpacing.cardRadius,
                          borderColors: const [
                            AppColors.borderGradientStart,
                            AppColors.borderGradientEnd,
                          ],
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Up Next',
                                      style: AppTextStyles.sectionOverline,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      _nextEventTitle ?? 'No exam scheduled',
                                      style: AppTextStyles.headingMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      _nextEventTime ?? 'You are clear for now',
                                      style: AppTextStyles.bodyMediumSecondary,
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
                                              alpha: 0.18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.pillRadius,
                                            ),
                                          ),
                                          child: Text(
                                            'Exam approaching. Open the countdown.',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: AppColors.danger,
                                                ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              FilledButton(
                                onPressed: () =>
                                    context.push('/exam-countdown'),
                                child: const Text('Open'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Quick Start',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.4,
                          children: [
                            _QuickActionCard(
                              icon: Icons.calendar_month_rounded,
                              label: 'Timetable',
                              description: 'Plan the week',
                              onTap: () => context.go('/home/timetable'),
                            ),
                            _QuickActionCard(
                              icon: Icons.menu_book_rounded,
                              label: 'Modules',
                              description: 'Open your syllabus',
                              onTap: () => context.go('/home/modules'),
                            ),
                            _QuickActionCard(
                              icon: Icons.auto_graph_rounded,
                              label: 'Progress',
                              description: 'Track momentum',
                              onTap: () => context.go('/home/progress'),
                            ),
                            _QuickActionCard(
                              icon: Icons.groups_rounded,
                              label: 'Groups',
                              description: 'Study together',
                              onTap: () => context.go('/home/groups'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
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
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.cardRadius,
      animateEntrance: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.captionSecondary),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.accent,
  });

  final String label;
  final String value;
  final String helper;
  final Color accent;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    borderRadius: AppSpacing.cardRadius,
    borderColors: [accent.withValues(alpha: 0.9), AppColors.borderSoft],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.captionSecondary),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headingSmall.copyWith(color: accent),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(helper, style: AppTextStyles.caption),
      ],
    ),
  );
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, this.size = 220});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}
