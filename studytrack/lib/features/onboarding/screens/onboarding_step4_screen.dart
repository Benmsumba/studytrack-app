import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingStep4Screen extends StatefulWidget {
  const OnboardingStep4Screen({super.key});

  @override
  State<OnboardingStep4Screen> createState() => _OnboardingStep4ScreenState();
}

class _OnboardingStep4ScreenState extends State<OnboardingStep4Screen> {
  int _selectedTime = 0; // 0 = Morning

  final List<Map<String, dynamic>> _times = [
    {'label': 'MORNING', 'icon': Icons.wb_sunny_outlined, 'sub': '5am–12pm'},
    {'label': 'AFTERNOON', 'icon': Icons.wb_twilight, 'sub': '12pm–5pm'},
    {'label': 'EVENING', 'icon': Icons.nights_stay_outlined, 'sub': '5pm–9pm'},
    {'label': 'NIGHT', 'icon': Icons.dark_mode_outlined, 'sub': '9pm–late'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDots(),
              const SizedBox(height: 32),
              Text(
                'YOUR PRIME\nSTUDY TIME',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: List.generate(
                    _times.length,
                    (i) => _buildTimeCard(i),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Most productive hours: 8 AM - 12 PM',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      children: List.generate(
        6,
        (i) => Container(
          margin: const EdgeInsets.only(right: 6),
          width: i == 3 ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i <= 3 ? const Color(0xFF7C3AED) : const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(int index) {
    final time = _times[index];
    final isSelected = index == _selectedTime;

    return GestureDetector(
      onTap: () => setState(() => _selectedTime = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
              : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF06B6D4)
                : const Color(0xFF2D2D44),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              time['icon'] as IconData,
              color: isSelected
                  ? const Color(0xFF06B6D4)
                  : const Color(0xFF9CA3AF),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              time['label'] as String,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
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
            // Placeholder: Navigate to next onboarding step
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'NEXT',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
