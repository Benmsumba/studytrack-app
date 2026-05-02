import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/exam_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/exam_model.dart';

class ExamCountdownScreen extends StatefulWidget {
  const ExamCountdownScreen({super.key});

  @override
  State<ExamCountdownScreen> createState() => _ExamCountdownScreenState();
}

class _ExamCountdownScreenState extends State<ExamCountdownScreen> {
  late final ExamRepository _examRepository;

  bool _isLoading = true;
  List<ExamModel> _exams = const [];

  @override
  void initState() {
    super.initState();
    _examRepository = getIt<ExamRepository>();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final result = await _examRepository.getUpcomingExams();
      if (!mounted) return;
      result.fold(
        (error) {
          setState(() {
            _exams = const [];
            _isLoading = false;
          });
        },
        (exams) {
          setState(() {
            _exams = exams;
            _isLoading = false;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exams = const [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Exams',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_exams.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D2D44)),
                  ),
                  child: Text(
                    'No upcoming exams yet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ..._exams.map(
                  (exam) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildExamCard(exam: exam),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Study Recommendations',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D2D44)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _exams.isEmpty
                                ? 'Add an exam to get personalized readiness tips.'
                                : 'Focus on your weakest topics to boost readiness before the next exam.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFFFDE047),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _exams.isEmpty
                                ? 'Keep a steady daily study rhythm to stay ready.'
                                : 'Maintain a steady daily study rhythm for your next exam.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFFA7F3D0),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard({required ExamModel exam}) {
    final daysLeft = exam.daysUntilExam;
    final readiness = (1 - (daysLeft / 21)).clamp(0.0, 1.0).toDouble();
    final urgency = daysLeft <= 7
        ? 'Urgent'
        : daysLeft <= 14
        ? 'Soon'
        : 'Upcoming';
    final urgencyColor = daysLeft <= 7
        ? const Color(0xFFF43F5E)
        : daysLeft <= 14
        ? const Color(0xFFF59E0B)
        : const Color(0xFF06B6D4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exam.title,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  urgency,
                  style: AppTextStyles.caption.copyWith(
                    color: urgencyColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(exam.examDate),
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time_outlined,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                exam.examTime ?? 'All day',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Days Left',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$daysLeft',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: urgencyColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Readiness',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${(readiness * 100).toInt()}%',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: readiness,
                        backgroundColor: const Color(0xFF2D2D44),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (_exams.isEmpty) return;
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7C3AED)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Start Prep',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF7C3AED),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
