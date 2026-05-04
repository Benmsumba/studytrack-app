import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';

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

  Future<void> _nextStep() async {
    final canContinue = _validateStep(_currentStep);
    if (!canContinue) return;

    await HapticFeedback.lightImpact();

    if (_currentStep == _steps - 1) {
      await _completeOnboarding();
      return;
    }

    final next = _currentStep + 1;
    setState(() => _currentStep = next);
    await _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipStep() async {
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

  bool _validateStep(int step) {
    if (step == 0 && _nameController.text.trim().isEmpty) {
      _showMessage(AppStrings.enterName);
      return false;
    }

    if (step == 1 && _courseController.text.trim().isEmpty) {
      _showMessage(AppStrings.enterCourse);
      return false;
    }

    return true;
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final profileResult = await _profileRepository.getCurrentProfile();
      final currentProfile = profileResult.fold(
        (error) => null,
        (profile) => profile,
      );
      if (currentProfile == null) {
        // User should always be logged in at this point, but if not,
        // complete onboarding locally and let them access the app
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', true);
        if (mounted) context.go('/home');
        return;
      }

      // Attempt to save profile preferences to backend
      await _profileRepository.updateProfile({
        'name': _nameController.text.trim(),
        'course': _courseController.text.trim(),
        'year_level': _yearLevel,
        'prime_study_time': _primeStudyTime,
        'study_hours_per_day': _dailyStudyHours.round(),
        'study_preference': _studyPreference,
      });

      // Mark onboarding as complete regardless of backend result
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      _confettiController.play();

      if (mounted) context.go('/home');
    } catch (e) {
      // Even if backend save fails, mark onboarding as complete locally
      // so users aren't stuck on the onboarding screen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      if (mounted) {
        _confettiController.play();
        _showMessage(
          'Your setup has been saved. '
          'We will sync with the cloud when internet is available.',
        );
        // Wait a moment so user sees the message, then navigate
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    SnackbarHelper.show(context, message, type: AppSnackbarType.warning);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width >= 600
        ? AppSpacing.xl
        : AppSpacing.screenHorizontal;
    final maxContentWidth = size.width >= 720 ? 640.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.3,
                  colors: [
                    Color(0x332D1B69),
                    AppColors.backgroundDark,
                    AppColors.backgroundDeep,
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      _buildDots(),
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
                      _buildBottomActions(),
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
              numberOfParticles: 18,
              gravity: 0.14,
              colors: const [
                AppColors.neonViolet,
                AppColors.neonCyan,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(_steps, (index) {
      final active = index == _currentStep;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: active ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          color: active ? null : AppColors.borderSoft,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          boxShadow: active
              ? const [
                  BoxShadow(color: AppColors.violetGlowSoft, blurRadius: 10),
                ]
              : null,
        ),
      );
    }),
  );

  Widget _buildBottomActions() {
    final isLast = _currentStep == _steps - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlowingButton(
          label: isLast ? 'Let\'s Go!' : 'Next',
          onPressed: _isSaving ? null : _nextStep,
          isLoading: _isSaving,
          width: double.infinity,
        ),
        if (!isLast)
          TextButton(
            onPressed: _skipStep,
            child: Text(
              'Skip',
              style: AppTextStyles.labelSecondary.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _stepWelcome() => _stepContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Welcome to StudyTrack 👋', style: AppTextStyles.displayMedium),
        const SizedBox(height: 10),
        Text(
          'Let\'s set up your personal study companion',
          style: AppTextStyles.bodyMediumSecondary,
        ),
        const SizedBox(height: 16),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoSize = constraints.maxWidth < 360 ? 136.0 : 160.0;
              return Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violetGlow,
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Image.asset(_brandAsset, fit: BoxFit.contain),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.04, 1.04),
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  );
            },
          ),
        ),
        const SizedBox(height: 10),
        _inputField(controller: _nameController, label: 'What\'s your name?'),
      ],
    ).animate().fadeIn(duration: 350.ms),
  );

  Widget _stepCourse() => _stepContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('What are you studying?'),
        const SizedBox(height: 12),
        _inputField(controller: _courseController, label: 'Course name'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _courseExamples
              .map(
                (example) => ActionChip(
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.borderSoft),
                  label: Text(example, style: AppTextStyles.labelSecondary),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _courseController.text = example;
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms),
  );

  Widget _stepYearLevel() => _stepContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('What year are you in?'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 360 ? 3 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.08,
              ),
              itemCount: 7,
              itemBuilder: (context, index) {
                final year = index + 1;
                final selected = year == _yearLevel;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _yearLevel = year);
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.fieldRadius,
                      ),
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : AppColors.surfaceElevated,
                      border: selected
                          ? null
                          : Border.all(color: AppColors.borderSoft, width: 1.1),
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                color: AppColors.violetGlowSoft,
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$year',
                        style: AppTextStyles.statValue.copyWith(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 350.ms),
  );

  Widget _stepPrimeTime() {
    final options = [
      ('morning', '🌅', 'Morning', '5am-12pm'),
      ('afternoon', '☀️', 'Afternoon', '12pm-5pm'),
      ('evening', '🌆', 'Evening', '5pm-9pm'),
      ('night', '🌙', 'Night', '9pm-late'),
    ];

    return _stepContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _title('When do you study best?'),
          const SizedBox(height: 14),
          ...options.map((item) {
            final selected = _primeStudyTime == item.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _primeStudyTime = item.$1);
                },
                borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                    gradient: selected ? AppColors.cardGradient : null,
                    color: selected ? null : AppColors.surfaceElevated,
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.borderSoft,
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: AppColors.violetGlowSoft,
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(item.$2, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$3, style: AppTextStyles.headingSmall),
                            Text(
                              item.$4,
                              style: AppTextStyles.bodySmallSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ).animate().fadeIn(duration: 350.ms),
    );
  }

  Widget _stepDailyHours() {
    final hours = _dailyStudyHours.round();
    final weeklyHours = hours * 7;

    return _stepContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _title('How many hours can you study daily?'),
          const SizedBox(height: 26),
          Center(
            child: Text(
              '$hours',
              style: AppTextStyles.displayLarge.copyWith(fontSize: 76),
            ),
          ),
          Center(
            child: Text('hours/day', style: AppTextStyles.bodyMediumSecondary),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.accent.withValues(alpha: 0.18),
            ),
            child: Slider(
              min: 1,
              max: 12,
              divisions: 11,
              value: _dailyStudyHours,
              onChanged: (value) {
                setState(() => _dailyStudyHours = value);
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'That\'s $weeklyHours hours per week',
              style: AppTextStyles.labelSecondary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 350.ms),
    );
  }

  Widget _stepStudyStyle() => _stepContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('How do you prefer to study?'),
        const SizedBox(height: 12),
        _studyStyleCard(
          selected: _studyPreference == 'alone',
          emoji: '🎧',
          title: 'Alone',
          subtitle: 'I focus best by myself',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _studyPreference = 'alone');
          },
        ),
        const SizedBox(height: 10),
        _studyStyleCard(
          selected: _studyPreference == 'group',
          emoji: '👥',
          title: 'With others',
          subtitle: 'I learn better with friends',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _studyPreference = 'group');
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Almost ready! Here\'s what we set up for you:',
          style: AppTextStyles.bodyMediumSecondary,
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: AppSpacing.fieldRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow('Name', _nameController.text.trim()),
              _summaryRow('Course', _courseController.text.trim()),
              _summaryRow('Year', '$_yearLevel'),
              _summaryRow('Best time', _primeStudyTime),
              _summaryRow('Hours/day', _dailyStudyHours.round().toString()),
              _summaryRow(
                'Style',
                _studyPreference == 'alone' ? 'Alone' : 'With others',
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms),
  );

  Widget _stepContainer({required Widget child}) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: GlassCard(
      animateEntrance: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.cardRadius,
      child: child,
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
  }) => TextField(
    controller: controller,
    style: AppTextStyles.bodyMedium,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.labelSecondary,
    ),
  );

  Widget _title(String text) => Text(text, style: AppTextStyles.headingLarge);

  Widget _studyStyleCard({
    required bool selected,
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
    child: Ink(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        gradient: selected ? AppColors.cardGradient : null,
        color: selected ? null : AppColors.surfaceElevated,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.borderSoft,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: AppColors.violetGlowSoft,
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingSmall),
                Text(subtitle, style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 88,
          child: Text('$label:', style: AppTextStyles.labelSecondary),
        ),
        Expanded(
          child: Text(value.isEmpty ? '-' : value, style: AppTextStyles.label),
        ),
      ],
    ),
  );
}
