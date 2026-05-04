import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/exam_model.dart';

class UrgentExamBanner extends StatefulWidget {
  const UrgentExamBanner({required this.exam, super.key});

  final ExamModel exam;

  @override
  State<UrgentExamBanner> createState() => _UrgentExamBannerState();
}

class _UrgentExamBannerState extends State<UrgentExamBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.exam.daysUntilExam;
    final urgent = days <= 2;

    return GlassCard(
      backgroundColor: const Color(0xFF2A1218),
      borderColors: const [Color(0xFFFF6B81), Color(0xFFFF3D6E)],
      child: Row(
        children: [
          if (urgent)
            ScaleTransition(
              scale: Tween<double>(begin: 0.82, end: 1.18).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: const Icon(
                Icons.circle,
                color: Color(0xFFFF3D6E),
                size: 10,
              ),
            )
          else
            const Icon(Icons.circle, color: AppColors.accent, size: 10),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              days <= 0
                  ? 'Exam today: ${widget.exam.title}'
                  : 'Days remaining: $days • ${widget.exam.title}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push('/exams'),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}
