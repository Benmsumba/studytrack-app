import 'package:flutter/services.dart';

/// Centralised haptic vocabulary for the Quiet Luxury design system.
///
/// Every interaction should feel deliberate. Use the lightest impact that
/// still feels responsive — heavy impacts are reserved for moments of
/// consequence (commit, success, error).
class Haptics {
  Haptics._();

  /// Default for every primary button press (CTAs, capsules, list tile taps).
  /// Subtle thump — felt, not heard.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Slightly firmer — toggles, swipe-to-action commits, modal dismissals.
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Strong — successful save, destructive confirmation, milestone reached.
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Discrete tick — tab/segment switches, day selectors, dropdown items.
  static Future<void> selection() => HapticFeedback.selectionClick();
}
