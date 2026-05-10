import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Theme-aware color palette resolved through `Theme.of(context).extension<AppPalette>()`
/// or the `context.palette` extension. The values implement an
/// "Architectural Minimalism" system: neutral obsidian / slate surfaces with
/// industrial accent colors. Every screen surface, gradient, and accent
/// resolves through this palette so light and dark modes render correctly
/// without per-screen branching.
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

  // Glows / ambient (kept for legacy widgets; values are now subdued)
  final Color glowPrimary;
  final Color glowSecondary;
  final Color ambientGlowPrimary;
  final Color ambientGlowSecondary;
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  /// Dark — Deep Obsidian + Slate with Industrial Steel accents.
  /// Tonal stepping (background → backgroundDeep → surface → surfaceElevated
  /// → card) communicates elevation without shadows or borders.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0B0E11),
    backgroundDeep: Color(0xFF07090B),
    surface: Color(0xFF11151A),
    surfaceElevated: Color(0xFF161B21),
    card: Color(0xFF1A1F26),
    cardAlt: Color(0xFF0F1318),
    glassFill: Color(0xEB11151A),
    glassBorder: Color(0xFF232A33),
    border: Color(0xFF2A323D),
    borderSoft: Color(0xFF1E242C),
    divider: Color(0xFF1E242C),
    inputFill: Color(0xFF141921),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFA8B0BC),
    textMuted: Color(0xFF6B7480),
    textGlow: Color(0xFFDCE3EC),
    brandPrimary: AppColors.steelTeal,
    brandSecondary: AppColors.amberWarm,
    brandTertiary: AppColors.terracotta,
    success: Color(0xFF5FB682),
    warning: Color(0xFFE8B96A),
    danger: Color(0xFFD26E6E),
    info: AppColors.steelTeal,
    brandGradient: LinearGradient(
      colors: [AppColors.steelTeal, AppColors.amberWarm],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF1A1F26), Color(0xFF0F1318)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: Color(0x554A9EBD),
    glowSecondary: Color(0x44E8B96A),
    ambientGlowPrimary: Color(0x224A9EBD),
    ambientGlowSecondary: Color(0x1AE8B96A),
    shadow: Color(0x80000000),
  );

  /// Light — Paper white with deeper steel + amber accents tuned for contrast.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF7F8FA),
    backgroundDeep: Color(0xFFEEF0F3),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFAFBFC),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFF1F3F6),
    glassFill: Color(0xF5FFFFFF),
    glassBorder: Color(0xFFE0E4EA),
    border: Color(0xFFDCE0E6),
    borderSoft: Color(0xFFE8EAEF),
    divider: Color(0xFFE8EAEF),
    inputFill: Color(0xFFF1F3F6),
    textPrimary: Color(0xFF0E1218),
    textSecondary: Color(0xFF4A5260),
    textMuted: Color(0xFF7A8290),
    textGlow: Color(0xFF1A2030),
    brandPrimary: Color(0xFF1C6E8C),
    brandSecondary: Color(0xFFB8893E),
    brandTertiary: Color(0xFFB85A3F),
    success: Color(0xFF2F8F5A),
    warning: Color(0xFFB8893E),
    danger: Color(0xFFB84747),
    info: Color(0xFF1C6E8C),
    brandGradient: LinearGradient(
      colors: [Color(0xFF1C6E8C), Color(0xFFB8893E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF1F3F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: Color(0x331C6E8C),
    glowSecondary: Color(0x33B8893E),
    ambientGlowPrimary: Color(0x141C6E8C),
    ambientGlowSecondary: Color(0x14B8893E),
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
  /// Theme-aware palette. Falls back to dark so any code that runs before the
  /// theme is fully wired never crashes.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
