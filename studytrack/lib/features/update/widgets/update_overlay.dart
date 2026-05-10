import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
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
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.glowPrimary,
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
    final palette = context.palette;
    final icon = switch (status) {
      UpdateStatus.readyToInstall => Icons.download_done_rounded,
      UpdateStatus.installing => Icons.install_mobile_rounded,
      UpdateStatus.verifying => Icons.verified_rounded,
      UpdateStatus.error => Icons.error_outline_rounded,
      _ => Icons.system_update_alt_rounded,
    };

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: palette.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: palette.glowPrimary,
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 34),
    );
  }
}

class _UpdateTitle extends StatelessWidget {
  const _UpdateTitle({required this.status});

  final UpdateStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

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
          style: theme.textTheme.titleLarge?.copyWith(
            color: palette.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
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
    if (versionName.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: palette.brandPrimary.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.brandPrimary.withAlpha(80)),
      ),
      child: Text(
        'Version $versionName',
        style: TextStyle(
          color: palette.brandPrimary,
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's new", style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            notes,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final percent = (progress * 100).toInt();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(
              '$percent%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: palette.brandSecondary,
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
            minHeight: 6,
            backgroundColor: palette.border,
            valueColor: AlwaysStoppedAnimation<Color>(palette.brandSecondary),
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
    final palette = context.palette;
    final theme = Theme.of(context);

    return Column(
      children: [
        if (message != null)
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.danger),
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: palette.brandGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: palette.glowPrimary,
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WifiOnlySection extends StatelessWidget {
  const _WifiOnlySection({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Wi-Fi only',
        style: theme.textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
      ),
      subtitle: Text(
        'Avoid mobile data during downloads',
        style: theme.textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: palette.brandPrimary,
    );
  }
}

class _DismissLink extends StatelessWidget {
  const _DismissLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton(
      onPressed: onPressed,
      child: Text(
        'Remind me later',
        style: TextStyle(color: palette.textMuted, fontSize: 13),
      ),
    );
  }
}
