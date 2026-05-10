import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/offline_sync_service.dart';

/// Global offline / sync status indicator.
///
/// Shown as a slim animated pill that slides down from the top of the screen
/// whenever the device is offline, syncing, has a pending-change backlog,
/// or has experienced a sync error. Disappears automatically when cleared.
class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<OfflineSyncService?>(context);
    if (sync == null) return child;

    final isOffline = !sync.isOnline;
    final isSyncing = sync.isSyncing;
    final hasError = sync.lastSyncError != null;
    final hasPending = sync.hasPendingChanges;

    final bool show = isOffline || isSyncing || hasError || hasPending;

    _BannerData? data;
    if (isOffline) {
      data = _BannerData(
        icon: Icons.cloud_off_rounded,
        message: "You're offline — changes will sync when you reconnect.",
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
        ),
      );
    } else if (hasError) {
      data = _BannerData(
        icon: Icons.sync_problem_rounded,
        message: 'Sync failed — ${sync.lastSyncError}',
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
        ),
      );
    } else if (isSyncing) {
      data = _BannerData(
        icon: Icons.sync_rounded,
        message: 'Syncing your changes…',
        gradient: const LinearGradient(
          colors: [Color(0xFF1C4E5C), Color(0xFF4A9EBD)],
        ),
        spinning: true,
      );
    } else if (hasPending) {
      data = _BannerData(
        icon: Icons.schedule_rounded,
        message:
            '${sync.pendingChanges} change${sync.pendingChanges == 1 ? '' : 's'} waiting to sync.',
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF059669)],
        ),
      );
    }

    return Column(
      children: [
        _AnimatedBanner(show: show, data: data),
        Expanded(child: child),
      ],
    );
  }
}

// ── Animated banner ───────────────────────────────────────────────────────────

class _AnimatedBanner extends StatefulWidget {
  const _AnimatedBanner({required this.show, required this.data});
  final bool show;
  final _BannerData? data;

  @override
  State<_AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<_AnimatedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideY;
  late final Animation<double> _opacity;
  _BannerData? _lastData;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideY = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    if (widget.show) {
      _lastData = widget.data;
      _ctrl.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedBanner old) {
    super.didUpdateWidget(old);
    if (widget.show && !old.show) {
      _lastData = widget.data;
      _ctrl.forward();
    } else if (!widget.show && old.show) {
      _ctrl.reverse();
    } else if (widget.show && widget.data != null) {
      setState(() => _lastData = widget.data);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _lastData;
    if (data == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        if (_ctrl.value == 0) return const SizedBox.shrink();
        return FractionalTranslation(
          translation: Offset(0, _slideY.value),
          child: FadeTransition(
            opacity: _opacity,
            child: _BannerContent(data: data),
          ),
        );
      },
    );
  }
}

// ── Banner content ────────────────────────────────────────────────────────────

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.data});
  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: data.gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              if (data.spinning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(data.icon, color: Colors.white, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
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

class _BannerData {
  const _BannerData({
    required this.icon,
    required this.message,
    required this.gradient,
    this.spinning = false,
  });
  final IconData icon;
  final String message;
  final LinearGradient gradient;
  final bool spinning;
}
