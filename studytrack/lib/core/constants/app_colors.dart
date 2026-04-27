import 'package:flutter/material.dart';

class AppColors {
  // Core Backgrounds
  static const Color backgroundDark = Color(0xFF0D0D12);
  static const Color surfaceDark = Color(0xFF16161E);
  static const Color cardDark = Color(0xFF1C1C26);
  
  // Brand Colors
  static const Color primary = Color(0xFF7C4DFF); // Deep Violet
  static const Color accent = Color(0xFF00E5FF);  // Cyan
  static const Color cyan = Color(0xFF00E5FF);
  static const Color deepViolet = Color(0xFF7C4DFF);
  
  // UI Elements
  static const Color border = Color(0xFF2D2D3D);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFFF5252);
  
  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B8);
  static const Color textMuted = Color(0xFF636370);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1C26), Color(0xFF12121A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subject/Module Colors (Used for the grid and radar chart)
  static const Map<String, Color> subjectColors = {
    'pharmacology': Color(0xFFFF5252),
    'anatomy': Color(0xFF7C4DFF),
    'biochemistry': Color(0xFF00E5FF),
    'physiology': Color(0xFFFFAB40),
  };
}