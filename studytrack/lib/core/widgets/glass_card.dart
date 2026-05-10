import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_spacing.dart';
import '../theme/app_palette.dart';

/// Flat tonal card — Architectural Minimalism.
///
/// The class name and constructor are preserved from the previous
/// glassmorphism implementation so existing call sites continue to compile,
/// but rendering is now:
///   • a single solid surface color from the palette
///   • a single hairline divider when needed (no gradient borders)
///   • no BackdropFilter blur, no glow shadows
///
/// Elevation is communicated through the tonal step between the page
/// background and the card surface, not through borders or shadows.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
    this.borderRadius = AppSpacing.cardRadius,
    this.borderColors,
    this.borderWidth = 1,
    this.blurSigma,
    this.enableGlow = false,
    this.glowColor,
    this.backgroundColor,
    this.animateEntrance = false,
    this.gradientBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  // Retained for API compatibility — no longer used for rendering.
  final List<Color>? borderColors;
  final double borderWidth;
  final double? blurSigma;
  final bool enableGlow;
  final Color? glowColor;
  final Color? backgroundColor;
  final bool animateEntrance;
  final bool gradientBorder;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(borderRadius);

    // Choose a tonal step that reads as raised against the page background.
    // Light mode: pure white card on near-white background — needs the soft
    // border to remain visible. Dark mode: card is two tonal steps above
    // background — the step itself signals elevation, no border required.
    final fill = backgroundColor ?? palette.card;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: palette.isDark
            ? null
            : Border.all(color: palette.borderSoft, width: 1),
      ),
      padding: padding,
      child: child,
    );

    if (animateEntrance) {
      card = card
          .animate()
          .fadeIn(duration: 240.ms, curve: Curves.easeOut)
          .moveY(begin: 14, end: 0, duration: 280.ms, curve: Curves.easeOut);
    }

    return card;
  }
}
