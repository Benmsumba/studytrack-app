import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    required this.isUserMessage,
    this.timestamp,
    this.showTimestamp = true,
    super.key,
  });

  final String message;
  final bool isUserMessage;
  final DateTime? timestamp;
  final bool showTimestamp;

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: isUserMessage
          ? AppSpacing.screenHorizontal + 48
          : AppSpacing.screenHorizontal,
      right: isUserMessage
          ? AppSpacing.screenHorizontal
          : AppSpacing.screenHorizontal + 48,
      bottom: AppSpacing.sm,
    ),
    child: Column(
      crossAxisAlignment: isUserMessage
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showTimestamp) ...[
          Text(
            _formatTime(timestamp),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          decoration: BoxDecoration(
            gradient: isUserMessage
                ? null
                : LinearGradient(
                    colors: [
                      AppColors.neonViolet.withValues(alpha: 0.3),
                      AppColors.neonCyan.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isUserMessage ? AppColors.neonViolet : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUserMessage ? 16 : 4),
              bottomRight: Radius.circular(isUserMessage ? 4 : 16),
            ),
            border: !isUserMessage
                ? Border.all(color: AppColors.border, width: 1)
                : null,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: isUserMessage ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
