import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Theme-aware color palette. Resolved from `Theme.of(context).extension<AppPalette>()`
/// or the `context.palette` extension. Every screen surface, gradient, and
/// glow color should come through here so light and dark modes render
/// flawlessly without per-screen branching.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.cardAlt,
    required this.glassFill,
    required this.glassBorder,
    required this.border,
    required this.borderSoft,
    required this.divider,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textGlow,
    required this.brandPrimary,
    required this.brandSecondary,
    required this.brandTertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.brandGradient,
    required this.cardGradient,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.ambientGlowPrimary,
    required this.ambientGlowSecondary,
    required this.shadow,
  });

  final Brightness brightness;

  // Surfaces
  final Color background;
  final Color backgroundDeep;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color cardAlt;
  final Color glassFill;
  final Color glassBorder;
  final Color border;
  final Color borderSoft;
  final Color divider;
  final Color inputFill;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textGlow;

  // Brand
  final Color brandPrimary;
  final Color brandSecondary;
  final Color brandTertiary;

  // Semantic
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // Gradients
  final LinearGradient brandGradient;
  final LinearGradient cardGradient;

  // Glows / ambient
  final Color glowPrimary;
  final Color glowSecondary;
  final Color ambientGlowPrimary;
  final Color ambientGlowSecondary;
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  /// Dark palette — premium neon on near-black.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0A0A0F),
    backgroundDeep: Color(0xFF050509),
    surface: Color(0xFF12121A),
    surfaceElevated: Color(0xFF171722),
    card: Color(0xFF1A1A25),
    cardAlt: Color(0xFF101018),
    glassFill: Color(0xCC0F0F16),
    glassBorder: Color(0xB31F1F2B),
    border: Color(0xFF262637),
    borderSoft: Color(0xFF1F1F2B),
    divider: Color(0xFF1F1F2B),
    inputFill: Color(0xFF14141D),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B8),
    textMuted: Color(0xFF636370),
    textGlow: Color(0xFFEDE9FF),
    brandPrimary: AppColors.neonViolet,
    brandSecondary: AppColors.neonCyan,
    brandTertiary: Color(0xFFEC4899),
    success: Color(0xFF00E676),
    warning: Color(0xFFFFB74D),
    danger: Color(0xFFFF5252),
    info: Color(0xFF2196F3),
    brandGradient: LinearGradient(
      colors: [AppColors.neonViolet, AppColors.neonCyan],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF1A1A25), Color(0xFF101018)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: Color(0xAA7C3AED),
    glowSecondary: Color(0xAA06B6D4),
    ambientGlowPrimary: Color(0x447C3AED),
    ambientGlowSecondary: Color(0x3306B6D4),
    shadow: Color(0x66000000),
  );

  /// Light palette — calm paper-white with vibrant brand accents.
  /// Designed to feel just as engaging as the dark mode but easier on
  /// the eyes for daytime / library use.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF6F7FB),
    backgroundDeep: Color(0xFFEEF0F7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF9FAFD),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFF4F5FB),
    glassFill: Color(0xF2FFFFFF),
    glassBorder: Color(0xFFE2E5EF),
    border: Color(0xFFDFE3EE),
    borderSoft: Color(0xFFE9ECF4),
    divider: Color(0xFFE9ECF4),
    inputFill: Color(0xFFF1F3F9),
    textPrimary: Color(0xFF0D1226),
    textSecondary: Color(0xFF4B5168),
    textMuted: Color(0xFF7E8499),
    textGlow: Color(0xFF2C2750),
    brandPrimary: Color(0xFF7C3AED),
    brandSecondary: Color(0xFF0891B2),
    brandTertiary: Color(0xFFDB2777),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    brandGradient: LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFF0891B2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF4F5FB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: Color(0x447C3AED),
    glowSecondary: Color(0x440891B2),
    ambientGlowPrimary: Color(0x227C3AED),
    ambientGlowSecondary: Color(0x220891B2),
    shadow: Color(0x14101A33),
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? backgroundDeep,
    Color? surface,
    Color? surfaceElevated,
    Color? card,
    Color? cardAlt,
    Color? glassFill,
    Color? glassBorder,
    Color? border,
    Color? borderSoft,
    Color? divider,
    Color? inputFill,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textGlow,
    Color? brandPrimary,
    Color? brandSecondary,
    Color? brandTertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    LinearGradient? brandGradient,
    LinearGradient? cardGradient,
    Color? glowPrimary,
    Color? glowSecondary,
    Color? ambientGlowPrimary,
    Color? ambientGlowSecondary,
    Color? shadow,
  }) =>
      AppPalette(
        brightness: brightness ?? this.brightness,
        background: background ?? this.background,
        backgroundDeep: backgroundDeep ?? this.backgroundDeep,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        card: card ?? this.card,
        cardAlt: cardAlt ?? this.cardAlt,
        glassFill: glassFill ?? this.glassFill,
        glassBorder: glassBorder ?? this.glassBorder,
        border: border ?? this.border,
        borderSoft: borderSoft ?? this.borderSoft,
        divider: divider ?? this.divider,
        inputFill: inputFill ?? this.inputFill,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        textGlow: textGlow ?? this.textGlow,
        brandPrimary: brandPrimary ?? this.brandPrimary,
        brandSecondary: brandSecondary ?? this.brandSecondary,
        brandTertiary: brandTertiary ?? this.brandTertiary,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        info: info ?? this.info,
        brandGradient: brandGradient ?? this.brandGradient,
        cardGradient: cardGradient ?? this.cardGradient,
        glowPrimary: glowPrimary ?? this.glowPrimary,
        glowSecondary: glowSecondary ?? this.glowSecondary,
        ambientGlowPrimary: ambientGlowPrimary ?? this.ambientGlowPrimary,
        ambientGlowSecondary:
            ambientGlowSecondary ?? this.ambientGlowSecondary,
        shadow: shadow ?? this.shadow,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      backgroundDeep: Color.lerp(backgroundDeep, other.backgroundDeep, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardAlt: Color.lerp(cardAlt, other.cardAlt, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textGlow: Color.lerp(textGlow, other.textGlow, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      brandTertiary: Color.lerp(brandTertiary, other.brandTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      brandGradient: t < 0.5 ? brandGradient : other.brandGradient,
      cardGradient: t < 0.5 ? cardGradient : other.cardGradient,
      glowPrimary: Color.lerp(glowPrimary, other.glowPrimary, t)!,
      glowSecondary: Color.lerp(glowSecondary, other.glowSecondary, t)!,
      ambientGlowPrimary:
          Color.lerp(ambientGlowPrimary, other.ambientGlowPrimary, t)!,
      ambientGlowSecondary:
          Color.lerp(ambientGlowSecondary, other.ambientGlowSecondary, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Theme-aware palette. Falls back to the dark palette so legacy code
  /// that runs before the theme is fully wired never crashes.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
