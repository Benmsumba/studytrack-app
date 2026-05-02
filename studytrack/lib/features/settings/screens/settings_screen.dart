import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
              _SettingsToggle(
                title: 'Dark Mode',
                subtitle: 'Always on',
                value: settings.darkMode,
                onChanged: settings.setDarkMode,
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
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    Text('StudyTrack', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 4),
                    Text('Version 1.0.0', style: AppTextStyles.caption),
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
  Widget build(BuildContext context) => Text(title, style: AppTextStyles.label);
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
          trailing,
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 1),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.caption),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    ),
  );
}
