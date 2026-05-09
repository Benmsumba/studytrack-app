import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_spacing.dart';
import '../theme/app_palette.dart';
import 'app_scaffold.dart';

/// Standard scaffold for full-page pushes (Profile, Settings, Notifications,
/// Analytics, Voice Notes, Weekly Wrapped, Exam Countdown). Adds a themed
/// translucent app bar with title, optional subtitle and back button.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.ambientGlow = true,
    this.useDeepBackground = false,
    this.padBody = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool ambientGlow;
  final bool useDeepBackground;

  /// When true (default), wraps body in horizontal screen padding.
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return AppScaffold(
      ambientGlow: ambientGlow,
      useDeepBackground: useDeepBackground,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(subtitle == null ? 60 : 76),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PageBarIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/home/dashboard');
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
      body: padBody
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: body,
            )
          : body,
    );
  }
}

class _PageBarIconButton extends StatelessWidget {
  const _PageBarIconButton({required this.icon, required this.onTap});

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
          width: 44,
          height: 44,
          child: Icon(icon, color: palette.textPrimary, size: 20),
        ),
      ),
    );
  }
}
