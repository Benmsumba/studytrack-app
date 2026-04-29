import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/wrapped_card.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  static const int _totalPages = 2;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/signup');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.cyan
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomeStep(),
                  _buildPrimeTimeStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _onNext,
                      child: Text(
                        _currentPage == _totalPages - 1
                            ? "Get Started"
                            : "Next",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildWelcomeStep() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 88,
            color: AppColors.cyan,
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
              ),
          const SizedBox(height: 32),
          Text(
            'Welcome to StudyTrack',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 120.ms),
          const SizedBox(height: 12),
          Text(
            'Your personalized study companion for planning sessions, tracking progress, and levelling up with AI.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 40),
          _featureRow(Icons.timer_outlined, 'Pomodoro study sessions'),
          const SizedBox(height: 12),
          _featureRow(Icons.psychology_outlined, 'AI tutor powered by Gemini'),
          const SizedBox(height: 12),
          _featureRow(Icons.bar_chart_rounded, 'Progress analytics & weekly wrapped'),
          const SizedBox(height: 12),
          _featureRow(Icons.group_outlined, 'Collaborative study groups'),
        ],
      ),
    );

  Widget _featureRow(IconData icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);

  Widget _buildPrimeTimeStep() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'YOUR PRIME\nSTUDY TIME',
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            "We'll personalise your schedule after you sign up.",
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTimeOption('MORNING', Icons.light_mode_outlined, '8 AM – 12 PM'),
                _buildTimeOption('AFTERNOON', Icons.wb_sunny_outlined, '12 PM – 5 PM'),
                _buildTimeOption('EVENING', Icons.dark_mode_outlined, '5 PM – 9 PM'),
                _buildTimeOption('NIGHT', Icons.nights_stay_outlined, '9 PM – late'),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
          ),
        ],
      ),
    );

  Widget _buildTimeOption(String title, IconData icon, String subtitle) => WrappedCard(
      padding: 12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.cyan, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
}
