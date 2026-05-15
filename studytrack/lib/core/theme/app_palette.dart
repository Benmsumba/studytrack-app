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

  /// Dark — deep navy-black (#0F0F1A) with Indigo + Emerald brand accents.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0F0F1A),
    backgroundDeep: Color(0xFF08080F),
    surface: Color(0xFF141425),
    surfaceElevated: Color(0xFF1A1A2E),
    card: Color(0xFF1A1A2E),
    cardAlt: Color(0xFF0F0F1A),
    // 80 % opacity card surface — semi-transparent so BackdropFilter shows through.
    glassFill: Color(0xCC1A1A2E),
    // 10 % white border as specified by Stitch design.
    glassBorder: Color(0x1AFFFFFF),
    border: Color(0xFF2A2A45),
    borderSoft: Color(0xFF1F1F38),
    divider: Color(0xFF1F1F38),
    inputFill: Color(0xFF12122A),
    textPrimary: Color(0xFFF0F1FF),
    textSecondary: Color(0xFFA5A8C8),
    textMuted: Color(0xFF6366A0),
    textGlow: Color(0xFFF0F1FF),
    brandPrimary: AppColors.indigoPrimary,
    brandSecondary: AppColors.emeraldAccent,
    brandTertiary: AppColors.indigoLight,
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: AppColors.indigoPrimary,
    brandGradient: LinearGradient(
      colors: [AppColors.indigoPrimary, AppColors.emeraldAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF1A1A2E), Color(0xFF141425)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: Color(0x00000000),
    glowSecondary: Color(0x00000000),
    ambientGlowPrimary: Color(0x00000000),
    ambientGlowSecondary: Color(0x00000000),
    shadow: Color(0x664F46E5),
  );

  /// Light — crisp white with Indigo + Emerald accents tuned for contrast.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF7F8FF),
    backgroundDeep: Color(0xFFEEEFF8),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF5F5FF),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFF0F0FA),
    glassFill: Color(0xF0FFFFFF),
    glassBorder: Color(0x1A4F46E5),
    border: Color(0xFFD0D0E8),
    borderSoft: Color(0xFFE0E0F0),
    divider: Color(0xFFE0E0F0),
    inputFill: Color(0xFFF0F0FA),
    textPrimary: Color(0xFF1A1730),
    textSecondary: Color(0xFF4A4875),
    textMuted: Color(0xFF7A78A0),
    textGlow: Color(0xFF1A1730),
    brandPrimary: AppColors.indigoPrimary,
    brandSecondary: AppColors.emeraldAccent,
    brandTertiary: AppColors.indigoLight,
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    info: AppColors.indigoPrimary,
    brandGradient: LinearGradient(
      colors: [AppColors.indigoPrimary, AppColors.emeraldAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF0F0FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: Color(0x00000000),
    glowSecondary: Color(0x00000000),
    ambientGlowPrimary: Color(0x00000000),
    ambientGlowSecondary: Color(0x00000000),
    shadow: Color(0x204F46E5),
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
  }) => AppPalette(
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
    ambientGlowSecondary: ambientGlowSecondary ?? this.ambientGlowSecondary,
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
      ambientGlowPrimary: Color.lerp(
        ambientGlowPrimary,
        other.ambientGlowPrimary,
        t,
      )!,
      ambientGlowSecondary: Color.lerp(
        ambientGlowSecondary,
        other.ambientGlowSecondary,
        t,
      )!,
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
