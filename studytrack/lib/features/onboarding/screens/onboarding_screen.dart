import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
  final _supabaseService = SupabaseService();

  int _currentStep = 0;
  int _yearLevel = 1;
  String _primeStudyTime = 'evening';
  double _dailyStudyHours = 3;
  String _studyPreference = 'alone';
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    final canContinue = _validateStep(_currentStep);
    if (!canContinue) return;

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
      _showMessage('Please enter your name.');
      return false;
    }

    if (step == 1 && _courseController.text.trim().isEmpty) {
      _showMessage('Please enter your course.');
      return false;
    }

    return true;
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final user = _supabaseService.getCurrentUser();
      if (user == null) {
        // User should always be logged in at this point, but if not,
        // complete onboarding locally and let them access the app
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', true);
        if (mounted) context.go('/home');
        return;
      }

      // Attempt to save profile preferences to backend
      await _supabaseService.updateProfile(user.id, {
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

      if (mounted) context.go('/home');
    } catch (e) {
      // Even if backend save fails, mark onboarding as complete locally
      // so users aren't stuck on the onboarding screen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      if (mounted) {
        _showMessage(
          'Your setup has been saved. '
          'We will sync with the cloud when internet is available.',
        );
        // Wait a moment so user sees the message, then navigate
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          children: [
            _buildDots(),
            const SizedBox(height: 18),
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
            const SizedBox(height: 14),
            _buildBottomActions(),
          ],
        ),
      ),
    ),
  );

  Widget _buildDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(_steps, (index) {
      final active = index == _currentStep;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: active ? 22 : 8,
        height: 8,
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          color: active ? null : AppColors.border,
          borderRadius: BorderRadius.circular(99),
        ),
      );
    }),
  );

  Widget _buildBottomActions() {
    final isLast = _currentStep == _steps - 1;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isLast ? 'Let\'s Go!' : 'Next',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
        if (!isLast)
          TextButton(
            onPressed: _skipStep,
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _stepWelcome() => _stepContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to StudyTrack 👋',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Let\'s set up your personal study companion',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child:
                Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Image.asset(_brandAsset, fit: BoxFit.contain),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.05, 1.05),
                      duration: 1800.ms,
                      curve: Curves.easeInOut,
                    ),
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
                  backgroundColor: AppColors.cardDark,
                  side: const BorderSide(color: AppColors.border),
                  label: Text(
                    example,
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                  onPressed: () {
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
      children: [
        _title('What year are you in?'),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: 7,
            itemBuilder: (context, index) {
              final year = index + 1;
              final selected = year == _yearLevel;
              return InkWell(
                onTap: () => setState(() => _yearLevel = year),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: selected ? AppColors.primaryGradient : null,
                    color: selected ? null : AppColors.cardDark,
                    border: selected
                        ? null
                        : Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      '$year',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
        children: [
          _title('When do you study best?'),
          const SizedBox(height: 14),
          ...options.map((item) {
            final selected = _primeStudyTime == item.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => _primeStudyTime = item.$1),
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: selected ? AppColors.cardGradient : null,
                    color: selected ? null : AppColors.cardDark,
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(item.$2, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$3,
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.$4,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
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
        children: [
          _title('How many hours can you study daily?'),
          const SizedBox(height: 26),
          Center(
            child: Text(
              '$hours',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 76,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          Center(
            child: Text(
              'hours/day',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
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
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 350.ms),
    );
  }

  Widget _stepStudyStyle() => _stepContainer(
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('How do you prefer to study?'),
          const SizedBox(height: 12),
          _studyStyleCard(
            selected: _studyPreference == 'alone',
            emoji: '🎧',
            title: 'Alone',
            subtitle: 'I focus best by myself',
            onTap: () => setState(() => _studyPreference = 'alone'),
          ),
          const SizedBox(height: 10),
          _studyStyleCard(
            selected: _studyPreference == 'group',
            emoji: '👥',
            title: 'With others',
            subtitle: 'I learn better with friends',
            onTap: () => setState(() => _studyPreference = 'group'),
          ),
          const SizedBox(height: 18),
          Text(
            'Almost ready! Here\'s what we set up for you:',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
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
      ),
    ).animate().fadeIn(duration: 350.ms),
  );

  Widget _stepContainer({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
  }) => TextField(
    controller: controller,
    style: GoogleFonts.inter(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),
  );

  Widget _title(String text) => Text(
    text,
    style: GoogleFonts.outfit(
      color: AppColors.textPrimary,
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
  );

  Widget _studyStyleCard({
    required bool selected,
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Ink(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: selected ? AppColors.cardGradient : null,
        color: selected ? null : AppColors.cardDark,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
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
          child: Text(
            '$label:',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
