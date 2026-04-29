import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingStep5Screen extends StatefulWidget {
  const OnboardingStep5Screen({super.key});

  @override
  State<OnboardingStep5Screen> createState() => _OnboardingStep5ScreenState();
}

class _OnboardingStep5ScreenState extends State<OnboardingStep5Screen> {
  double _dailyTarget = 6;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDots(),
              const SizedBox(height: 28),
              Text(
                'Daily Study Target',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How many hours do you want to study daily?',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7C3AED).withValues(alpha: 0.2),
                            const Color(0xFF06B6D4).withValues(alpha: 0.2),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF2D2D44),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dailyTarget.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF7C3AED),
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'hours/day',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Slider(
                      value: _dailyTarget,
                      onChanged: (val) {
                        setState(() => _dailyTarget = val);
                      },
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: '${_dailyTarget.toStringAsFixed(1)} hrs',
                      activeColor: const Color(0xFF7C3AED),
                      inactiveColor: const Color(0xFF2D2D44),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1 hr',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '12 hrs',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Recommended: 6-8 hours daily for optimal learning',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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
                      // Placeholder: Navigate to next step
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue',
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
          width: index == 4 ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == 4
                ? const Color(0xFF7C3AED)
                : const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
}
