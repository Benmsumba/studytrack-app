import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/exam_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/glass_card.dart';

/// 2026 dashboard hub — a bento grid that surfaces every feature in one
/// scroll. Greeting hero → momentum stats → quick actions grid → tools
/// directory. Every tile routes to a single feature; nothing is buried.
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
  String _greetingEmoji = '👋';
  String? _userName;
  double _dailyGoalProgress = 0;
  static const double _dailyGoalTarget = 3;
  String? _nextEventTitle;
  String? _nextEventCountdown;
  int? _examCountdownDays;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _refresh() async {
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      _updateGreeting();

      final userResult = await _authRepository.getCurrentUser();
      _userName = userResult.fold(
        (_) => null,
        (user) => user?.name ?? 'Student',
      );

      final examsResult = await _examRepository.getUpcomingExams();
      examsResult.fold((_) => null, (exams) {
        if (exams.isNotEmpty) {
          final next = exams.first;
          _nextEventTitle = next.title;
          _examCountdownDays =
              next.examDate.difference(DateTime.now()).inDays;
          _nextEventCountdown = _examCountdownDays == 0
              ? 'Today'
              : _examCountdownDays == 1
                  ? 'Tomorrow'
                  : 'In $_examCountdownDays days';
        }
      });

      final sessionsResult = await _sessionRepository.getSessionsToday();
      sessionsResult.fold((_) => null, (sessions) {
        var totalHours = 0.0;
        for (final s in sessions) {
          totalHours +=
              ((s.actualDurationMinutes ?? s.durationMinutes) ?? 0) / 60.0;
        }
        _dailyGoalProgress = totalHours;
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      AppLogger.warning('HomeScreen load error', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
      _greetingEmoji = '☀️';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
      _greetingEmoji = '🌤️';
    } else if (hour < 21) {
      _greeting = 'Good evening';
      _greetingEmoji = '🌆';
    } else {
      _greeting = 'Good night';
      _greetingEmoji = '🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LoadingState();
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.xs,
          AppSpacing.screenHorizontal,
          AppSpacing.xxl,
        ),
        children: [
          _GreetingHero(
            greeting: _greeting,
            emoji: _greetingEmoji,
            name: _userName ?? 'Student',
          ).animate().fadeIn(duration: 320.ms).moveY(begin: 12, end: 0),
          const SizedBox(height: AppSpacing.lg),
          _MomentumRow(
            studiedHours: _dailyGoalProgress,
            goalHours: _dailyGoalTarget,
            countdown: _nextEventCountdown,
            examTitle: _nextEventTitle,
          ).animate(delay: 80.ms).fadeIn(duration: 320.ms).moveY(begin: 12, end: 0),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: AppSpacing.sm),
          _QuickActionsGrid()
              .animate(delay: 160.ms)
              .fadeIn(duration: 320.ms)
              .moveY(begin: 12, end: 0),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: 'Study tools'),
          const SizedBox(height: AppSpacing.sm),
          _ToolsList()
              .animate(delay: 240.ms)
              .fadeIn(duration: 320.ms)
              .moveY(begin: 12, end: 0),
          const SizedBox(height: AppSpacing.xl),
          _ProgressCallout(
              progress: _dailyGoalProgress,
              target: _dailyGoalTarget)
              .animate(delay: 320.ms)
              .fadeIn(duration: 320.ms)
              .moveY(begin: 12, end: 0),
        ],
      ),
    );
  }
}

// ─── Greeting hero ───────────────────────────────────────────────────────────
class _GreetingHero extends StatelessWidget {
  const _GreetingHero({
    required this.greeting,
    required this.emoji,
    required this.name,
  });

