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
    final shellBottomPadding = showStudyNow ? navBottom + 104 : navBottom + 88;
    final headerActions = currentIndex == 2
        ? [
            TextButton.icon(
              onPressed: () => context.push('/weekly-wrapped'),
              icon: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.neonCyan,
              ),
              label: const Text(
                'Wrapped',
                style: TextStyle(color: AppColors.neonCyan),
              ),
            ),
          ]
        : const <Widget>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _AmbientGlow(
              color: AppColors.neonViolet.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 220,
            left: -90,
            child: _AmbientGlow(
              color: AppColors.neonCyan.withValues(alpha: 0.12),
              size: 180,
            ),
          ),
          Column(
            children: [
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
          if (showStudyNow)
            Positioned(
              right: AppSpacing.screenHorizontal,
              bottom: navBottom + 84,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenHorizontal,
      AppSpacing.sm,
      AppSpacing.screenHorizontal,
      AppSpacing.md,
    ),
    child: GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.cardRadius,
      borderColors: const [
        AppColors.borderGradientStart,
        AppColors.borderGradientEnd,
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StudyTrack',
                  style: AppTextStyles.sectionOverline.copyWith(
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: AppTextStyles.headingLarge),
                const SizedBox(height: 4),
                Text(
                  'Focused mode, one tap from your next action.',
                  style: AppTextStyles.captionSecondary,
                ),
              ],
            ),
          ),
          ...actions,
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: onNotificationTap,
          ),
          _HeaderIconButton(icon: Icons.settings_rounded, onTap: onSettingsTap),
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
    ),
  );
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, color: Colors.white),
    style: IconButton.styleFrom(
      backgroundColor: AppColors.cardDark.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
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
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.sm,
    ),
    borderRadius: AppSpacing.cardRadius,
    blurSigma: 18,
    glowColor: AppColors.neonViolet,
    child: Row(
      children: List.generate(_items.length, (index) {
        final selected = index == currentIndex;
        final item = _items[index];

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                color: selected
                    ? AppColors.neonViolet.withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.08 : 1.0,
                    child: Icon(
                      item.$1,
                      color: selected
                          ? AppColors.neonCyan
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: selected
                        ? AppTextStyles.label.copyWith(
                            color: AppColors.textGlow,
                          )
                        : AppTextStyles.labelSecondary,
                    child: Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 3,
                    width: selected ? 18 : 6,
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.pillRadius,
                      ),
                    ),
                  ),
                ],
              ),
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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text('Study Now', style: AppTextStyles.button),
        ],
      ),
    ),
  );
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, this.size = 220});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}
