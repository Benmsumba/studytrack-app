import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/action_capsule.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  // Titles indexed by BRANCH index (6 branches total).
  // Branch 0=dashboard, 1=timetable (no nav tab), 2=modules, 3=progress, 4=groups, 5=profile
  static const _titles = ['', 'Timetable', 'Modules', 'Progress', 'Group', 'Profile'];

  // Capsules indexed by BRANCH index.
  static const _capsules = <_CapsuleSpec?>[
    null, // dashboard - no capsule
    _CapsuleSpec('Start Session', Icons.play_arrow_rounded, '/study-session'),
    _CapsuleSpec('Start Session', Icons.play_arrow_rounded, '/study-session'),
    null,
    null,
    null,
  ];

  // Maps nav bar tap index → branch index (skip timetable branch=1)
  static const _navToBranch = [0, 2, 3, 4, 5];

  // Maps branch index → nav bar selection index (-1 if not in nav)
  static int _branchToNav(int branchIndex) {
    const map = {0: 0, 2: 1, 3: 2, 4: 3, 5: 4};
    return map[branchIndex] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final currentIndex = navigationShell.currentIndex; // branch index
    final navIndex = _branchToNav(currentIndex); // nav bar selection
    final capsule = _capsules[currentIndex];
    final showCapsule = capsule != null;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBottom = bottomInset + AppSpacing.md;
    final shellBottomPadding = showCapsule ? navBottom + 116 : navBottom + 84;

    final headerActions = currentIndex == 3
        ? [
            TextButton.icon(
              onPressed: () => context.push('/weekly-wrapped'),
              icon: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.signal,
              ),
              label: const Text('See Wrapped'),
            ),
          ]
        : const <Widget>[];

    return Scaffold(
      backgroundColor: isLight ? AppColors.paperWhite : AppColors.obsidian,
      body: Stack(
        children: [
          Column(
            children: [
              if (currentIndex > 0)
                SafeArea(
                  bottom: false,
                  child: _Header(
                    title: _titles[currentIndex],
                    onProfileTap: () => context.go('/profile'),
                    onNotificationTap: () => context.push('/notifications'),
                    onSettingsTap: () => context.push('/settings'),
                    onVoiceNotesTap: () => context.push('/voice-notes'),
                    onAnalyticsTap: () => context.push('/analytics'),
                    actions: headerActions,
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
          if (showCapsule)
            Positioned(
              left: 0,
              right: 0,
              bottom: navBottom + 80,
              child: Center(
                child: ActionCapsule(
                  label: capsule.label,
                  icon: capsule.icon,
                  onPressed: () => context.go(capsule.route),
                ),
              ),
            ),
          Positioned(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            bottom: navBottom,
            child: _BottomNavBar(
              currentIndex: navIndex,
              onTap: (tapIndex) {
                final branchIndex = _navToBranch[tapIndex];
                navigationShell.goBranch(
                  branchIndex,
                  initialLocation: branchIndex == currentIndex,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CapsuleSpec {
  const _CapsuleSpec(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.onSettingsTap,
    required this.onVoiceNotesTap,
    required this.onAnalyticsTap,
    required this.actions,
  });

  final String title;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onVoiceNotesTap;
  final VoidCallback onAnalyticsTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final fg = isLight ? AppColors.inkPrimary : AppColors.parchment;
    final mutedFg = isLight ? AppColors.inkMuted : AppColors.parchmentMuted;
    final avatarBg = isLight ? AppColors.surfaceLight : AppColors.cardDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STUDYTRACK',
                  style: AppTextStyles.overline.copyWith(color: mutedFg),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: isLight
                      ? AppTextStyles.headingLargeLight
                      : AppTextStyles.headingLarge,
                ),
              ],
            ),
          ),
          ...actions,
          PopupMenuButton<String>(
            onSelected: (value) {
              Haptics.selection();
              if (value == 'voice-notes') {
                onVoiceNotesTap();
              } else if (value == 'analytics') {
                onAnalyticsTap();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'voice-notes',
                child: Row(
                  children: [
                    Icon(Icons.mic_rounded, size: 18, color: fg),
                    const SizedBox(width: 8),
                    const Text('Voice Notes'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.analytics_rounded, size: 18, color: fg),
                    const SizedBox(width: 8),
                    const Text('Analytics'),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert_rounded, color: fg),
            color: isLight ? AppColors.surfaceLight : AppColors.cardDark,
          ),
          IconButton(
            onPressed: () {
              Haptics.light();
              onSettingsTap();
            },
            icon: Icon(Icons.settings_rounded, color: fg),
          ),
          IconButton(
            onPressed: () {
              Haptics.light();
              onNotificationTap();
            },
            icon: Icon(Icons.notifications_none_rounded, color: fg),
          ),
          GestureDetector(
            onTap: () {
              Haptics.light();
              onProfileTap();
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: avatarBg,
              child: Icon(Icons.person_rounded, color: fg, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.menu_book_rounded, 'Modules'),
    (Icons.auto_graph_rounded, 'Progress'),
    (Icons.groups_rounded, 'Group'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fill = isLight ? AppColors.surfaceLight : AppColors.surfaceDark;
    final border = isLight ? AppColors.borderLight : AppColors.borderDark;
    final mutedFg = isLight ? AppColors.inkMuted : AppColors.parchmentMuted;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_items.length, (index) {
          final selected = index == currentIndex;
          final item = _items[index];

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Haptics.selection();
                onTap(index);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.08 : 1.0,
                    child: Icon(
                      item.$1,
                      color: selected ? AppColors.signal : mutedFg,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: selected
                        ? AppTextStyles.overlineSignal
                        : AppTextStyles.caption.copyWith(color: mutedFg),
                    child: Text(
                      item.$2.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Subtle ochre underline indicator — width animates on select.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 2,
                    width: selected ? 14 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.signal,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.pillRadius,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
