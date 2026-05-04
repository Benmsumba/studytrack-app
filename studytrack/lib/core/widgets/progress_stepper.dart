import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class ProgressStepper extends StatelessWidget {
  const ProgressStepper({
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.height = 60,
    super.key,
  });

  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isActive = index == currentStep;

            return Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.success
                            : isActive
                            ? AppColors.neonViolet
                            : AppColors.surfaceElevated,
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.success
                              : isActive
                              ? AppColors.neonViolet
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    // Optional label
                    if (stepLabels != null && stepLabels!.length > index)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          stepLabels![index],
                          style: AppTextStyles.caption.copyWith(
                            color: isActive
                                ? AppColors.neonViolet
                                : isCompleted
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                // Connector line
                if (index < totalSteps - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Container(
                      width: 24,
                      height: 2,
                      color: isCompleted ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    ),
  );
}
