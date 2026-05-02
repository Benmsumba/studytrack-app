import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
    this.borderRadius = AppSpacing.cardRadius,
    this.borderColors,
    this.borderWidth = 1,
    this.blurSigma = 18,
    this.enableGlow = true,
    this.glowColor,
    this.backgroundColor,
    this.animateEntrance = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final List<Color>? borderColors;
  final double borderWidth;
  final double blurSigma;
  final bool enableGlow;
  final Color? glowColor;
  final Color? backgroundColor;
  final bool animateEntrance;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final innerRadius = math.max(0, borderRadius - borderWidth);
    final innerBorderRadius = BorderRadius.circular(innerRadius);
    final colors =
        borderColors ?? const [AppColors.neonViolet, AppColors.neonCyan];

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enableGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? AppColors.violetGlowSoft).withValues(
                    alpha: 0.7,
                  ),
                  blurRadius: 32,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
                const BoxShadow(
                  color: AppColors.cyanGlowSoft,
                  blurRadius: 22,
                  spreadRadius: 0,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: ClipRRect(
            borderRadius: innerBorderRadius,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: innerBorderRadius,
                    color: backgroundColor ?? AppColors.glassOverlay,
                    border: Border.all(
                      color: AppColors.borderSoft.withValues(alpha: 0.72),
                    ),
                  ),
                  padding: padding,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (animateEntrance) {
      card = card
          .animate()
          .fadeIn(duration: 220.ms, curve: Curves.easeOut)
          .moveY(begin: 12, end: 0, duration: 260.ms, curve: Curves.easeOut);
    }

    return card;
  }
}
