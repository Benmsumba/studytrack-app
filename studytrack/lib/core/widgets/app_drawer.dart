import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/controllers/auth_provider.dart';
import '../constants/app_spacing.dart';
import '../theme/app_palette.dart';

/// The single drawer that exposes every secondary screen in the app.
/// Push to it from any screen so a student can reach Profile, Settings,
/// Notifications, Voice Notes, Analytics, Weekly Wrapped, Exam Countdown
/// and sign-out in one tap.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const _quickLinks = <_DrawerEntry>[
    _DrawerEntry(
      icon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/home/dashboard',
      description: 'Daily overview',
    ),
    _DrawerEntry(
      icon: Icons.calendar_month_rounded,
      label: 'Timetable',
      route: '/home/timetable',
      description: 'Classes & study sessions',
    ),
    _DrawerEntry(
      icon: Icons.menu_book_rounded,
      label: 'Modules',
      route: '/home/modules',
      description: 'Topics & ratings',
    ),
    _DrawerEntry(
      icon: Icons.auto_graph_rounded,
      label: 'Progress',
      route: '/home/progress',
      description: 'Insights & streaks',
    ),
    _DrawerEntry(
      icon: Icons.groups_rounded,
      label: 'Groups',
      route: '/home/groups',
      description: 'Study together',
    ),
  ];

  static const _toolsLinks = <_DrawerEntry>[
    _DrawerEntry(
      icon: Icons.bar_chart_rounded,
      label: 'Analytics',
      route: '/analytics',
      description: 'Detailed performance charts',
    ),
    _DrawerEntry(
      icon: Icons.celebration_rounded,
      label: 'Weekly Wrapped',
      route: '/weekly-wrapped',
      description: 'Your week in review',
    ),
    _DrawerEntry(
      icon: Icons.event_available_rounded,
      label: 'Exam Countdown',
      route: '/exam-countdown',
      description: 'Days until exams',
    ),
    _DrawerEntry(
      icon: Icons.mic_rounded,
      label: 'Voice Notes',
      route: '/voice-notes',
      description: 'Capture & transcribe',
    ),
    _DrawerEntry(
      icon: Icons.timer_rounded,
      label: 'Study Session',
      route: '/study-session',
      description: 'Pomodoro timer',
    ),
  ];

  static const _accountLinks = <_DrawerEntry>[
    _DrawerEntry(
      icon: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
      description: 'Your details',
    ),
    _DrawerEntry(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      route: '/notifications',
      description: 'Reminders & alerts',
    ),
    _DrawerEntry(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: '/settings',
      description: 'Theme, account, sync',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentUser;
    final authUser = Supabase.instance.client.auth.currentUser;
    final name = profile?.name ?? 'Student';
    final email = authUser?.email ?? 'Welcome to StudyTrack';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(name: name, email: email),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  _SectionLabel(label: 'Workspace'),
                  ..._quickLinks.map(
                    (e) => _DrawerTile(
                      entry: e,
                      onTap: () => _go(context, e.route),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionLabel(label: 'Study tools'),
                  ..._toolsLinks.map(
                    (e) => _DrawerTile(
                      entry: e,
                      onTap: () => _go(context, e.route),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionLabel(label: 'Account'),
                  ..._accountLinks.map(
                    (e) => _DrawerTile(
                      entry: e,
                      onTap: () => _go(context, e.route),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(color: palette.divider, height: 1),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: Icon(Icons.logout_rounded, color: palette.danger),
                    label: Text(
                      'Sign out',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: palette.danger,
                          ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: palette.danger.withValues(alpha: 0.4),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _go(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    if (route.startsWith('/home/')) {
      context.go(route);
    } else {
      context.push(route);
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : 'S';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.brandPrimary.withValues(alpha: palette.isDark ? 0.18 : 0.08),
            palette.brandSecondary.withValues(alpha: palette.isDark ? 0.12 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            const BorderRadius.only(bottomRight: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: palette.brandGradient,
              boxShadow: [
                BoxShadow(
                  color: palette.glowPrimary.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: palette.brandSecondary,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.entry, required this.onTap});

  final _DrawerEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: palette.brandPrimary
                      .withValues(alpha: palette.isDark ? 0.16 : 0.1),
                ),
                child: Icon(entry.icon, size: 19, color: palette.brandPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      entry.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerEntry {
  const _DrawerEntry({
    required this.icon,
    required this.label,
    required this.route,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String route;
  final String description;
}
