import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/wrapped_card.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator (Image 3 style)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.cyan : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomeStep(),
                  _buildPrimeTimeStep(), // This matches the 1st screen in Image 2
                ],
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () {}, child: const Text("Skip", style: TextStyle(color: Colors.white54))),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease),
                      child: const Text("Next"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.handshake_outlined, size: 100, color: AppColors.cyan),
          const SizedBox(height: 32),
          Text("Welcome to StudyTrack", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text("Your personalized health sciences study companion.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildPrimeTimeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("YOUR PRIME\nSTUDY TIME", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildTimeOption("MORNING", Icons.light_mode_outlined, "8 AM - 12 PM"),
                _buildTimeOption("AFTERNOON", Icons.wb_sunny_outlined, "12 PM - 4 PM"),
                _buildTimeOption("EVENING", Icons.dark_mode_outlined, "4 PM - 8 PM"),
                _buildTimeOption("NIGHT", Icons.nights_stay_outlined, "8 PM - 12 AM"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String title, IconData icon, String subtitle) {
    return WrappedCard(
      padding: 12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.cyan),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}