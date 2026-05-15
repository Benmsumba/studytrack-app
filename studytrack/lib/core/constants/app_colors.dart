import 'package:flutter/material.dart';

/// StudyTrack colour system — Material 3, dark-mode-first, glass-morphic.
///
/// Brand: Indigo (#4F46E5) primary · Emerald (#10B981) accent.
/// Surfaces: deep navy-black (#0F0F1A) background · #1A1A2E card.
class AppColors {
  AppColors._();

  // ── Stitch brand tokens ───────────────────────────────────────────────────

  /// Primary — Indigo 600.
  static const Color indigoPrimary = Color(0xFF4F46E5);

  /// Lighter indigo for dark-mode legibility.
  static const Color indigoLight = Color(0xFF818CF8);

  /// 20 % indigo — selected tiles, chip fills.
  static const Color indigoMuted = Color(0x334F46E5);

  /// 10 % indigo — hover / pressed state.
  static const Color indigoSubtle = Color(0x1A4F46E5);

  /// Accent — Emerald 500.
  static const Color emeraldAccent = Color(0xFF10B981);

  /// Lighter emerald for dark-mode legibility.
  static const Color emeraldLight = Color(0xFF34D399);

  /// 20 % emerald.
  static const Color emeraldMuted = Color(0x3310B981);

  // ── Backgrounds ────────────────────────────────────────────────────────────

  /// Light mode canvas — warm off-white. Never pure #FFFFFF.
  static const Color paperWhite = Color(0xFFF9F8F6);

  /// Dark mode canvas — deep navy-black.
  static const Color obsidian = Color(0xFF0F0F1A);

  // ── Surface materiality ────────────────────────────────────────────────────

  /// Card surface (light) — one step denser than the canvas.
  static const Color surfaceLight = Color(0xFFF3F2EF);

  /// Elevated surface (light) — dialogs, bottom sheets, floating panels.
  static const Color surfaceElevatedLight = Color(0xFFEEEDEA);

  /// Card surface (dark) — elevated navy.
  static const Color surfaceDark = Color(0xFF141425);

  /// Elevated surface (dark) — dialogs, bottom sheets, overlays.
  static const Color surfaceElevated = Color(0xFF1A1A2E);

  // ── Hairline borders ───────────────────────────────────────────────────────

  static const Color borderLight = Color(0xFFE3E2DF);
  static const Color borderLightSoft = Color(0xFFEAE9E6);
  static const Color borderDark = Color(0xFF2A2A45);
  static const Color borderDarkSoft = Color(0xFF1F1F38);

  // Legacy aliases
  static const Color border = borderDark;
  static const Color borderSoft = borderDarkSoft;

  // ── Brand signal ──────────────────────────────────────────────────────────

  /// Primary interactive colour — Indigo.
  static const Color signal = indigoPrimary;
  static const Color signalLight = indigoLight;
  static const Color signalMuted = indigoMuted;
  static const Color signalSubtle = indigoSubtle;

  // Brand aliases
  static const Color primary = indigoPrimary;
  static const Color accent = emeraldAccent;
  static const Color neonViolet = indigoPrimary;
  static const Color neonCyan = emeraldAccent;
  static const Color cyan = emeraldAccent;
  static const Color deepViolet = indigoPrimary;
  static const Color steelTeal = Color(0xFF1C6E8C);
  static const Color amberWarm = Color(0xFFB8893E);
  static const Color terracotta = Color(0xFFB35C4A);

  // Glow aliases — transparent; no glow halos in this design system.
  static const Color violetGlow = Color(0x004F46E5);
  static const Color cyanGlow = Color(0x0010B981);
  static const Color violetGlowSoft = Color(0x004F46E5);
  static const Color cyanGlowSoft = Color(0x0010B981);
  static const Color borderGlow = Color(0x004F46E5);
  static const Color borderGlowSoft = Color(0x004F46E5);
  static const Color borderGradientStart = indigoPrimary;
  static const Color borderGradientEnd = emeraldAccent;

  // ── Glassmorphism ──────────────────────────────────────────────────────────

  /// Frosted glass fill — light mode.
  static const Color glassLight = Color(0xD0F9F8F6);

  /// Frosted glass fill — dark mode (80 % opacity card surface).
  static const Color glassDark = Color(0xCC1A1A2E);

  /// Glass border — 10 % white as specified by Stitch design.
  static const Color glassBorderWhite = Color(0x1AFFFFFF);

  // Legacy alias
  static const Color glassOverlay = glassDark;

  // ── Typography — dark mode ─────────────────────────────────────────────────

  /// Primary text on dark backgrounds — cool near-white.
  static const Color parchment = Color(0xFFF0F1FF);
  static const Color parchmentSecondary = Color(0xFFA5A8C8);
  static const Color parchmentMuted = Color(0xFF6366A0);
  static const Color parchmentDisabled = Color(0xFF3A3D60);

  // Legacy aliases — dark mode primary
  static const Color textPrimary = parchment;
  static const Color textSecondary = parchmentSecondary;
  static const Color textMuted = parchmentMuted;
  static const Color textDisabled = parchmentDisabled;
  static const Color textGlow = parchment;

  // ── Typography — light mode ────────────────────────────────────────────────

  static const Color inkPrimary = Color(0xFF1A1730);
  static const Color inkSecondary = Color(0xFF4A4875);
  static const Color inkMuted = Color(0xFF7A78A0);
  static const Color inkDisabled = Color(0xFFB0AECF);

  // ── Semantic states ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = indigoPrimary;

  static const Color errorBackground = Color(0xFF1C0A0A);
  static const Color successBackground = Color(0xFF051A12);
  static const Color warningBackground = Color(0xFF1C1005);
  static const Color infoBackground = Color(0xFF0A0A2E);

  // ── Inputs ────────────────────────────────────────────────────────────────
  static const Color inputFill = Color(0xFF12122A);
  static const Color inputFillLight = Color(0xFFEFEEF8);

  // ── Convenience tonal aliases ──────────────────────────────────────────────
  static const Color cardDark = surfaceDark;
  static const Color cardDarkAlt = Color(0xFF0F0F1A);
  static const Color backgroundDeep = Color(0xFF08080F);
  static const Color backgroundDark = obsidian;
  static const Color surfaceObsidian = surfaceDark;

  // ── Gradients ─────────────────────────────────────────────────────────────

  /// Brand gradient — indigo → emerald.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [indigoPrimary, emeraldAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card tonal gradient (dark).
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF141425)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card tonal gradient (light).
  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFF3F2EF), Color(0xFFECEBE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// CTA button fill — indigo.
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy gradient aliases
  static const LinearGradient primaryGradient = buttonGradient;
  static const LinearGradient borderGradient = LinearGradient(
    colors: [borderDark, borderDarkSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Subject / module accent colours ──────────────────────────────────────
  static const Map<String, Color> subjectColors = {
    'clinical-sciences': Color(0xFF7C3AED), // violet
    'anatomy': Color(0xFF0891B2), // cyan
    'biochemistry': Color(0xFF059669), // emerald
    'physiology': Color(0xFF4F46E5), // indigo
    'pathology': Color(0xFFDB2777), // pink
    'microbiology': Color(0xFF0284C7), // sky
    'immunology': Color(0xFF7C3AED), // purple
    'neuroscience': Color(0xFF0D9488), // teal
  };

  // ── Chart colours ─────────────────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF4F46E5), // indigo
    Color(0xFF10B981), // emerald
    Color(0xFF818CF8), // indigo-light
    Color(0xFF34D399), // emerald-light
    Color(0xFF7C3AED), // violet
    Color(0xFF0891B2), // cyan
  ];
}
