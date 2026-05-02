import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _titles = ['Timetable', 'Modules', 'Progress', 'Group'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final showStudyNow = currentIndex == 0 || currentIndex == 1;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBottom = bottomInset + AppSpacing.md;
    final shellBottomPadding = showStudyNow ? navBottom + 104 : navBottom + 84;
    final headerActions = currentIndex == 2
        ? [
            TextButton.icon(
              onPressed: () => context.push('/weekly-wrapped'),
              icon: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.cyan,
              ),
              label: const Text(
                'See Wrapped',
                style: TextStyle(color: AppColors.cyan),
              ),
            ),
          ]
        : const <Widget>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: _Header(
                  title: _titles[currentIndex],
                  onProfileTap: () => context.go('/profile'),
                  onNotificationTap: () => context.push('/notifications'),
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
          if (showStudyNow)
            Positioned(
              right: AppSpacing.screenHorizontal,
              bottom: navBottom + 80,
              child: _StudyNowFab(onTap: () => context.go('/study-session')),
            ),
          Positioned(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            bottom: navBottom,
            child: _BottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.actions,
  });

  final String title;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
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
                'StudyTrack',
                style: AppTextStyles.sectionOverline.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: AppTextStyles.headingLarge),
            ],
          ),
        ),
        ...actions,
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.cardDark,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    ),
  );
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.calendar_month_rounded, 'Timetable'),
    (Icons.menu_book_rounded, 'Modules'),
    (Icons.auto_graph_rounded, 'Progress'),
    (Icons.groups_rounded, 'Group'),
  ];

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    borderRadius: AppSpacing.cardRadius,
    blurSigma: 16,
    glowColor: AppColors.neonViolet,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_items.length, (index) {
        final selected = index == currentIndex;
        final item = _items[index];

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(index);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.1 : 1.0,
                  child: Icon(
                    item.$1,
                    color: selected ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: selected
                      ? AppTextStyles.label.copyWith(color: AppColors.primary)
                      : AppTextStyles.labelSecondary,
                  child: Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 4,
                  width: selected ? 14 : 6,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.primaryGradient : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
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

class _StudyNowFab extends StatelessWidget {
  const _StudyNowFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      onTap();
    },
    child: GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      borderRadius: AppSpacing.pillRadius,
      blurSigma: 18,
      glowColor: AppColors.neonCyan,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow_rounded, color: Colors.white),
          const SizedBox(width: 6),
          Text('Study Now', style: AppTextStyles.button),
        ],
      ),
    ),
  );
}