  final String greeting;
  final String emoji;
  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                greeting.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.textMuted,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Text(emoji, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: theme.textTheme.displayMedium?.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your study cockpit is ready. Pick up where you left off or start a fresh sprint.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PrimaryCta(
                  label: 'Start a Session',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => context.push('/study-session'),
                ),
              ),
              const SizedBox(width: 10),
              _SecondaryCta(
                icon: Icons.celebration_rounded,
                onTap: () => context.push('/weekly-wrapped'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: palette.brandGradient,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            boxShadow: [
              BoxShadow(
                color: palette.glowPrimary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatelessWidget {
  const _SecondaryCta({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        side: BorderSide(color: palette.borderSoft),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: palette.brandSecondary, size: 22),
        ),
      ),
    );
  }
}

// ─── Momentum stats (2-up bento) ─────────────────────────────────────────────
class _MomentumRow extends StatelessWidget {
  const _MomentumRow({
    required this.studiedHours,
    required this.goalHours,
    this.countdown,
    this.examTitle,
  });

  final double studiedHours;
  final double goalHours;
  final String? countdown;
  final String? examTitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progress = (studiedHours / goalHours).clamp(0.0, 1.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _StatTile(
            eyebrow: 'Today',
            primary: '${studiedHours.toStringAsFixed(1)}h',
            secondary: 'of ${goalHours.toStringAsFixed(0)}h goal',
            accent: palette.brandPrimary,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: palette.borderSoft,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(palette.brandPrimary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            eyebrow: 'Next exam',
            primary: countdown ?? 'No exams',
            secondary: examTitle ?? 'You\'re clear ahead',
            accent: palette.brandSecondary,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.brandSecondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: palette.brandSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to plan',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.brandSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () => context.push('/exam-countdown'),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.eyebrow,
    required this.primary,
    required this.secondary,
    required this.accent,
    this.child,
    this.onTap,
  });

  final String eyebrow;
  final String primary;
  final String secondary;
  final Color accent;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: 22,
      gradientBorder: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

// ─── Quick actions grid (2x2 bento) ──────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final actions = <_ActionTile>[
      _ActionTile(
        icon: Icons.calendar_month_rounded,
        title: 'Today',
        subtitle: 'Schedule',
        accent: palette.brandPrimary,
        onTap: () => context.go('/home/timetable'),
      ),
      _ActionTile(
        icon: Icons.menu_book_rounded,
        title: 'Modules',
        subtitle: 'Topics',
        accent: palette.brandSecondary,
        onTap: () => context.go('/home/modules'),
      ),
      _ActionTile(
        icon: Icons.auto_graph_rounded,
        title: 'Insights',
        subtitle: 'Charts',
        accent: palette.success,
        onTap: () => context.go('/home/progress'),
      ),
      _ActionTile(
        icon: Icons.groups_rounded,
        title: 'Groups',
        subtitle: 'Connect',
        accent: palette.brandTertiary,
        onTap: () => context.go('/home/groups'),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: actions,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            color: palette.card,
            border: Border.all(color: palette.borderSoft),
            gradient: LinearGradient(
              colors: [
                palette.card,
                accent.withValues(alpha: palette.isDark ? 0.07 : 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withValues(alpha: palette.isDark ? 0.2 : 0.12),
                ),
                child: Icon(icon, color: accent),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tools list ──────────────────────────────────────────────────────────────
class _ToolsList extends StatelessWidget {
  const _ToolsList();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tools = <_ToolEntry>[
      _ToolEntry(
        icon: Icons.smart_toy_rounded,
        title: 'AI Tutor',
        subtitle: 'Ask questions on any topic',
        accent: palette.brandPrimary,
        onTap: () => context.go('/home/modules'),
      ),
      _ToolEntry(
        icon: Icons.mic_rounded,
        title: 'Voice Notes',
        subtitle: 'Record & transcribe lectures',
        accent: palette.brandSecondary,
        onTap: () => context.push('/voice-notes'),
      ),
      _ToolEntry(
        icon: Icons.bar_chart_rounded,
        title: 'Analytics',
        subtitle: 'Deep performance breakdown',
        accent: palette.success,
        onTap: () => context.push('/analytics'),
      ),
      _ToolEntry(
        icon: Icons.event_available_rounded,
        title: 'Exam Countdown',
        subtitle: 'Pace yourself before the big day',
        accent: palette.warning,
        onTap: () => context.push('/exam-countdown'),
      ),
      _ToolEntry(
        icon: Icons.celebration_rounded,
        title: 'Weekly Wrapped',
        subtitle: 'Your week in review',
        accent: palette.brandTertiary,
        onTap: () => context.push('/weekly-wrapped'),
      ),
    ];
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppSpacing.cardRadius,
      gradientBorder: false,
      child: Column(
        children: [
          for (var i = 0; i < tools.length; i++) ...[
            tools[i],
            if (i != tools.length - 1)
              Divider(height: 1, color: palette.divider, indent: 60),
          ],
        ],
      ),
    );
  }
}

class _ToolEntry extends StatelessWidget {
  const _ToolEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: accent.withValues(alpha: palette.isDark ? 0.18 : 0.1),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section title ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: palette.brandGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

// ─── Progress callout ────────────────────────────────────────────────────────
class _ProgressCallout extends StatelessWidget {
  const _ProgressCallout({required this.progress, required this.target});

  final double progress;
  final double target;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final hit = progress >= target;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.cardRadius,
      gradientBorder: hit,
      child: Row(
        children: [
          Text(hit ? '🎉' : '💪', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hit ? 'Goal smashed' : 'Keep momentum',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  hit
                      ? 'You hit your daily target. Take a well-earned break.'
                      : 'One focused block gets you closer to today\'s ${target.toStringAsFixed(0)}h target.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: palette.brandPrimary),
          const SizedBox(height: 16),
          Text(
            'Loading your dashboard…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
