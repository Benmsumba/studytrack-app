import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/exam_repository.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../update/controllers/update_provider.dart';
import '../controllers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthRepository _authRepository = getIt<AuthRepository>();
  final ProfileRepository _profileRepository = getIt<ProfileRepository>();
  final ModuleRepository _moduleRepository = getIt<ModuleRepository>();
  final ExamRepository _examRepository = getIt<ExamRepository>();
  final ExportService _exportService = ExportService();

  bool _isExporting = false;

  // ── Delete account ──────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete account',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.danger),
        ),
        content: Text(
          'This will permanently delete your account and all your data. '
          'This action cannot be undone.',
          style: AppTextStyles.bodyMediumSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await _profileRepository.deleteAccount();
    if (!context.mounted) return;

    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: ${error.message}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) => context.go('/login'),
    );
  }

  // ── Daily goal dialog ───────────────────────────────────────────────────────

  Future<void> _showDailyGoalDialog(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    var hours = settings.dailyGoalHours;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Daily Study Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$hours ${hours == 1 ? 'hour' : 'hours'} per day',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              Slider(
                value: hours.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: '$hours h',
                onChanged: (v) => setLocal(() => hours = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                settings.setDailyGoalHours(hours);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pomodoro duration dialog ────────────────────────────────────────────────

  Future<void> _showPomodoroDialog(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    var minutes = settings.pomodoroMinutes;
    const options = [15, 20, 25, 30, 45, 60, 90];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Pomodoro Duration'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final selected = opt == minutes;
              return ChoiceChip(
                label: Text('$opt min'),
                selected: selected,
                onSelected: (_) => setLocal(() => minutes = opt),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                settings.setPomodoroMinutes(minutes);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Change password ─────────────────────────────────────────────────────────

  Future<void> _showChangePasswordSheet(BuildContext context) async {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password', style: AppTextStyles.headingSmall),
                const SizedBox(height: 20),
                TextFormField(
                  controller: currentPwCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setLocal(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter current password' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPwCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setLocal(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'At least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPwCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setLocal(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (v) =>
                      v != newPwCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setLocal(() => isSaving = true);
                            try {
                              // Re-authenticate first, then update password.
                              final email = Supabase
                                  .instance.client.auth.currentUser?.email;
                              if (email == null) throw Exception('Not signed in');

                              // Sign in with current password to verify it.
                              await Supabase.instance.client.auth
                                  .signInWithPassword(
                                email: email,
                                password: currentPwCtrl.text,
                              );

                              // Now update to new password.
                              await Supabase.instance.client.auth
                                  .updateUser(
                                UserAttributes(password: newPwCtrl.text),
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                SnackbarHelper.show(
                                  context,
                                  'Password updated successfully.',
                                  type: AppSnackbarType.success,
                                );
                              }
                            } catch (e) {
                              setLocal(() => isSaving = false);
                              if (ctx.mounted) {
                                SnackbarHelper.show(
                                  ctx,
                                  e is AuthException
                                      ? e.message
                                      : 'Failed to update password.',
                                  type: AppSnackbarType.error,
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    currentPwCtrl.dispose();
    newPwCtrl.dispose();
    confirmPwCtrl.dispose();
  }

  // ── Export data ─────────────────────────────────────────────────────────────

  Future<void> _exportData(BuildContext context) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final profileResult = await _profileRepository.getCurrentProfile();
      final profile = profileResult.fold((_) => <String, dynamic>{}, (p) => p ?? <String, dynamic>{});
      final userId = (profile['id'] as String?) ?? 'unknown';

      final modulesResult = await _moduleRepository.getAllModules();
      final modules = switch (modulesResult) {
        Success(data: final data) => data.map((m) => m.toJson()).toList(),
        Failure() => <Map<String, dynamic>>[],
      };

      final examsResult = await _examRepository.getUpcomingExams();
      final exams = switch (examsResult) {
        Success(data: final data) => data.map((e) => e.toJson()).toList(),
        Failure() => <Map<String, dynamic>>[],
      };

      final file = await _exportService.createBackupJson(
        userId: userId,
        profile: profile,
        modules: modules,
        exams: exams,
      );

      await _exportService.shareFileToGoogleDrive(
        file: file,
        message:
            'StudyTrack data export. Open with any JSON viewer or save to Google Drive.',
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          'Export failed. Please try again.',
          type: AppSnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl + AppSpacing.xxl + AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Study Preferences ──────────────────────────────────────────
              const _SectionHeader(title: AppStrings.studyPreferences),
              const SizedBox(height: AppSpacing.md),
              _SettingsCard(
                title: 'Daily Study Goal',
                subtitle: '${settings.dailyGoalHours} ${settings.dailyGoalHours == 1 ? 'hour' : 'hours'} per day',
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => _showDailyGoalDialog(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsCard(
                title: 'Pomodoro Duration',
                subtitle: '${settings.pomodoroMinutes} minutes',
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => _showPomodoroDialog(context),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Notifications ──────────────────────────────────────────────
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

              // ── Appearance ─────────────────────────────────────────────────
              const _SectionHeader(title: 'Appearance'),
              const SizedBox(height: AppSpacing.md),
              _ThemeModeSelector(
                selectedMode: settings.themeMode,
                onChanged: settings.setThemeMode,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Account ────────────────────────────────────────────────────
              const _SectionHeader(title: 'Account'),
              const SizedBox(height: AppSpacing.md),
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
                onTap: () => _showChangePasswordSheet(context),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Export Data',
                subtitle: 'Download as JSON',
                trailing: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                onTap: _isExporting ? null : () => _exportData(context),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Delete Account',
                subtitle: 'Permanently remove your account and data',
                trailing: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.danger,
                ),
                onTap: () => _confirmDeleteAccount(context),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── About ──────────────────────────────────────────────────────
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

              // ── Sync Status ────────────────────────────────────────────────
              const _SectionHeader(title: 'Sync'),
              const SizedBox(height: AppSpacing.md),
              Consumer<OfflineSyncService>(
                builder: (context, sync, _) {
                  final subtitle = sync.isSyncing
                      ? 'Syncing…'
                      : (sync.lastSyncError != null
                            ? 'Error: ${sync.lastSyncError}'
                            : (sync.hasPendingChanges
                                  ? 'Pending changes: ${sync.pendingChanges}'
                                  : (sync.lastSyncedAt != null
                                        ? 'Last synced ${sync.lastSyncedAt}'
                                        : 'Up to date')));

                  return _SettingsCard(
                    title: 'Sync Status',
                    subtitle: subtitle,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sync.isSyncing)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        FilledButton(
                          onPressed: sync.isSyncing
                              ? null
                              : () async {
                                  await sync.syncPendingChanges();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        sync.lastSyncError == null
                                            ? 'Sync completed'
                                            : 'Sync encountered errors',
                                      ),
                                    ),
                                  );
                                },
                          child: const Text('Sync now'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // ── Update Check ───────────────────────────────────────────────
              const _SectionHeader(title: 'Update Check'),
              const SizedBox(height: AppSpacing.md),
              Consumer<UpdateProvider>(
                builder: (context, update, _) => Column(
                  children: [
                    _SettingsCard(
                      title: 'Check for Updates',
                      subtitle: 'Manually check for new versions',
                      trailing: FilledButton(
                        onPressed: () => update.checkForUpdate(),
                        child: const Text('Check'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsCard(
                      title: 'Update Status',
                      subtitle: update.status.toString(),
                      trailing: const SizedBox.shrink(),
                    ),
                    if (update.updateInfo != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SettingsCard(
                        title: 'Version Available',
                        subtitle:
                            'Code ${update.updateInfo!.versionCode} (v${update.updateInfo!.versionName})',
                        trailing: const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Support ────────────────────────────────────────────────────
              const _SectionHeader(title: 'Support'),
              const SizedBox(height: AppSpacing.md),
              _SettingsCard(
                title: AppStrings.supportContact,
                subtitle: 'Report a bug or ask for help',
                trailing: const Icon(Icons.support_agent_rounded),
                onTap: () async {
                  final uri = Uri.parse(AppConstants.repositoryIssuesUrl);
                  final launched = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!context.mounted || launched) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.unableToOpen)),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: AppStrings.supportRepo,
                subtitle: 'Open the project repository',
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse(AppConstants.repositoryUrl);
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

              // ── Logout ─────────────────────────────────────────────────────
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
                  child: Text(AppStrings.logout, style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

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
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1.0,
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
                Expanded(
                  child: Column(
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
                ),
                const SizedBox(width: 12),
                IconTheme(
                  data: IconThemeData(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  child: trailing,
                ),
              ],
            ),
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
            Expanded(
              child: Column(
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
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
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
                if (selection.isEmpty) return;
                onChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
