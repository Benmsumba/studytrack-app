import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingStep6Screen extends StatelessWidget {
  const OnboardingStep6Screen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildDots(),
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'You\'re All Set!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your personalized study experience is ready. Let\'s ace those exams!',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D2D44)),
                ),
                child: Column(
                  children: [
                    _buildFeature(
                      icon: Icons.calendar_month_outlined,
                      title: 'Smart Schedule',
                      subtitle: 'AI-powered timetable for optimal learning',
                    ),
                    const SizedBox(height: 12),
                    _buildFeature(
                      icon: Icons.insights_outlined,
                      title: 'Progress Tracking',
                      subtitle: 'Real-time analytics on your study habits',
                    ),
                    const SizedBox(height: 12),
                    _buildFeature(
                      icon: Icons.group_outlined,
                      title: 'Study Groups',
                      subtitle: 'Collaborate with peers in your courses',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {
                      // Placeholder: Navigate to home screen
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildDots() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) => Container(
          width: index == 5 ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == 5
                ? const Color(0xFF7C3AED)
                : const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
}
