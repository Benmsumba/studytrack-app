import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/spotify_service.dart';

class MusicPlayerWidget extends StatefulWidget {
  const MusicPlayerWidget({super.key});

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isConnected = false;
  SpotifyPlaybackState? _playback;
  bool _actionBusy = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  Future<void> _refresh() async {
    final connected = await SpotifyService.hasStoredSession();
    if (!mounted) return;
    setState(() => _isConnected = connected);
    if (connected) {
      await _fetchPlayback();
      _startPolling();
    } else {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _fetchPlayback();
    });
  }

  Future<void> _fetchPlayback() async {
    final state = await SpotifyService.getPlaybackState();
    if (!mounted) return;
    setState(() => _playback = state);
  }

  Future<void> _connectSpotify() async {
    final clientId = AppConstants.resolvedSpotifyClientId;
    if (clientId.isEmpty) {
      _showSnack('Spotify client ID is not configured.');
      return;
    }
    final verifier = await SpotifyService.startAuth(clientId: clientId);
    if (!mounted) return;
    if (verifier == null) {
      _showSnack('Failed to start Spotify auth.');
      return;
    }
    _showSnack('Spotify login opened — come back after authorising.');
  }

  Future<void> _disconnectSpotify() async {
    await SpotifyService.clearStoredSession();
    if (!mounted) return;
    setState(() {
      _isConnected = false;
      _playback = null;
    });
    _pollTimer?.cancel();
    _showSnack('Spotify disconnected.');
  }

  Future<void> _togglePlayPause() async {
    if (_actionBusy) return;
    final playing = _playback?.isPlaying ?? false;
    setState(() => _actionBusy = true);
    final ok = await SpotifyService.togglePlayPause(currentlyPlaying: playing);
    if (!mounted) return;
    if (ok) await _fetchPlayback();
    setState(() => _actionBusy = false);
  }

  Future<void> _skipNext() async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    final ok = await SpotifyService.skipToNext();
    if (!mounted) return;
    if (ok) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _fetchPlayback();
    }
    setState(() => _actionBusy = false);
  }

  Future<void> _skipPrevious() async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    final ok = await SpotifyService.skipToPrevious();
    if (!mounted) return;
    if (ok) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _fetchPlayback();
    }
    setState(() => _actionBusy = false);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: AppColors.cardGradient,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(isConnected: _isConnected),
        const SizedBox(height: 14),
        if (_isConnected && _playback != null)
          _NowPlaying(playback: _playback!).animate().fadeIn(duration: 300.ms)
        else if (_isConnected)
          _NoActiveDevice(
            onOpenSpotify: () => SpotifyService.openPlaylist(
              SpotifyService.studyPlaylists[_selectedIndex],
            ),
          ),
        if (_isConnected && _playback != null) ...[
          const SizedBox(height: 14),
          _ProgressBar(playback: _playback!),
          const SizedBox(height: 12),
          _PlaybackControls(
            isPlaying: _playback!.isPlaying,
            busy: _actionBusy,
            onPrevious: _skipPrevious,
            onTogglePlay: _togglePlayPause,
            onNext: _skipNext,
          ),
        ],
        const SizedBox(height: 14),
        _PlaylistPicker(
          playlists: SpotifyService.studyPlaylists,
          selectedIndex: _selectedIndex,
          onSelect: (i) => setState(() => _selectedIndex = i),
        ),
        const SizedBox(height: 14),
        _Footer(
          isConnected: _isConnected,
          selectedPlaylist: SpotifyService.studyPlaylists[_selectedIndex],
          onConnect: _connectSpotify,
          onDisconnect: _disconnectSpotify,
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.isConnected});
  final bool isConnected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Flow Mode',
              style: AppTextStyles.headingSmall.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              isConnected
                  ? 'Spotify connected'
                  : 'Connect Spotify to control playback',
              style: AppTextStyles.caption.copyWith(
                color: isConnected
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.playback});
  final SpotifyPlaybackState playback;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: playback.albumArtUrl != null
            ? CachedNetworkImage(
                imageUrl: playback.albumArtUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const _AlbumArtPlaceholder(),
              )
            : const _AlbumArtPlaceholder(),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playback.trackName.isNotEmpty
                  ? playback.trackName
                  : 'Unknown track',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              playback.artistName.isNotEmpty
                  ? playback.artistName
                  : 'Unknown artist',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (playback.isPlaying ? AppColors.success : AppColors.textMuted)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              playback.isPlaying
                  ? Icons.equalizer_rounded
                  : Icons.pause_circle_outline_rounded,
              color: playback.isPlaying
                  ? AppColors.success
                  : AppColors.textMuted,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              playback.isPlaying ? 'Playing' : 'Paused',
              style: AppTextStyles.caption.copyWith(
                color: playback.isPlaying
                    ? AppColors.success
                    : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _AlbumArtPlaceholder extends StatelessWidget {
  const _AlbumArtPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted),
  );
}

