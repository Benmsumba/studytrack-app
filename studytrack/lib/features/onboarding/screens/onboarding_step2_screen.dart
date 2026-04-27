import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingStep2Screen extends StatefulWidget {
  const OnboardingStep2Screen({super.key});

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  final int _selectedCoursesCount = 0;

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
              const SizedBox(height: 28),
              Text(
                'Select Your Courses',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add the courses you\'re studying this semester',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildCourseCheckbox(
                      'Pharmacology',
                      Icons.medication_outlined,
                    ),
                    _buildCourseCheckbox(
                      'Anatomy',
                      Icons.accessibility_new_outlined,
                    ),
                    _buildCourseCheckbox(
                      'Biochemistry',
                      Icons.science_outlined,
                    ),
                    _buildCourseCheckbox(
                      'Microbiology',
                      Icons.bug_report_outlined,
                    ),
                    _buildCourseCheckbox(
                      'Pathology',
                      Icons.local_hospital_outlined,
                    ),
                    _buildCourseCheckbox('Physiology', Icons.favorite_outline),
                  ],
                ),
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
                    onPressed: _selectedCoursesCount > 0
                        ? () {
                            // TODO: Navigate to next step
                          }
                        : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: const Color(0xFF2D2D44),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.outfit(
                        color: _selectedCoursesCount > 0
                            ? Colors.white
                            : const Color(0xFF6B7280),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // TODO: Skip to next step
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) => Container(
          width: index == 1 ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == 1
                ? const Color(0xFF7C3AED)
                : const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCheckbox(String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2D2D44)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
            ),
            Checkbox(
              value: false,
              onChanged: (val) {
                setState(() {
                  // TODO: Update selected courses
                });
              },
              fillColor: WidgetStateProperty.all(const Color(0xFF7C3AED)),
              checkColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2D2D44)),
            ),
          ],
        ),
      ),
    );
  }
}
