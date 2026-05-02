import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class NeonGlowContainer extends StatelessWidget {
  const NeonGlowContainer({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppSpacing.cardRadius,
    this.gradient,
    this.glowColor,
    this.glowBlur = 24,
    this.glowSpread = 1,
    this.backgroundColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? gradient;
  final Color? glowColor;
  final double glowBlur;
  final double glowSpread;
  final Color? backgroundColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final innerRadius = math.max(0.0, borderRadius - borderWidth);
    final innerBorderRadius = BorderRadius.circular(innerRadius);
    final resolvedGradient = gradient ?? AppColors.primaryGradient;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? AppColors.violetGlow).withValues(alpha: 0.45),
            blurRadius: glowBlur,
            spreadRadius: glowSpread,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: resolvedGradient,
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: ClipRRect(
            borderRadius: innerBorderRadius,
            child: Container(
              color: backgroundColor ?? AppColors.backgroundDark,
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
