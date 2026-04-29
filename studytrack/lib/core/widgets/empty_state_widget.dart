import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class EmptyStateWidget extends StatelessWidget {

  const EmptyStateWidget({
    super.key,
    this.message,
    this.title,
    this.subtitle,
    this.icon,
    this.illustrationName,
    this.onRetry,
    this.onAction,
    this.actionLabel,
  });
  final String? message;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? illustrationName;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.neonViolet.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: AppColors.neonCyan.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (title != null) ...[
              Text(title!, style: AppTextStyles.headingMedium),
              const SizedBox(height: 12),
            ],
            Text(
              subtitle ?? message ?? 'Nothing to show right now.',
              style: AppTextStyles.bodyMediumSecondary,
              textAlign: TextAlign.center,
            ),
            if (illustrationName != null) ...[
              const SizedBox(height: 10),
              Text(illustrationName!, style: AppTextStyles.caption),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: Text('Retry', style: AppTextStyles.buttonSmall),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
}
