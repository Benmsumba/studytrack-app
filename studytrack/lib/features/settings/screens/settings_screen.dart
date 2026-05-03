import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../controllers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthRepository _authRepository = getIt<AuthRepository>();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl + AppSpacing.xxl,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl + AppSpacing.xxl + AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Study Preferences
              const _SectionHeader(title: 'Study Preferences'),
              const SizedBox(height: AppSpacing.md),
              const _SettingsCard(
                title: 'Daily Study Goal',
                subtitle: '5 hours per day',
                trailing: Icon(Icons.arrow_forward),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _SettingsCard(
                title: 'Pomodoro Duration',
                subtitle: '25 minutes',
                trailing: Icon(Icons.arrow_forward),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Notifications
              const _SectionHeader(title: 'Notifications'),
              const SizedBox(height: AppSpacing.md),
              _SettingsToggle(
                title: 'Daily Briefing',
                subtitle: 'Morning study reminder',
                value: settings.dailyBriefing,
                onChanged: settings.setDailyBriefing,
              ),
              const SizedBox(height: 12),
              _SettingsToggle(
                title: 'Study Session Reminders',
                subtitle: '15 minutes before session',
                value: settings.studyReminders,
                onChanged: settings.setStudyReminders,
              ),
              const SizedBox(height: 12),
              _SettingsToggle(
                title: 'Exam Countdown',
                subtitle: 'Alerts leading up to exams',
                value: settings.examAlerts,
                onChanged: settings.setExamAlerts,
              ),
              const SizedBox(height: 12),
              _SettingsToggle(
                title: 'Weekly Wrapped',
                subtitle: 'Sunday at 8 PM',
                value: settings.weeklyReport,
                onChanged: settings.setWeeklyReport,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Appearance
              const _SectionHeader(title: 'Appearance'),
              const SizedBox(height: AppSpacing.md),
              _ThemeModeSelector(
                selectedMode: settings.themeMode,
                onChanged: settings.setThemeMode,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Account
              const _SectionHeader(title: 'Account'),
              const SizedBox(height: AppSpacing.md),
              _SettingsCard(
                title: 'Edit Profile',
                subtitle: 'Update your information',
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/profile'),
              ),
              const SizedBox(height: 12),
              const _SettingsCard(
                title: 'Change Password',
                subtitle: 'Update your password',
                trailing: Icon(Icons.arrow_forward),
              ),
              const SizedBox(height: 12),
              const _SettingsCard(
                title: 'Export Data',
                subtitle: 'Download as JSON',
                trailing: Icon(Icons.download),
              ),
              const SizedBox(height: AppSpacing.xl),

              // About
              const _SectionHeader(title: 'About'),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                  border: Border.all(
                    color: isDark
                        ? AppColors.border
                        : theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text('StudyTrack', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Made with ❤️ for health sciences students',
                      style: AppTextStyles.captionMuted.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Support
              const _SectionHeader(title: 'Support'),
              const SizedBox(height: AppSpacing.md),
              _SettingsCard(
                title: 'Contact Support',
                subtitle: 'Report a bug or ask for help',
                trailing: const Icon(Icons.support_agent_rounded),
                onTap: () async {
                  final uri = Uri.parse(
                    'https://github.com/Benmsumba/studytrack-app/issues/new/choose',
                  );
                  final launched = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!context.mounted || launched) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to open support page.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'View on GitHub',
                subtitle: 'Open the project repository',
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse(
                    'https://github.com/Benmsumba/studytrack-app',
                  );
                  final launched = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!context.mounted || launched) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to open repository.')),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Logout
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _authRepository.signOut();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Logout', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Text(
      title,
      style: AppTextStyles.label.copyWith(color: color, fontSize: 13),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.border
                  : theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconTheme(
                data: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      toggled: value,
      label: title,
      hint: subtitle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.border : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final AppThemeMode selectedMode;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'App theme mode',
      hint: 'Choose system, light, or dark mode',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.border : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Mode',
              style: AppTextStyles.label.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'System default is recommended',
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AppThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.smartphone_rounded),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded),
                ),
              ],
              selected: {selectedMode},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                onChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
