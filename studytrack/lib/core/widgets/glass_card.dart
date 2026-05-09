import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_spacing.dart';
import '../theme/app_palette.dart';

/// Frosted-glass surface with an optional brand-gradient hairline border
/// and soft glow. Resolves all colors from [AppPalette] so it looks crisp
/// in light mode (paper-white with subtle brand tint) and luminous in
/// dark mode (deep glass with neon edge).
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
    this.enableGlow = true,
    this.glowColor,
    this.backgroundColor,
    this.animateEntrance = false,
    this.gradientBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
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
    final isDark = palette.isDark;
    final radius = BorderRadius.circular(borderRadius);
    final innerRadius = math.max(0, borderRadius - borderWidth).toDouble();
    final innerBorderRadius = BorderRadius.circular(innerRadius);

    final defaultBorderColors = [palette.brandPrimary, palette.brandSecondary];
    final colors = borderColors ?? defaultBorderColors;

    final fill = backgroundColor ??
        (isDark ? palette.glassFill : palette.surface.withValues(alpha: 0.94));
    final solidBorder = palette.glassBorder.withValues(alpha: isDark ? 0.7 : 1);
    final blur = blurSigma ?? (isDark ? 18 : 24);

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enableGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? palette.glowPrimary).withValues(
                    alpha:
                        (glowColor ?? palette.glowPrimary).a * (isDark ? 0.55 : 0.18),
                  ),
                  blurRadius: isDark ? 32 : 28,
                  spreadRadius: isDark ? 1 : 0,
                  offset: const Offset(0, 12),
                ),
                if (isDark)
                  BoxShadow(
                    color: palette.glowSecondary.withValues(alpha: 0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  )
                else
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ]
            : null,
      ),
      child: gradientBorder
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  colors: colors
                      .map((c) => c.withValues(alpha: isDark ? 1 : 0.55))
                      .toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(borderWidth),
                child: _innerSurface(
                  innerBorderRadius,
                  fill,
                  solidBorder,
                  blur,
                  isDark,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: solidBorder),
              ),
              child: _innerSurface(
                radius,
                fill,
                solidBorder,
                blur,
                isDark,
              ),
            ),
    );

    if (animateEntrance) {
      card = card
          .animate()
          .fadeIn(duration: 240.ms, curve: Curves.easeOut)
          .moveY(begin: 14, end: 0, duration: 280.ms, curve: Curves.easeOut);
    }

    return card;
  }

  Widget _innerSurface(
    BorderRadius innerRadius,
    Color fill,
    Color borderColor,
    double blur,
    bool isDark,
  ) =>
      ClipRRect(
        borderRadius: innerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: innerRadius,
              color: fill,
              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
            ),
            padding: padding,
            child: child,
          ),
        ),
      );
}
