import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/topic_model.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({required this.topicId, super.key});

  final String topicId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final SupabaseService _supabase = SupabaseService();
  final GeminiService _gemini = GeminiService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  TopicModel? _topic;
  List<QuizQuestion> _questions = const [];
  int _currentIndex = 0;
  int? _selectedIndex;
  int _score = 0;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _prepareQuiz();
  }

  Future<void> _prepareQuiz() async {
    setState(() {
      _isLoading = true;
      _questions = const [];
      _currentIndex = 0;
      _selectedIndex = null;
      _score = 0;
      _answered = false;
    });

    final topic = await _supabase.getTopicById(widget.topicId);

    var course = 'Health Sciences';
    final user = _supabase.getCurrentUser();
    if (user != null) {
      final profile = await _supabase.getProfile(user.id);
      final profileCourse = profile?['course']?.toString();
      if (profileCourse != null && profileCourse.trim().isNotEmpty) {
        course = profileCourse;
      }
    }

    if (topic != null) {
      final questions = await _gemini.generateQuiz(
        topicName: topic.name,
        course: course,
        notesContent: topic.notes,
      );

      if (!mounted) return;
      setState(() {
        _topic = topic;
        _questions = questions;
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _selectOption(int index) {
    if (_answered) return;

    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _score += 1;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex >= _questions.length - 1) {
      setState(() {
        _currentIndex = _questions.length;
      });
      return;
    }

    setState(() {
      _currentIndex += 1;
      _selectedIndex = null;
      _answered = false;
    });
  }

  int _suggestedRating() {
    if (_score >= 5) return 9;
    if (_score >= 4) return 7;
    if (_score >= 3) return 5;
    return 3;
  }

  Future<void> _updateRating() async {
    final topic = _topic;
    if (topic == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    await _supabase.updateTopicRating(topic.id, _suggestedRating());

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Topic rating updated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Generating quiz from your notes...',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_topic == null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(backgroundColor: AppColors.backgroundDark),
        body: Center(
          child: Text(
            'Unable to generate quiz right now.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final isFinished = _currentIndex >= _questions.length;
    if (isFinished) {
      return _ResultsView(
        score: _score,
        total: _questions.length,
        suggestedRating: _suggestedRating(),
        isSubmitting: _isSubmitting,
        onUpdateRating: _updateRating,
        onTryAgain: _prepareQuiz,
        onBack: () => Navigator.of(context).pop(),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          'Quiz',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: AppColors.primary,
              backgroundColor: AppColors.cardDark,
            ),
            const SizedBox(height: 18),
            Text(
              question.question,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(4, (index) {
              final option = question.options[index];
              final state = _optionState(question, index);
              return _OptionCard(
                label: String.fromCharCode(65 + index),
                text: option,
                state: state,
                onTap: () => _selectOption(index),
              );
            }),
            if (_answered) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  question.explanation,
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _nextQuestion,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentIndex == _questions.length - 1
                        ? 'See Results'
                        : 'Next Question',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  _OptionState _optionState(QuizQuestion question, int index) {
    if (!_answered) {
      return _selectedIndex == index
          ? _OptionState.selected
          : _OptionState.normal;
    }
    if (index == question.correctIndex) {
      return _OptionState.correct;
    }
    if (_selectedIndex == index && index != question.correctIndex) {
      return _OptionState.wrong;
    }
    return _OptionState.normal;
  }
}

enum _OptionState { normal, selected, correct, wrong }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    var bg = AppColors.cardDark;
    var border = AppColors.border;
    IconData? trailing;

    switch (state) {
      case _OptionState.selected:
        bg = AppColors.primary.withValues(alpha: 0.2);
        border = AppColors.primary;
        break;
      case _OptionState.correct:
        bg = AppColors.success.withValues(alpha: 0.2);
        border = AppColors.success;
        trailing = Icons.check_circle_rounded;
        break;
      case _OptionState.wrong:
        bg = AppColors.danger.withValues(alpha: 0.2);
        border = AppColors.danger;
        trailing = Icons.cancel_rounded;
        break;
      case _OptionState.normal:
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: GoogleFonts.inter(color: Colors.white)),
            ),
            if (trailing != null) Icon(trailing, color: border),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.score,
    required this.total,
    required this.suggestedRating,
    required this.isSubmitting,
    required this.onUpdateRating,
    required this.onTryAgain,
    required this.onBack,
  });

  final int score;
  final int total;
  final int suggestedRating;
  final bool isSubmitting;
  final VoidCallback onUpdateRating;
  final VoidCallback onTryAgain;
  final VoidCallback onBack;

  String _message() {
    if (score == 5) return "Perfect! You've mastered this 🏆";
    if (score == 4) return 'Excellent work! Almost there ⭐';
    if (score == 3) return 'Good effort! A bit more practice 📚';
    return "Keep studying — you'll get there 💪";
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    appBar: AppBar(backgroundColor: AppColors.backgroundDark),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score/$total',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _message(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We suggest rating this $suggestedRating/10',
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: isSubmitting ? 'Updating...' : 'Update My Rating',
            onTap: onUpdateRating,
          ),
          const SizedBox(height: 10),
          _SecondaryButton(label: 'Try Again', onTap: onTryAgain),
          const SizedBox(height: 10),
          _SecondaryButton(label: 'Back to Topic', onTap: onBack),
        ],
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(color: AppColors.textSecondary),
    ),
  );
}
