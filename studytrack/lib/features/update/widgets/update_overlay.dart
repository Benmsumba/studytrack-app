import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/update_provider.dart';

class UpdateOverlay extends StatelessWidget {
  const UpdateOverlay({super.key});

  @override
  Widget build(BuildContext context) => Consumer<UpdateProvider>(
    builder: (context, update, _) {
      if (!update.shouldShowOverlay) {
        return const SizedBox.shrink();
      }
      return const _UpdateSheet();
    },
  );
}

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withAlpha(180),
    child: const SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _UpdateCard(),
        ),
      ),
    ),
  );
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard();

  @override
  Widget build(BuildContext context) {
    final update = context.watch<UpdateProvider>();
    final info = update.updateInfo;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.violetGlow,
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UpdateIcon(status: update.status),
            const SizedBox(height: 20),
            _UpdateTitle(status: update.status),
            const SizedBox(height: 8),
            if (info != null) ...[
              _VersionBadge(versionName: info.versionName),
              const SizedBox(height: 16),
              if (info.changelog.isNotEmpty || info.releaseNotes.isNotEmpty)
                _ReleaseNotes(
                  notes: info.changelog.isNotEmpty
                      ? info.changelog
                      : info.releaseNotes,
                ),
              const SizedBox(height: 16),
              _WifiOnlySection(
                value: update.wifiOnly,
                onChanged: update.setWifiOnly,
              ),
              const SizedBox(height: 24),
            ],
            if (update.status == UpdateStatus.downloading)
              _ProgressSection(
                progress: update.progress,
                label: 'Downloading...',
              )
            else if (update.status == UpdateStatus.verifying)
              const _ProgressSection(
                progress: 1,
                label: 'Verifying download...',
              )
            else if (update.status == UpdateStatus.installing)
              const _ProgressSection(
                progress: 1,
                label: 'Launching installer...',
              )
            else if (update.status == UpdateStatus.error)
              _ErrorSection(message: update.errorMessage)
            else if (update.status == UpdateStatus.awaitingPermission)
              const _PermissionSection()
            else
              _ActionButton(status: update.status),
          ],
        ),
      ),
    );
  }
}

class _UpdateIcon extends StatelessWidget {
  const _UpdateIcon({required this.status});

  final UpdateStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      UpdateStatus.readyToInstall => Icons.install_mobile_rounded,
      UpdateStatus.installing => Icons.install_mobile_rounded,
      UpdateStatus.verifying => Icons.verified_rounded,
      UpdateStatus.error => Icons.error_outline_rounded,
      _ => Icons.system_update_alt_rounded,
    };

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.violetGlowSoft,
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 36),
    );
  }
}

class _UpdateTitle extends StatelessWidget {
  const _UpdateTitle({required this.status});

  final UpdateStatus status;

  @override
  Widget build(BuildContext context) {
    final title = switch (status) {
      UpdateStatus.downloading => 'Downloading Update',
      UpdateStatus.verifying => 'Verifying Download',
      UpdateStatus.readyToInstall => 'Ready to Install',
      UpdateStatus.awaitingPermission => 'Permission Required',
      UpdateStatus.installing => 'Opening Installer',
      UpdateStatus.error => 'Update Failed',
      _ => 'Update Available',
    };

    final subtitle = switch (status) {
      UpdateStatus.downloading => 'Please keep the app open',
      UpdateStatus.verifying => 'Checking file integrity before install',
      UpdateStatus.readyToInstall => 'Tap below to launch the installer',
      UpdateStatus.awaitingPermission =>
        'Allow "Install unknown apps" to continue',
      UpdateStatus.installing => 'Switching to the Android installer',
      UpdateStatus.error => 'Something went wrong. Please try again.',
      _ => 'A new version of StudyTrack is ready',
    };

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.versionName});

  final String versionName;

  @override
  Widget build(BuildContext context) {
    if (versionName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.neonViolet.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonViolet.withAlpha(80)),
      ),
      child: Text(
        'Version $versionName',
        style: const TextStyle(
          color: AppColors.neonViolet,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's new",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          notes,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppColors.neonCyan,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
          ),
        ),
      ],
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final update = context.read<UpdateProvider>();

    return Column(
      children: [
        if (message != null)
          Text(
            message!,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        _GradientButton(label: 'Try Again', onPressed: update.retry),
        const SizedBox(height: 10),
        _DismissLink(onPressed: update.dismiss),
      ],
    );
  }
}

class _PermissionSection extends StatelessWidget {
  const _PermissionSection();

  @override
  Widget build(BuildContext context) {
    final update = context.read<UpdateProvider>();

    return Column(
      children: [
        _GradientButton(
          label: 'Grant Permission',
          onPressed: update.retryAfterPermission,
        ),
        const SizedBox(height: 10),
        _DismissLink(onPressed: update.dismiss),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.status});

  final UpdateStatus status;

  @override
  Widget build(BuildContext context) {
    final update = context.read<UpdateProvider>();

    if (status == UpdateStatus.readyToInstall) {
      return Column(
        children: [
          _GradientButton(label: 'Install Now', onPressed: update.install),
          const SizedBox(height: 10),
          _DismissLink(onPressed: update.dismiss),
        ],
      );
    }

    return Column(
      children: [
        _GradientButton(label: 'Update Now', onPressed: update.startDownload),
        const SizedBox(height: 10),
        _DismissLink(onPressed: update.dismiss),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.violetGlowSoft,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _WifiOnlySection extends StatelessWidget {
  const _WifiOnlySection({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: const Text(
      'Wi-Fi only',
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
    ),
    subtitle: const Text(
      'Avoid mobile data during downloads',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
    ),
    value: value,
    onChanged: onChanged,
    activeColor: AppColors.neonCyan,
  );
}

class _DismissLink extends StatelessWidget {
  const _DismissLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: const Text(
      'Remind me later',
      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
    ),
  );
}
