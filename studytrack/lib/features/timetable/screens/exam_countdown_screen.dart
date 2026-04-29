import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/wrapped_card.dart';

class ExamCountdownScreen extends StatefulWidget {
  const ExamCountdownScreen({super.key});

  @override
  State<ExamCountdownScreen> createState() => _ExamCountdownScreenState();
}

class _ExamCountdownScreenState extends State<ExamCountdownScreen> {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  Map<String, dynamic>? _exam;
  int _daysRemaining = 0;
  double _readiness = 0;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    final user = _service.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final exams =
          await _service.getUpcomingExams(user.id) ?? <Map<String, dynamic>>[];
      final exam = exams.isEmpty ? null : exams.first;
      final examDate = _parseDate(
        exam?['exam_date'] ?? exam?['date'] ?? exam?['scheduled_date'],
      );
      final daysRemaining = examDate == null
          ? 0
          : math.max(examDate.difference(DateTime.now()).inDays, 0);
      final readiness = examDate == null
          ? 0.0
          : (1 - (daysRemaining / 21)).clamp(0.0, 1.0).toDouble();

      if (!mounted) return;
      setState(() {
        _exam = exam;
        _daysRemaining = daysRemaining;
        _readiness = readiness;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String? _firstText(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return null;
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: SafeArea(
      child: RefreshIndicator(
        color: AppColors.warning,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: _loadExam,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exam Countdown', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Track the next exam you need to beat.',
                style: AppTextStyles.bodyMediumSecondary,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_exam == null)
                WrappedCard(
                  enableGlow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No upcoming exams yet',
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add an exam in your timetable to start a live countdown.',
                        style: AppTextStyles.bodyMediumSecondary,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.push('/study-session'),
                        child: const Text('Open Study Session'),
                      ),
                    ],
                  ),
                )
              else
                WrappedCard(
                  enableGlow: true,
                  glowColor: AppColors.warning.withValues(alpha: 0.25),
                  customBorderColors: [
                    AppColors.warning.withValues(alpha: 0.8),
                    AppColors.primary,
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _firstText(_exam, ['title', 'name']) ?? 'Upcoming exam',
                        style: AppTextStyles.headingLarge.copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_daysRemaining days remaining',
                        style: AppTextStyles.bodyLargeSecondary,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Readiness pulse',
                                  style: AppTextStyles.bodySmallSecondary,
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: _readiness,
                                    backgroundColor: AppColors.border,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.warning,
                                        ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 68,
                            height: 68,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 68,
                                  height: 68,
                                  child: CircularProgressIndicator(
                                    value: _readiness,
                                    strokeWidth: 6,
                                    backgroundColor: AppColors.border,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.warning,
                                        ),
                                  ),
                                ),
                                Text(
                                  '${(_readiness * 100).toInt()}%',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => context.push('/study-session'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Start Study Session',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                              ),
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
      ),
    ),
  );
}
