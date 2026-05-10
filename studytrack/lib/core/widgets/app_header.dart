import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_spacing.dart';
import '../theme/app_palette.dart';

/// App-wide screen header.
///
/// Architectural Minimalism: lives directly on the page surface, no card
/// wrapper, no glass effect. The title is the visual anchor; the small
/// muted eyebrow above it provides context without the previous loud
/// brand-tag treatment.
class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.eyebrow = 'StudyTrack',
    this.onMenuTap,
    this.trailing = const <Widget>[],
    this.leadingIcon,
    this.onBack,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final String eyebrow;
  final VoidCallback? onMenuTap;
  final List<Widget> trailing;
  final IconData? leadingIcon;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final hasLeading = onBack != null || onMenuTap != null || leadingIcon != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        compact ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.screenHorizontal,
        compact ? AppSpacing.sm : AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null)
            _IconAffordance(
              icon: Icons.arrow_back_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                onBack!();
              },
            )
          else if (onMenuTap != null)
            _IconAffordance(
              icon: Icons.menu_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                onMenuTap!();
              },
            )
          else if (leadingIcon != null)
            _IconAffordance(icon: leadingIcon!, onTap: () {}),
          if (hasLeading) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.headlineMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// Square icon button used for back / menu in the header.
/// No background fill — the icon sits directly on the page surface.
class _IconAffordance extends StatelessWidget {
  const _IconAffordance({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: palette.textPrimary),
        ),
      ),
    );
  }
}

/// Trailing action button for the header. Flat, square, no halos.
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    required this.icon,
    required this.onTap,
    super.key,
    this.badge,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 22,
                color: color ?? palette.textPrimary,
              ),
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Tooltip(message: tooltip!, child: btn),
      );
    }
    return Padding(padding: const EdgeInsets.only(left: 4), child: btn);
  }
}
