import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class MemberAvatarStack extends StatelessWidget {
  const MemberAvatarStack({
    required this.memberNames,
    this.memberAvatarUrls,
    this.maxVisible = 3,
    this.size = 36,
    this.onTap,
    super.key,
  });

  final List<String> memberNames;
  final List<String>? memberAvatarUrls;
  final int maxVisible;
  final double size;
  final VoidCallback? onTap;

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    final firstInitial = parts[0][0].toUpperCase();
    final lastInitial = parts.length > 1 ? parts[1][0].toUpperCase() : '';
    return firstInitial + lastInitial;
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.neonViolet,
      AppColors.neonCyan,
      AppColors.accent,
      AppColors.info,
      AppColors.success,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = memberNames.length > maxVisible
        ? maxVisible
        : memberNames.length;
    final hasMoreMembers = memberNames.length > maxVisible;
    final overlayWidth = (size * 0.5) * (displayCount - 1) + size;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: overlayWidth + AppSpacing.md,
        height: size + AppSpacing.sm,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            ...List.generate(
              displayCount,
              (index) => Positioned(
                left: index * size * 0.5,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundDark,
                      width: 2,
                    ),
                    color: _getColorForIndex(index),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(memberNames[index]),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (hasMoreMembers)
              Positioned(
                left: displayCount * size * 0.5,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundDark,
                      width: 2,
                    ),
                    color: AppColors.surfaceElevated,
                  ),
                  child: Center(
                    child: Text(
                      '+${memberNames.length - maxVisible}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