class _NoActiveDevice extends StatelessWidget {
  const _NoActiveDevice({required this.onOpenSpotify});
  final VoidCallback onOpenSpotify;

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
      children: [
        const Icon(Icons.devices_rounded, color: AppColors.textMuted, size: 28),
        const SizedBox(height: 8),
        Text(
          'No active Spotify device',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Open Spotify on your phone and start playing, then come back.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onOpenSpotify,
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Open Spotify'),
          style: TextButton.styleFrom(foregroundColor: AppColors.neonCyan),
        ),
      ],
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.playback});
  final SpotifyPlaybackState playback;

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: playback.progressFraction,
          minHeight: 4,
          backgroundColor: AppColors.border,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
        ),
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _fmt(playback.progressMs),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          Text(
            _fmt(playback.durationMs),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    ],
  );
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.isPlaying,
    required this.busy,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
  });
  final bool isPlaying;
  final bool busy;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _ControlBtn(
        icon: Icons.skip_previous_rounded,
        size: 28,
        onTap: busy ? null : onPrevious,
      ),
      const SizedBox(width: 16),
      GestureDetector(
        onTap: busy ? null : onTogglePlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: AppColors.violetGlowSoft,
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ),
      const SizedBox(width: 16),
      _ControlBtn(
        icon: Icons.skip_next_rounded,
        size: 28,
        onTap: busy ? null : onNext,
      ),
    ],
  );
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.size,
    required this.onTap,
  });
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onTap == null ? 0.4 : 1.0,
      child: Icon(icon, color: Colors.white, size: size),
    ),
  );
}

class _PlaylistPicker extends StatelessWidget {
  const _PlaylistPicker({
    required this.playlists,
    required this.selectedIndex,
    required this.onSelect,
  });
  final List<SpotifyStudyPlaylist> playlists;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('STUDY PLAYLISTS', style: AppTextStyles.sectionOverline),
      const SizedBox(height: 10),
      SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: playlists.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = playlists[index];
            final selected = index == selectedIndex;
            return GestureDetector(
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 110,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected
                      ? item.accentColor.withValues(alpha: 0.2)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? item.accentColor : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 18)),
                    const Spacer(),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isConnected,
    required this.selectedPlaylist,
    required this.onConnect,
    required this.onDisconnect,
  });
  final bool isConnected;
  final SpotifyStudyPlaylist selectedPlaylist;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton.icon(
            onPressed: () => SpotifyService.openPlaylist(selectedPlaylist),
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: Colors.white,
              size: 16,
            ),
            label: Text(
              'Open in Spotify',
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      OutlinedButton(
        onPressed: isConnected ? onDisconnect : onConnect,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isConnected ? AppColors.danger : AppColors.neonCyan,
          side: BorderSide(
            color: isConnected ? AppColors.danger : AppColors.neonCyan,
          ),
        ),
        child: Text(isConnected ? 'Disconnect' : 'Connect'),
      ),
    ],
  );
}
