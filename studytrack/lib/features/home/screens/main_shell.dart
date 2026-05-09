import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_scaffold.dart';

/// Main app shell. Five-tab bottom navigation, persistent drawer with all
/// secondary screens, and a unified glass header. The "Study Now" floating
/// CTA stays available on Home, Today, and Learn tabs.
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_TabConfig>[
    _TabConfig(
      label: 'Home',
      title: 'Home',
      eyebrow: 'Dashboard',
      subtitle: 'Your day, in one glance.',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _TabConfig(
      label: 'Today',
      title: 'Timetable',
      eyebrow: 'Today',
      subtitle: 'Classes, sessions and reminders.',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    _TabConfig(
      label: 'Learn',
      title: 'Modules',
      eyebrow: 'Learn',
      subtitle: 'Topics, ratings and AI tutor.',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
    ),
    _TabConfig(
      label: 'Insights',
      title: 'Progress',
      eyebrow: 'Insights',
      subtitle: 'Streaks, charts and your wrapped.',
      icon: Icons.auto_graph_outlined,
      activeIcon: Icons.auto_graph_rounded,
    ),
    _TabConfig(
      label: 'Connect',
      title: 'Groups',
      eyebrow: 'Connect',
      subtitle: 'Study together — chat & share.',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final currentIndex = navigationShell.currentIndex;
    final tab = _tabs[currentIndex];
    final showStudyFab = currentIndex == 0 || currentIndex == 1 || currentIndex == 2;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBottom = bottomInset + AppSpacing.sm;
    final shellBottomPadding = navBottom + 96 + (showStudyFab ? 12 : 0);

    final headerActions = <Widget>[
      if (currentIndex == 3)
        HeaderActionButton(
          icon: Icons.celebration_rounded,
          tooltip: 'Weekly Wrapped',
          color: palette.brandSecondary,
          onTap: () => context.push('/weekly-wrapped'),
        ),
      HeaderActionButton(
        icon: Icons.notifications_none_rounded,
        tooltip: 'Notifications',
        onTap: () => context.push('/notifications'),
      ),
    ];

    return AppScaffold(
      useDeepBackground: true,
      drawer: const AppDrawer(),
      body: Builder(
        builder: (innerContext) => Column(
          children: [
            SafeArea(
              bottom: false,
              child: AppHeader(
                eyebrow: tab.eyebrow,
                title: tab.title,
                subtitle: tab.subtitle,
                onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                trailing: headerActions,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: shellBottomPadding),
                child: navigationShell,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          AppSpacing.sm,
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            AppBottomNav(
              currentIndex: currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == currentIndex,
              ),
              items: _tabs
                  .map(
                    (t) => AppNavItem(
                      icon: t.icon,
                      activeIcon: t.activeIcon,
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
            if (showStudyFab)
              Positioned(
                top: -32,
                right: 0,
                child: _StudyNowFab(onTap: () => context.push('/study-session')),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudyNowFab extends StatelessWidget {
  const _StudyNowFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: palette.brandGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: palette.glowPrimary,
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Study Now',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabConfig {
  const _TabConfig({
    required this.label,
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String title;
  final String eyebrow;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;
}
