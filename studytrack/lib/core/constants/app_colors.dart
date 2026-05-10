import 'package:flutter/material.dart';

/// Architectural Minimalism palette. The legacy "neon" identifiers are
/// preserved as compatibility aliases so existing widgets keep compiling, but
/// they now resolve to the new industrial accent colors (steel teal + warm
/// amber). Every visible surface is sourced from this file or, preferably,
/// from `AppPalette` via `context.palette`.
class AppColors {
  // ============ Core Backgrounds (Deep Obsidian / Slate) ============
  static const Color backgroundDeep = Color(0xFF07090B);
  static const Color backgroundDark = Color(0xFF0B0E11);
  static const Color surfaceDark = Color(0xFF11151A);
  static const Color surfaceElevated = Color(0xFF161B21);
  static const Color cardDark = Color(0xFF1A1F26);
  static const Color cardDarkAlt = Color(0xFF0F1318);
  static const Color glassOverlay = Color(0xEB11151A);

  // ============ Industrial Accent Colors ============
  /// Steel teal — calm primary action color. Replaces the legacy violet.
  static const Color steelTeal = Color(0xFF4A9EBD);

  /// Warm amber — secondary accent and progress highlights. Replaces cyan.
  static const Color amberWarm = Color(0xFFE8B96A);

  /// Terracotta — tertiary accent used sparingly for alerts and emphasis.
  static const Color terracotta = Color(0xFFD97757);

  // Legacy aliases — kept so old call sites continue to build.
  // They now resolve to the new industrial palette, not the old neon values.
  static const Color neonViolet = steelTeal;
  static const Color neonCyan = amberWarm;
  static const Color primary = steelTeal;
  static const Color accent = amberWarm;
  static const Color cyan = amberWarm;
  static const Color deepViolet = steelTeal;

  // ============ Glow Colors (subdued — architectural minimalism) ============
  static const Color violetGlow = Color(0x554A9EBD);
  static const Color cyanGlow = Color(0x44E8B96A);
  static const Color violetGlowSoft = Color(0x224A9EBD);
  static const Color cyanGlowSoft = Color(0x1AE8B96A);
  static const Color borderGlow = Color(0x444A9EBD);
  static const Color borderGlowSoft = Color(0x22E8B96A);

  // ============ UI Elements ============
  static const Color border = Color(0xFF2A323D);
  static const Color borderSoft = Color(0xFF1E242C);
  static const Color borderGradientStart = steelTeal;
  static const Color borderGradientEnd = amberWarm;
  static const Color inputFill = Color(0xFF141921);
  static const Color success = Color(0xFF5FB682);
  static const Color warning = Color(0xFFE8B96A);
  static const Color danger = Color(0xFFD26E6E);
  static const Color info = steelTeal;

  // ============ Typography ============
  static const Color textPrimary = Color(0xFFF2F4F7);
  static const Color textSecondary = Color(0xFFA8B0BC);
  static const Color textMuted = Color(0xFF6B7480);
  static const Color textDisabled = Color(0xFF4A5260);
  static const Color textGlow = Color(0xFFDCE3EC);

  // ============ Gradients ============
  /// Primary brand gradient — steel teal to warm amber.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [steelTeal, amberWarm],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card gradient (soft tonal step on dark surfaces).
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1F26), Color(0xFF0F1318)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Border gradient.
  static const LinearGradient borderGradient = LinearGradient(
    colors: [steelTeal, amberWarm],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Button gradient.
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF5BAFCB), steelTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient.
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF6FC692), Color(0xFF4FA372)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning gradient.
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFEDC57A), Color(0xFFD9A655)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ Subject / Module Colors ============
  // Curated to live in the same tonal family as the rest of the system —
  // muted, never neon. Used in charts and module color picker chips.
  static const Map<String, Color> subjectColors = {
    'clinical-sciences': Color(0xFFD26E6E),
    'anatomy': Color(0xFF4A9EBD),
    'biochemistry': Color(0xFF5FB682),
    'physiology': Color(0xFFE8B96A),
    'pathology': Color(0xFFD97757),
    'microbiology': Color(0xFF6FAEB8),
    'immunology': Color(0xFF9577B5),
    'neuroscience': Color(0xFF5B8BC4),
  };

  // ============ Chart Colors ============
  static const List<Color> chartColors = [
    steelTeal,
    amberWarm,
    Color(0xFF5FB682),
    terracotta,
    Color(0xFFD26E6E),
    Color(0xFF9577B5),
  ];

  // ============ Semantic Backgrounds ============
  static const Color errorBackground = Color(0xFF1C1012);
  static const Color successBackground = Color(0xFF0F1815);
  static const Color warningBackground = Color(0xFF1C170F);
  static const Color infoBackground = Color(0xFF0F1518);
}
