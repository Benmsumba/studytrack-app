import 'package:flutter/material.dart';

/// Quiet Luxury 2026 colour system for StudyTrack.
///
/// Single signal accent: Deep Ochre (#977E41).
/// Used exclusively for interactive focus points — never decorative.
///
/// Materiality comes from 0.5px tonal borders, not shadows or neon glows.
class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────────────────────────────────

  /// Light mode canvas — warm off-white. Never pure #FFFFFF.
  static const Color paperWhite = Color(0xFFF9F8F6);

  /// Dark mode canvas — near-black with a faint warm undertone. Never pure #000000.
  static const Color obsidian = Color(0xFF0F0F10);

  // ── Surface materiality ────────────────────────────────────────────────────

  /// Card surface (light) — one step denser than the canvas.
  static const Color surfaceLight = Color(0xFFF3F2EF);

  /// Elevated surface (light) — dialogs, bottom sheets, floating panels.
  static const Color surfaceElevatedLight = Color(0xFFEEEDEA);

  /// Card surface (dark) — one step lighter/warmer than obsidian.
  static const Color surfaceDark = Color(0xFF161617);

  /// Elevated surface (dark) — dialogs, bottom sheets, overlays.
  static const Color surfaceElevated = Color(0xFF1D1D1F);

  // ── Hairline borders — materiality without shadow ──────────────────────────
  // Use width: 0.5 in BorderSide. Slightly lighter/darker than the background
  // is all that's needed to convey physical layering.

  static const Color borderLight = Color(0xFFE3E2DF); // on paperWhite
  static const Color borderLightSoft = Color(
    0xFFEAE9E6,
  ); // subtle dividers (light)
  static const Color borderDark = Color(0xFF2C2C2E); // on obsidian
  static const Color borderDarkSoft = Color(
    0xFF232325,
  ); // subtle dividers (dark)

  // Legacy aliases (widely used in existing widgets — kept while screens migrate)
  static const Color border = borderDark;
  static const Color borderSoft = borderDarkSoft;

  // ── Signal accent: Deep Ochre ───────────────────────────────────────────────
  // Used ONLY for: focus rings, active states, CTAs, selected indicators.
  // Never as a decorative fill or background on large surfaces.

  /// Primary interactive accent.
  static const Color signal = Color(0xFF977E41);

  /// Slightly brighter variant for dark-mode filled buttons and legibility.
  static const Color signalLight = Color(0xFFB9974D);

  /// 20 % opacity — selected tile backgrounds, chip fills.
  static const Color signalMuted = Color(0x33977E41);

  /// 10 % opacity — hover tint, very subtle pressed state.
  static const Color signalSubtle = Color(0x1A977E41);

  // Legacy aliases — migrate callsites progressively to `signal`
  static const Color primary = signal;
  static const Color accent = signal;
  static const Color neonViolet = signal;
  static const Color neonCyan = signal;
  static const Color cyan = signal;
  static const Color deepViolet = signal;
  static const Color steelTeal = Color(0xFF1C6E8C);
  static const Color amberWarm = Color(0xFFB8893E);
  static const Color terracotta = Color(0xFFB35C4A);

  // Glow aliases — zeroed out. Existing widgets that reference these will
  // simply produce invisible shadows. Remove shadow calls during screen-level
  // refactors (Phase 3 onwards).
  static const Color violetGlow = Color(0x00977E41);
  static const Color cyanGlow = Color(0x00977E41);
  static const Color violetGlowSoft = Color(0x00977E41);
  static const Color cyanGlowSoft = Color(0x00977E41);
  static const Color borderGlow = Color(0x00977E41);
  static const Color borderGlowSoft = Color(0x00977E41);
  static const Color borderGradientStart = signal;
  static const Color borderGradientEnd = signal;

  // ── Glassmorphism ──────────────────────────────────────────────────────────
  // Heavy blur (30px+) defined in GlassCard. These overlays are the fill colour
  // behind the blur — should be semi-transparent to reveal the blurred content.

  /// Frosted glass fill — light mode.
  static const Color glassLight = Color(0xD0F9F8F6);

  /// Frosted glass fill — dark mode.
  static const Color glassDark = Color(0xD00F0F10);

  // Legacy alias
  static const Color glassOverlay = glassDark;

  // ── Typography — dark mode ─────────────────────────────────────────────────

  /// Primary text on dark backgrounds — warm near-white.
  static const Color parchment = Color(0xFFEAE8E3);
  static const Color parchmentSecondary = Color(0xFF8A8882);
  static const Color parchmentMuted = Color(0xFF5A5856);
  static const Color parchmentDisabled = Color(0xFF3A3836);

  // Legacy aliases — dark mode primary
  static const Color textPrimary = parchment;
  static const Color textSecondary = parchmentSecondary;
  static const Color textMuted = parchmentMuted;
  static const Color textDisabled = parchmentDisabled;
  static const Color textGlow = parchment;

  // ── Typography — light mode ────────────────────────────────────────────────

  /// Primary text on light backgrounds — near-black with warmth.
  static const Color inkPrimary = Color(0xFF1A1917);
  static const Color inkSecondary = Color(0xFF6B6860);
  static const Color inkMuted = Color(0xFF9B9890);
  static const Color inkDisabled = Color(0xFFB8B6AF);

  // ── Semantic states — desaturated, earthy, not neon ───────────────────────
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFF9A6B1C);
  static const Color danger = Color(0xFF8B2635);
  static const Color info = Color(0xFF3A5F8A);

  static const Color errorBackground = Color(0xFF1C1014);
  static const Color successBackground = Color(0xFF0E1C14);
  static const Color warningBackground = Color(0xFF1C160D);
  static const Color infoBackground = Color(0xFF0D1420);

  // ── Inputs ────────────────────────────────────────────────────────────────
  static const Color inputFill = Color(0xFF1A1A1C);
  static const Color inputFillLight = Color(0xFFEFEEEB);

  // ── Convenience tonal aliases used in legacy widget code ──────────────────
  static const Color cardDark = surfaceDark;
  static const Color cardDarkAlt = Color(0xFF121214);
  static const Color backgroundDeep = Color(0xFF0A0A0B);
  static const Color backgroundDark = obsidian;
  static const Color surfaceObsidian = surfaceDark;

  // ── Gradients — purely tonal, no neon ─────────────────────────────────────

  /// Subtle tonal card gradient (dark) — barely perceptible surface depth.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF181819), Color(0xFF121213)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle tonal card gradient (light).
  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFF3F2EF), Color(0xFFECEBE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// CTA button fill — signal ochre with a touch of depth.
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF977E41), Color(0xFF7D6733)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy gradient aliases — redirected to neutral/tonal versions
  static const LinearGradient primaryGradient = buttonGradient;
  static const LinearGradient borderGradient = LinearGradient(
    colors: [borderDark, borderDarkSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF2D6A4F), Color(0xFF245540)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFF9A6B1C), Color(0xFF7D5615)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Subject / module accent colours — desaturated, earthy ────────────────
  static const Map<String, Color> subjectColors = {
    'clinical-sciences': Color(0xFF7A3B3B), // deep terracotta
    'anatomy': Color(0xFF4A5E6A), // slate
    'biochemistry': Color(0xFF3D5A45), // sage
    'physiology': Color(0xFF7D5E2E), // warm ochre
    'pathology': Color(0xFF5A3E5A), // plum
    'microbiology': Color(0xFF2E5050), // teal
    'immunology': Color(0xFF5A4A3A), // walnut
    'neuroscience': Color(0xFF3A4A6A), // navy
  };

  // ── Chart colours — curated earthy palette ────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF977E41), // ochre (signal)
    Color(0xFF4A5E6A), // slate
    Color(0xFF3D5A45), // sage
    Color(0xFF7A3B3B), // terracotta
    Color(0xFF5A3E5A), // plum
    Color(0xFF2E5050), // teal
  ];
}
