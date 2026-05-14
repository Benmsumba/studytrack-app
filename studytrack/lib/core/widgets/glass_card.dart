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
    this.borderWidth = 0.5,
    this.blurSigma = 30,
    this.enableGlow = false,
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
    final innerRadius = math.max(0, borderRadius - borderWidth).toDouble();
    final innerBorderRadius = BorderRadius.circular(innerRadius);
    // Single tonal hairline border — materiality comes from the subtle contrast
    // between the card surface and its border, not from glow or shadow.
    final colors =
        borderColors ?? const [AppColors.borderDark, AppColors.borderDarkSoft];

    Widget card = Container(
      margin: margin,
      // enableGlow kept as a parameter for backwards compatibility but ignored:
      // shadows are replaced by 0.5px hairline borders per Quiet Luxury spec.
      decoration: BoxDecoration(borderRadius: radius),
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
                    color: backgroundColor ?? AppColors.glassDark,
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
