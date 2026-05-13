import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Quiet Luxury 2026 typography system.
///
/// Heading family : Instrument Sans — architectural weight, tight tracking (-0.03em).
/// Body family    : Inter Tight — legible, generous line-height (1.6).
/// Micro-copy     : Inter Tight, ALL-CAPS, expanded letter-spacing (+0.05em).
///
/// The -0.03em / +0.05em values are expressed in logical pixels:
///   tracking_px = em_value × font_size_px
class AppTextStyles {
  AppTextStyles._();

  // ── Display — Instrument Sans ─────────────────────────────────────────────

  static final TextStyle displayLarge = GoogleFonts.instrumentSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.parchment,
    letterSpacing: -1.2, // -0.03em @ 40 px
  );

  static final TextStyle displayMedium = GoogleFonts.instrumentSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.parchment,
    letterSpacing: -0.96, // -0.03em @ 32 px
  );

  // ── Headings — Instrument Sans ────────────────────────────────────────────

  static final TextStyle headingLarge = GoogleFonts.instrumentSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.parchment,
    letterSpacing: -0.84, // -0.03em @ 28 px
  );

  static final TextStyle headingMedium = GoogleFonts.instrumentSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.parchment,
    letterSpacing: -0.72, // -0.03em @ 24 px
  );

  static final TextStyle headingSmall = GoogleFonts.instrumentSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.parchment,
    letterSpacing: -0.6, // -0.03em @ 20 px
  );

  // Light-mode overrides — same metrics, ink-coloured.
  static final TextStyle headingLargeLight =
      headingLarge.copyWith(color: AppColors.inkPrimary);
  static final TextStyle headingMediumLight =
      headingMedium.copyWith(color: AppColors.inkPrimary);
  static final TextStyle headingSmallLight =
      headingSmall.copyWith(color: AppColors.inkPrimary);

  // ── Body — Inter Tight, line-height 1.6 ──────────────────────────────────

  static final TextStyle bodyLarge = GoogleFonts.interTight(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.parchment,
  );

  static final TextStyle bodyMedium = GoogleFonts.interTight(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.parchment,
  );

  static final TextStyle bodySmall = GoogleFonts.interTight(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.parchment,
  );

  // ── Secondary body ────────────────────────────────────────────────────────

  static final TextStyle bodyLargeSecondary = GoogleFonts.interTight(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.parchmentSecondary,
  );

  static final TextStyle bodyMediumSecondary = GoogleFonts.interTight(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.parchmentSecondary,
  );

  static final TextStyle bodySmallSecondary = GoogleFonts.interTight(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.parchmentSecondary,
  );

  // ── Micro-copy — ALL CAPS, expanded tracking (+0.05em) ────────────────────
  // Apply .toUpperCase() at the call site — the style does not force case.

  /// Use with Text(label.toUpperCase()). Secondary tint by default.
  static final TextStyle overline = GoogleFonts.interTight(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.parchmentSecondary,
    letterSpacing: 0.55, // +0.05em @ 11 px
  );

  /// Signal-tinted overline — active section headers, selected tab labels.
  static final TextStyle overlineSignal = GoogleFonts.interTight(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.signal,
    letterSpacing: 0.55, // +0.05em @ 11 px
  );

  // ── Labels ─────────────────────────────────────────────────────────────────

  static final TextStyle label = GoogleFonts.interTight(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.parchment,
    letterSpacing: 0.12,
  );

  static final TextStyle labelSecondary = GoogleFonts.interTight(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.parchmentSecondary,
    letterSpacing: 0.12,
  );

  // ── Captions ──────────────────────────────────────────────────────────────

  static final TextStyle caption = GoogleFonts.interTight(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.parchmentMuted,
  );

  static final TextStyle captionSecondary = GoogleFonts.interTight(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.parchmentSecondary,
  );

  static final TextStyle captionMuted = GoogleFonts.interTight(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.parchmentDisabled,
  );

  // ── Buttons ────────────────────────────────────────────────────────────────
  // Controlled weight (w600) and restrained tracking — not the aggressive
  // 0.9 px of the old neon system.

  static final TextStyle button = GoogleFonts.interTight(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.parchment,
    letterSpacing: 0.15,
  );

  static final TextStyle buttonSmall = GoogleFonts.interTight(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.parchment,
    letterSpacing: 0.13,
  );

  // ── Numerics / stats — Instrument Sans tabular feel ───────────────────────

  static final TextStyle statValue = GoogleFonts.instrumentSans(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.05,
    color: AppColors.parchment,
    letterSpacing: -0.78, // -0.03em @ 26 px
  );

  static final TextStyle statValueLarge = GoogleFonts.instrumentSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.parchment,
    letterSpacing: -1.2,
  );

  // ── Legacy aliases — keeps existing callsites compiling ───────────────────

  static final TextStyle sectionOverline = overlineSignal;

  static final TextStyle accentLarge = GoogleFonts.instrumentSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.signal,
    letterSpacing: -0.6,
  );

  static final TextStyle accentMedium = GoogleFonts.instrumentSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.signal,
    letterSpacing: -0.48,
  );

  static final TextStyle bodyMuted = GoogleFonts.interTight(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.parchmentMuted,
  );
}
