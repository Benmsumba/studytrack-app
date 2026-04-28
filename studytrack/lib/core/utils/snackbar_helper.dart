import 'package:flutter/material.dart';

enum AppSnackbarType { success, error, warning, info }

class SnackbarHelper {
  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.info,
  }) {
    final style = _style(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: style.$1,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static (Color, IconData) _style(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return (const Color(0xFF10B981), Icons.check_circle_outline_rounded);
      case AppSnackbarType.error:
        return (const Color(0xFFF43F5E), Icons.error_outline_rounded);
      case AppSnackbarType.warning:
        return (const Color(0xFFF59E0B), Icons.warning_amber_rounded);
      case AppSnackbarType.info:
        return (const Color(0xFF06B6D4), Icons.info_outline_rounded);
    }
  }
}
