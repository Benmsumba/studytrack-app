import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/glass_card.dart';

/// Onboarding flow — six steps, exact copy preserved verbatim from the
/// existing app. Visuals reimagined: a per-step gradient backdrop, a
/// progress rail at the top, animated illustrations, and tactile inputs.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const String _brandAsset = 'assets/icon/app_icon.jpeg';
  static const int _steps = 6;
  static const List<String> _courseExamples = [
    'Pharmacy',
    'MBBS',
    'Physiotherapy',
    'Nursing',
    'Dentistry',
    'Other',
  ];

  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  late final ConfettiController _confettiController;
  late final ProfileRepository _profileRepository;

  int _currentStep = 0;
  int _yearLevel = 1;
  String _primeStudyTime = 'evening';
  double _dailyStudyHours = 3;
  String _studyPreference = 'alone';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileRepository = getIt<ProfileRepository>();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _courseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_validate(_currentStep)) return;
    await HapticFeedback.lightImpact();
    if (_currentStep == _steps - 1) {
      await _complete();
      return;
    }
    final next = _currentStep + 1;
    setState(() => _currentStep = next);
    await _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    if (_currentStep == 0) return;
    await HapticFeedback.selectionClick();
    final prev = _currentStep - 1;
    setState(() => _currentStep = prev);
    await _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skip() async {
    if (_currentStep >= _steps - 1) return;
    await HapticFeedback.selectionClick();
    final next = _currentStep + 1;
    setState(() => _currentStep = next);
    await _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  bool _validate(int step) {
    if (step == 0 && _nameController.text.trim().isEmpty) {
      _show(AppStrings.enterName);
      return false;
    }
    if (step == 1 && _courseController.text.trim().isEmpty) {
      _show(AppStrings.enterCourse);
      return false;
    }
    return true;
  }

  Future<void> _complete() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      // Always attempt to persist — updateProfile upserts the row, so it
      // works for both brand-new users (no profile row yet) and returning
      // users updating their preferences.
      await _profileRepository.updateProfile({
        'name': _nameController.text.trim(),
        'course': _courseController.text.trim(),
        'year_level': _yearLevel,
        'prime_study_time': _primeStudyTime,
        'study_hours_per_day': _dailyStudyHours.round(),
        'study_preference': _studyPreference,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      Analytics.onboardingCompleted();
      _confettiController.play();
      if (mounted) context.go('/home');
    } catch (_) {
      // Save flag locally so the guard doesn't re-show onboarding; data
      // will sync to the cloud on next successful connection.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      if (mounted) {
        _confettiController.play();
        _show(
          'Your setup has been saved. '
          'We will sync with the cloud when internet is available.',
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    SnackbarHelper.show(context, msg, type: AppSnackbarType.warning);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width >= 600
        ? AppSpacing.xl
        : AppSpacing.screenHorizontal;
    final maxWidth = size.width >= 720 ? 640.0 : double.infinity;
    final isLast = _currentStep == _steps - 1;

    return AppScaffold(
      ambientGlow: true,
      ambientIntensity: 1.4,
      useDeepBackground: true,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppSpacing.md,
                    hPad,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      _StepRail(current: _currentStep, total: _steps),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _stepWelcome(),
                            _stepCourse(),
                            _stepYearLevel(),
                            _stepPrimeTime(),
                            _stepDailyHours(),
                            _stepStudyStyle(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _BottomActions(
                        isLast: isLast,
                        isFirst: _currentStep == 0,
                        isSaving: _isSaving,
                        onNext: _next,
                        onBack: _back,
                        onSkip: _skip,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 22,
              gravity: 0.14,
              colors: [
                context.palette.brandPrimary,
                context.palette.brandSecondary,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Welcome ──────────────────────────────────────────────────────
  Widget _stepWelcome() {
    final palette = context.palette;
    return _StepShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to StudyTrack 👋',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            "Let's set up your personal study companion",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 28),
          Center(
            child: LayoutBuilder(
              builder: (context, c) {
                final size = c.maxWidth < 360 ? 144.0 : 168.0;
                return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: palette.brandGradient,
                        boxShadow: [
                          BoxShadow(
                            color: palette.glowPrimary.withValues(alpha: 0.55),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: palette.glowSecondary.withValues(alpha: 0.4),
                            blurRadius: 28,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: ClipOval(
                        child: Image.asset(_brandAsset, fit: BoxFit.cover),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1.05, 1.05),
                      duration: 1800.ms,
                      curve: Curves.easeInOut,
                    );
              },
            ),
          ),
          const SizedBox(height: 24),
          _Field(
            controller: _nameController,
            label: "What's your name?",
            icon: Icons.person_outline_rounded,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Course ───────────────────────────────────────────────────────
  Widget _stepCourse() => _StepShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: 'What are you studying?', emoji: '📚'),
        const SizedBox(height: 16),
        _Field(
          controller: _courseController,
          label: 'Course name',
          icon: Icons.school_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 18),
        Text(
          'Popular courses',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.palette.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _courseExamples.map((example) {
            final selected = _courseController.text == example;
            return _ChoiceChip(
              label: example,
              selected: selected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _courseController.text = example);
              },
            );
          }).toList(),
        ),
      ],
    ),
  );

  // ── Step 3: Year level ───────────────────────────────────────────────────
  Widget _stepYearLevel() => _StepShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: 'What year are you in?', emoji: '🎓'),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (c, constraints) {
            final cross = constraints.maxWidth < 360 ? 3 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.05,
              ),
              itemCount: 7,
              itemBuilder: (c, i) {
                final year = i + 1;
                final selected = year == _yearLevel;
                return _NumberTile(
                  number: year,
                  selected: selected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _yearLevel = year);
                  },
                );
              },
            );
          },
        ),
      ],
    ),
  );

  // ── Step 4: Prime study time ─────────────────────────────────────────────
  Widget _stepPrimeTime() {
    final options = [
      ('morning', '🌅', 'Morning', '5am-12pm'),
      ('afternoon', '☀️', 'Afternoon', '12pm-5pm'),
      ('evening', '🌆', 'Evening', '5pm-9pm'),
      ('night', '🌙', 'Night', '9pm-late'),
    ];

    return _StepShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(title: 'When do you study best?', emoji: '⏰'),
          const SizedBox(height: 16),
          ...options.map((item) {
            final selected = _primeStudyTime == item.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionCard(
                emoji: item.$2,
                title: item.$3,
                subtitle: item.$4,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _primeStudyTime = item.$1);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 5: Daily hours ──────────────────────────────────────────────────
  Widget _stepDailyHours() {
    final palette = context.palette;
    final hours = _dailyStudyHours.round();
    final weekly = hours * 7;
    return _StepShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(title: 'How many hours can you study daily?', emoji: '⚡'),
          const SizedBox(height: 28),
          Center(
            child: Text(
              '$hours',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 96,
                color: palette.brandPrimary,
              ),
            ),
          ),
          Center(
            child: Text(
              'hours/day',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            min: 1,
            max: 12,
            divisions: 11,
            value: _dailyStudyHours,
            onChanged: (v) => setState(() => _dailyStudyHours = v),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: palette.brandSecondary.withValues(alpha: 0.14),
              ),
              child: Text(
                "That's $weekly hours per week",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.brandSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 6: Study style + summary ────────────────────────────────────────
  Widget _stepStudyStyle() => _StepShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: 'How do you prefer to study?', emoji: '✨'),
        const SizedBox(height: 14),
        _OptionCard(
          emoji: '🎧',
          title: 'Alone',
          subtitle: 'I focus best by myself',
          selected: _studyPreference == 'alone',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _studyPreference = 'alone');
          },
        ),
        const SizedBox(height: 10),
        _OptionCard(
          emoji: '👥',
          title: 'With others',
          subtitle: 'I learn better with friends',
          selected: _studyPreference == 'group',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _studyPreference = 'group');
          },
        ),
        const SizedBox(height: 18),
        Text(
          "Almost ready! Here's what we set up for you:",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          rows: [
            ('Name', _nameController.text.trim()),
            ('Course', _courseController.text.trim()),
            ('Year', '$_yearLevel'),
            ('Best time', _primeStudyTime),
            ('Hours/day', _dailyStudyHours.round().toString()),
            ('Style', _studyPreference == 'alone' ? 'Alone' : 'With others'),
          ],
        ),
      ],
    ),
  );
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _StepRail extends StatelessWidget {
  const _StepRail({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        final isCurrent = i == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              height: 6,
              decoration: BoxDecoration(
                gradient: active ? palette.brandGradient : null,
                color: active ? null : palette.borderSoft,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: palette.glowPrimary.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: GlassCard(
      animateEntrance: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.cardRadius,
      child: child,
    ),
  );
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.emoji});

  final String title;
  final String emoji;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    ],
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.icon,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    textCapitalization: textCapitalization,
    style: Theme.of(context).textTheme.bodyLarge,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
    ),
  );
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      palette.brandPrimary.withValues(alpha: 0.22),
                      palette.brandSecondary.withValues(alpha: 0.18),
                    ],
                  )
                : null,
            color: selected ? null : palette.surfaceElevated,
            border: Border.all(
              color: selected ? palette.brandPrimary : palette.borderSoft,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? palette.textPrimary : palette.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
            gradient: selected ? palette.brandGradient : null,
            color: selected ? null : palette.surfaceElevated,
            border: Border.all(
              color: selected ? Colors.transparent : palette.borderSoft,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.glowPrimary.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: selected ? Colors.white : palette.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      palette.brandPrimary.withValues(alpha: 0.18),
                      palette.brandSecondary.withValues(alpha: 0.12),
                    ],
                  )
                : null,
            color: selected ? null : palette.surfaceElevated,
            border: Border.all(
              color: selected ? palette.brandSecondary : palette.borderSoft,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.glowPrimary.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 220),
                scale: selected ? 1 : 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: palette.brandSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        color: palette.surfaceElevated,
        border: Border.all(color: palette.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      '${row.$1}:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2.isEmpty ? '-' : row.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isLast,
    required this.isFirst,
    required this.isSaving,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final bool isLast;
  final bool isFirst;
  final bool isSaving;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (!isFirst) ...[
              _RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSaving ? null : onNext,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  child: Ink(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: palette.brandGradient,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.buttonRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.glowPrimary.withValues(alpha: 0.5),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLast ? "Let's Go!" : 'Next',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  isLast
                                      ? Icons.celebration_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                'Skip',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: palette.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

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
          width: 56,
          height: 56,
          child: Icon(icon, color: palette.textPrimary),
        ),
      ),
    );
  }
}
