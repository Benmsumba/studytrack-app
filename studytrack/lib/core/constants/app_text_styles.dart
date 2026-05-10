import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ============ Display Styles ============
  static final TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    height: 1.1,
    color: AppColors.textPrimary,
    letterSpacing: -1.2,
  );

  static final TextStyle displayMedium = GoogleFonts.spaceGrotesk(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.15,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
  );

  // ============ Heading Styles ============
  static final TextStyle headingLarge = GoogleFonts.spaceGrotesk(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static final TextStyle headingMedium = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static final TextStyle headingSmall = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ============ Body Styles ============
  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  // ============ Secondary Body Styles ============
  static final TextStyle bodyLargeSecondary = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textSecondary,
  );

  static final TextStyle bodyMediumSecondary = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static final TextStyle bodySmallSecondary = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // ============ Caption & Label ============
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMuted,
  );

  static final TextStyle captionSecondary = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static final TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.textGlow,
    letterSpacing: 0.2,
  );

  static final TextStyle labelSecondary = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  // ============ Button Styles ============
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textGlow,
    letterSpacing: 0.9,
  );

  static final TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textGlow,
    letterSpacing: 0.7,
  );

  // ============ Accent/Highlight Styles ============
  static final TextStyle accentLarge = GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.amberWarm,
    letterSpacing: 0.1,
  );

  static final TextStyle accentMedium = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.steelTeal,
  );

  static final TextStyle statValue = GoogleFonts.spaceGrotesk(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.05,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );

  static final TextStyle sectionOverline = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.neonCyan,
    letterSpacing: 1.2,
  );

  // ============ Muted Styles ============
  static final TextStyle bodyMuted = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textMuted,
  );

  static final TextStyle captionMuted = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textDisabled,
  );
}
