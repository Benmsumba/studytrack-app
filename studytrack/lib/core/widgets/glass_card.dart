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
    this.borderWidth = 1.0,
    this.blurSigma = 10,
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

    // Stitch spec: 10 % white border on the glass overlay.
    final borderColor = borderColors != null
        ? borderColors!.first
        : AppColors.glassBorderWhite;

    Widget card = Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                // Semi-transparent so the blurred content shows through.
                color: backgroundColor ?? AppColors.glassDark,
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
              padding: padding,
              child: child,
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
