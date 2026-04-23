import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const primary = Color(0xFF7C3AED);
  static const accent = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFF43F5E);

  // Surface colors
  static const backgroundDark = Color(0xFF0F0F1A);
  static const surfaceDark = Color(0xFF1A1A2E);
  static const cardDark = Color(0xFF16213E);

  // Typography and borders
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const border = Color(0xFF2D2D44);

  // Aliases for readability in different contexts
  static const deepViolet = primary;
  static const cyan = accent;
  static const emerald = success;
  static const amber = warning;
  static const rose = danger;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1D1D33),
      cardDark,
    ],
  );

  // Subject colors for chips, charts, and module tagging
  static const Map<String, Color> subjectColors = {
    'Pharmacology': Color(0xFF7C3AED),
    'Anatomy': Color(0xFFEF4444),
    'Physiology': Color(0xFFF59E0B),
    'Biochemistry': Color(0xFF10B981),
    'Pathology': Color(0xFF3B82F6),
    'Surgery': Color(0xFFEC4899),
    'Microbiology': Color(0xFF8B5CF6),
    'Medicine': Color(0xFF06B6D4),
    'Paediatrics': Color(0xFFF97316),
    'Default': Color(0xFF6B7280),
  };
}
