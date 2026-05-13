import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_palette.dart';

/// Container that previously rendered a neon-glow border. Repurposed for
/// Architectural Minimalism as a flat tonal panel with a single hairline
/// border. The class name and constructor are preserved so existing call
/// sites continue to compile without edits.
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
  // Retained for API compatibility — no longer rendered.
  final Gradient? gradient;
  final Color? glowColor;
  final double glowBlur;
  final double glowSpread;
  final Color? backgroundColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.card,
        borderRadius: radius,
        border: Border.all(color: palette.borderSoft, width: borderWidth),
      ),
      padding: padding,
      child: child,
    );
  }
}
