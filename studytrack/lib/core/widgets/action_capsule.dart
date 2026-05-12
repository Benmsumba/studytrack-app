import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/haptics.dart';

/// The Action Capsule — a centered pill at the bottom of the screen holding
/// the primary context-aware action. Replaces FloatingActionButton.
///
/// Visual treatment:
///   • Obsidian (or paperWhite-tinted) glass fill
///   • Signal-ochre hairline border (0.5 px)
///   • Signal icon + parchment label
///   • Heavy press feedback: 0.96 scale + light haptic
///
/// Position it via [Positioned] inside a [Stack], or via Scaffold's
/// `floatingActionButton` slot with `centerDocked` location.
class ActionCapsule extends StatefulWidget {
  const ActionCapsule({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
    this.minWidth = 168,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double minWidth;

  @override
  State<ActionCapsule> createState() => _ActionCapsuleState();
}

class _ActionCapsuleState extends State<ActionCapsule> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fill = isLight ? AppColors.paperWhite : AppColors.obsidian;
    final fg = isLight ? AppColors.inkPrimary : AppColors.parchment;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        Haptics.light();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              border: Border.all(color: AppColors.signal, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: AppColors.signal, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.label.toUpperCase(),
                  style: AppTextStyles.overline.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
