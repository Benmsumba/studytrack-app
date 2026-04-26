import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseService _service = SupabaseService();

  bool _darkMode = true;
  bool _dailyBriefing = true;
  bool _studyReminders = true;
  bool _examAlerts = true;
  bool _weeklyReport = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Study Preferences
              _SectionHeader(title: 'Study Preferences'),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Daily Study Goal',
                subtitle: '5 hours per day',
                trailing: const Icon(Icons.arrow_forward),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Pomodoro Duration',
                subtitle: '25 minutes',
                trailing: const Icon(Icons.arrow_forward),
              ),
              const SizedBox(height: 32),

              // Notifications
              _SectionHeader(title: 'Notifications'),
              const SizedBox(height: 16),
              _SettingsToggle(
                title: 'Daily Briefing',
                subtitle: 'Morning study reminder',
                value: _dailyBriefing,
                onChanged: (value) => setState(() => _dailyBriefing = value),
              ),
              const SizedBox(height: 12),
              _SettingsToggle(
                title: 'Study Session Reminders',
                subtitle: '15 minutes before session',
                value: _studyReminders,
                onChanged: (value) => setState(() => _studyReminders = value),
              ),
              const SizedBox(height: 12),
              _SettingsToggle(
                title: 'Exam Countdown',
                subtitle: 'Alerts leading up to exams',
                value: _examAlerts,
                onChanged: (value) => setState(() => _examAlerts = value),
              ),
              const SizedBox(height: 12),
              _SettingsToggle(
                title: 'Weekly Wrapped',
                subtitle: 'Sunday at 8 PM',
                value: _weeklyReport,
                onChanged: (value) => setState(() => _weeklyReport = value),
              ),
              const SizedBox(height: 32),

              // Appearance
              _SectionHeader(title: 'Appearance'),
              const SizedBox(height: 16),
              _SettingsToggle(
                title: 'Dark Mode',
                subtitle: 'Always on',
                value: _darkMode,
                onChanged: (value) => setState(() => _darkMode = value),
              ),
              const SizedBox(height: 32),

              // Account
              _SectionHeader(title: 'Account'),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Edit Profile',
                subtitle: 'Update your information',
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/profile'),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Change Password',
                subtitle: 'Update your password',
                trailing: const Icon(Icons.arrow_forward),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Export Data',
                subtitle: 'Download as JSON',
                trailing: const Icon(Icons.download),
              ),
              const SizedBox(height: 32),

              // About
              _SectionHeader(title: 'About'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'StudyTrack',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Made with ❤️ for health sciences students',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
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
                    await _service.signOut();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
    );
  }
}
