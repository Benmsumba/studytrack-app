import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

enum BadgeStatus { success, warning, error, info, pending }

extension BadgeStatusColor on BadgeStatus {
  Color get color => switch (this) {
    BadgeStatus.success => AppColors.success,
    BadgeStatus.warning => AppColors.warning,
    BadgeStatus.error => AppColors.danger,
    BadgeStatus.info => AppColors.accent,
    BadgeStatus.pending => AppColors.info,
  };

  String get label => switch (this) {
    BadgeStatus.success => 'Active',
    BadgeStatus.warning => 'Warning',
    BadgeStatus.error => 'Error',
    BadgeStatus.info => 'Info',
    BadgeStatus.pending => 'Pending',
  };
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.status,
    this.label,
    this.icon,
    this.size = BadgeSize.medium,
    super.key,
  });

  final BadgeStatus status;
  final String? label;
  final IconData? icon;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? status.label;
    final padding = switch (size) {
      BadgeSize.small => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      BadgeSize.medium => const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      BadgeSize.large => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    };

    final textStyle = switch (size) {
      BadgeSize.small => AppTextStyles.caption,
      BadgeSize.medium => AppTextStyles.bodySmall,
      BadgeSize.large => AppTextStyles.bodyLarge,
    };

    return Container(
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.2),
        border: Border.all(color: status.color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: status.color),
            const SizedBox(width: 4),
          ],
          Text(
            displayLabel,
            style: textStyle.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeSize { small, medium, large }
