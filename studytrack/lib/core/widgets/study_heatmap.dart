import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class StudyHeatmap extends StatelessWidget {
  const StudyHeatmap({
    required this.data,
    required this.weeks,
    this.height = 120,
    super.key,
  });

  /// Map of dates (YYYY-MM-DD) to intensity (0-4)
  final Map<String, int> data;
  final int weeks;
  final double height;

  Color _getColorForIntensity(int intensity) => switch (intensity) {
    0 => AppColors.surfaceElevated,
    1 => AppColors.success.withValues(alpha: 0.3),
    2 => AppColors.success.withValues(alpha: 0.6),
    3 => AppColors.success.withValues(alpha: 0.85),
    4 => AppColors.success,
    _ => AppColors.surfaceElevated,
  };

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = DateTime.now();
    final startDate = today.subtract(
      Duration(days: today.weekday + (weeks - 1) * 7),
    );

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Text(
              'Study Activity ($weeks weeks)',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      7,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: SizedBox(
                          width: 16,
                          child: Text(
                            dayLabels[index],
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(weeks * 7, (index) {
                      final date = startDate.add(Duration(days: index));
                      final dateStr =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final intensity = data[dateStr] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: '$dateStr - Activity: $intensity',
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getColorForIntensity(intensity),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
