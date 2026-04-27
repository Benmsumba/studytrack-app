import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _selectedOption = 1; // B is selected
  final int _currentQuestion = 2;
  final int _totalQuestions = 5;

  final List<String> _options = [
    'Absorption half-life',
    'Total Body Clearance',
    'Area Under the Curve (AUC)',
    'Apparent Volume of Distribution',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildProgress(),
              const SizedBox(height: 28),
              _buildQuestion(),
              const SizedBox(height: 24),
              _buildOptions(),
              const Spacer(),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF9CA3AF),
            size: 18,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Topic Quiz',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Pharmacokinetics',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final progress = _currentQuestion / _totalQuestions;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $_currentQuestion of $_totalQuestions',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.outfit(
                color: const Color(0xFF10B981),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF2D2D44),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Text(
      'Which parameter represents the rate of elimination of a drug?',
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.35,
      ),
    );
  }

  Widget _buildOptions() {
    final letters = ['A', 'B', 'C', 'D'];
    return Column(
      children: List.generate(_options.length, (i) {
        final isSelected = i == _selectedOption;
        return GestureDetector(
          onTap: () => setState(() => _selectedOption = i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                  : const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF2D2D44),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${letters[i]}. ',
                  style: GoogleFonts.outfit(
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(
                    _options[i],
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'NEXT QUESTION',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
