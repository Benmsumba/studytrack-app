import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_spacing.dart';
import '../theme/app_palette.dart';
import 'glass_card.dart';

/// Unified glass header used across the main shell and standalone screens.
/// Contains: optional menu button (drawer), brand mark, page title,
/// optional subtitle, and trailing action chips.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: GlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: compact ? AppSpacing.sm : AppSpacing.md,
        ),
        borderRadius: AppSpacing.cardRadius,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null)
              _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onBack!();
                },
              )
            else if (onMenuTap != null)
              _CircleIconButton(
                icon: Icons.menu_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onMenuTap!();
                },
              )
            else if (leadingIcon != null)
              _CircleIconButton(icon: leadingIcon!, onTap: () {}),
            if (onBack != null || onMenuTap != null || leadingIcon != null)
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.brandSecondary,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.headlineMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
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
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.borderSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: palette.textPrimary),
        ),
      ),
    );
  }
}

/// Pill-shaped action button to drop into [AppHeader.trailing].
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
      color: palette.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.borderSoft),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 19,
                color: color ?? palette.textPrimary,
              ),
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.danger.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Tooltip(message: tooltip!, child: btn),
      );
    }
    return Padding(padding: const EdgeInsets.only(left: 6), child: btn);
  }
}
