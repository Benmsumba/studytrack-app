import 'package:flutter/material.dart';

class AppColors {
  // ============ Core Backgrounds ============
  static const Color backgroundDark = Color(0xFF0D0D12);
  static const Color surfaceDark = Color(0xFF16161E);
  static const Color cardDark = Color(0xFF1C1C26);
  static const Color cardDarkAlt = Color(0xFF14131F);

  // ============ Premium Brand Colors (Neon) ============
  /// Exact neon violet from design spec
  static const Color neonViolet = Color(0xFF7C3AED);

  /// Exact cyan from design spec
  static const Color neonCyan = Color(0xFF06B6D4);

  // Legacy aliases for compatibility
  static const Color primary = neonViolet;
  static const Color accent = neonCyan;
  static const Color cyan = neonCyan;
  static const Color deepViolet = neonViolet;

  // ============ Glow Colors (for shadow effects) ============
  static const Color violetGlow = Color(0xAA7C3AED);
  static const Color cyanGlow = Color(0xAA06B6D4);
  static const Color violetGlowSoft = Color(0x557C3AED);
  static const Color cyanGlowSoft = Color(0x5506B6D4);

  // ============ UI Elements ============
  static const Color border = Color(0xFF2D2D3D);
  static const Color borderGradientStart = Color(0xFF3A3A4D);
  static const Color borderGradientEnd = Color(0xFF2D2D3D);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFFF5252);
  static const Color info = Color(0xFF2196F3);

  // ============ Typography ============
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B8);
  static const Color textMuted = Color(0xFF636370);
  static const Color textDisabled = Color(0xFF4A4A52);

  // ============ Gradients ============
  /// Primary neon gradient (violet to cyan)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonViolet, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card gradient (dark premium)
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1C26), Color(0xFF12121A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Border gradient (subtle neon effect)
  static const LinearGradient borderGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Button gradient (vibrant neon)
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning gradient
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFFAB1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ Subject/Module Colors (for charts and categorization) ============
  static const Map<String, Color> subjectColors = {
    'clinical-sciences': Color(0xFFFF5252),
    'anatomy': Color(0xFF7C3AED),
    'biochemistry': Color(0xFF06B6D4),
    'physiology': Color(0xFFFFAB40),
    'pathology': Color(0xFF7C3AED),
    'microbiology': Color(0xFF26C6DA),
    'immunology': Color(0xFF9C27B0),
    'neuroscience': Color(0xFF2196F3),
  };

  // ============ Chart Colors ============
  static const List<Color> chartColors = [
    Color(0xFF7C3AED), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFF00E676), // Green
    Color(0xFFFFB74D), // Orange
    Color(0xFFFF5252), // Red
    Color(0xFF9C27B0), // Purple
  ];

  // ============ Semantic Colors ============
  static const Color errorBackground = Color(0xFF1C0B0B);
  static const Color successBackground = Color(0xFF0B1C0B);
  static const Color warningBackground = Color(0xFF1C1C0B);
  static const Color infoBackground = Color(0xFF0B0B1C);
}
