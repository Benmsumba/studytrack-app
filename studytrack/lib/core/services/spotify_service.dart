import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import 'supabase_service.dart';

// ---------------------------------------------------------------------------
// Playback state model
// ---------------------------------------------------------------------------

class SpotifyPlaybackState {
  const SpotifyPlaybackState({
    required this.isPlaying,
    required this.trackName,
    required this.artistName,
    required this.albumArtUrl,
    required this.progressMs,
    required this.durationMs,
  });

  factory SpotifyPlaybackState.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;
    final artists = (item?['artists'] as List<dynamic>?)
            ?.map((a) => (a as Map<String, dynamic>)['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ') ??
        '';
    final images =
        ((item?['album'] as Map<String, dynamic>?)?['images'] as List<dynamic>?) ?? [];
    final artUrl = images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['url']?.toString()
        : null;

    return SpotifyPlaybackState(
      isPlaying: json['is_playing'] as bool? ?? false,
      trackName: item?['name']?.toString() ?? '',
      artistName: artists,
      albumArtUrl: artUrl,
      progressMs: (json['progress_ms'] as num?)?.toInt() ?? 0,
      durationMs: (item?['duration_ms'] as num?)?.toInt() ?? 1,
    );
  }

  final bool isPlaying;
  final String trackName;
  final String artistName;
  final String? albumArtUrl;
  final int progressMs;
  final int durationMs;

  double get progressFraction =>
      durationMs > 0 ? (progressMs / durationMs).clamp(0.0, 1.0) : 0.0;
}

class SpotifyStudyPlaylist {
  const SpotifyStudyPlaylist({
    required this.title,
    required this.description,
    required this.searchQuery,
    required this.emoji,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String searchQuery;
  final String emoji;
  final Color accentColor;

  Uri get deepLink =>
      Uri.parse('spotify:search:${Uri.encodeComponent(searchQuery)}');
  Uri get webLink => Uri.parse(
    'https://open.spotify.com/search/${Uri.encodeComponent(searchQuery)}',
  );
}

class SpotifyService {
  static const _storage = FlutterSecureStorage();
  static const _codeVerifierKey = 'spotify_code_verifier';
  static const _accessTokenKey = 'spotify_access_token';
  static const _refreshTokenKey = 'spotify_refresh_token';
  static const _expiresAtKey = 'spotify_token_expires_at';
  static Timer? _refreshMonitorTimer;

  static const List<SpotifyStudyPlaylist> studyPlaylists = [
    SpotifyStudyPlaylist(
      title: 'Lo-Fi Focus',
      description: 'Soft beats for deep reading sessions.',
      searchQuery: 'lofi study beats',
      emoji: '🎧',
      accentColor: Color(0xFF7C3AED),
    ),
    SpotifyStudyPlaylist(
      title: 'Deep Work Flow',
      description: 'Instrumental focus for long modules.',
      searchQuery: 'deep focus study music',
      emoji: '🧠',
      accentColor: Color(0xFF06B6D4),
    ),
    SpotifyStudyPlaylist(
      title: 'Brain Food',
      description: 'Calm productivity sounds for review mode.',
      searchQuery: 'brain food study playlist',
      emoji: '📚',
      accentColor: Color(0xFF10B981),
    ),
    SpotifyStudyPlaylist(
      title: 'Piano Focus',
      description: 'Minimal piano for note-taking and recall.',
      searchQuery: 'peaceful piano study',
      emoji: '🎹',
      accentColor: Color(0xFFF59E0B),
    ),
    SpotifyStudyPlaylist(
      title: 'Night Revision',
      description: 'Late-night calm for quiet revision blocks.',
      searchQuery: 'night study playlist',
      emoji: '🌙',
      accentColor: Color(0xFFF43F5E),
    ),
  ];

  static Future<bool> openPlaylist(SpotifyStudyPlaylist playlist) async {
    final deepLink = playlist.deepLink;
    final webLink = playlist.webLink;

    try {
      if (await canLaunchUrl(deepLink)) {
        return launchUrl(deepLink, mode: LaunchMode.externalApplication);
      }
      return launchUrl(webLink, mode: LaunchMode.externalApplication);
    } on Object catch (error) {
      debugPrint('openPlaylist error: $error');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // OAuth (PKCE) helpers
  // -------------------------------------------------------------------------

  static String _randomString([int length = 64]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)))
        .map((c) => String.fromCharCode(c))
        .join();
  }

  static String _base64UrlEncode(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  static String codeChallengeFromVerifier(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes).bytes;
    return _base64UrlEncode(digest);
  }

  /// Start the Spotify authorization flow using PKCE. Returns the generated
  /// `codeVerifier` which must be retained and later provided to
  /// [handleAuthCodeExchange]. The redirect handling must be wired in the
  /// app (deep link) and the resulting `code` passed to
  /// [handleAuthCodeExchange].
  static Future<String?> startAuth({
    required String clientId,
    String scope =
        'user-read-private user-read-email '
        'user-read-playback-state user-modify-playback-state '
        'user-read-currently-playing',
  }) async {
    final codeVerifier = _randomString(128);
    final codeChallenge = codeChallengeFromVerifier(codeVerifier);

    final redirectUri = Uri.parse(AppConstants.resolvedOAuthRedirectUri);

    final authUri = Uri.parse('https://accounts.spotify.com/authorize').replace(queryParameters: {
      'response_type': 'code',
      'client_id': clientId,
      'scope': scope,
      'redirect_uri': redirectUri.toString(),
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
    });

    try {
      await launchUrl(authUri, mode: LaunchMode.externalApplication);
      try {
        await _storage.write(key: _codeVerifierKey, value: codeVerifier);
      } on Object catch (e) {
        debugPrint('Failed to persist code verifier: $e');
      }
      return codeVerifier;
    } on Object catch (e) {
      debugPrint('startAuth error: $e');
      return null;
    }
  }

  /// Exchange the authorization `code` (received on redirect) for tokens.
  /// Stores tokens on the user's profile via `SupabaseService.updateProfile`.
  static Future<bool> handleAuthCodeExchange({
    required String code,
    required String codeVerifier,
    required String clientId,
  }) async {
    try {
      final redirectUri = AppConstants.resolvedOAuthRedirectUri;
      final resp = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': clientId,
          'code_verifier': codeVerifier,
        },
      );

      if (resp.statusCode != 200) {
        debugPrint('Spotify token exchange failed: ${resp.statusCode} ${resp.body}');
        return false;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final expiresIn = (data['expires_in'] as num?)?.toInt();

      final user = SupabaseService().getCurrentUser();
      if (user == null || accessToken == null) return false;

      final expiresAt = expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String()
          : null;

      await _storage.write(key: _accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
      if (expiresAt != null) {
        await _storage.write(key: _expiresAtKey, value: expiresAt);
      }
      await clearCodeVerifier();
      await scheduleTokenRefresh(clientId: clientId);
      return true;
    } on Object catch (e) {
      debugPrint('handleAuthCodeExchange error: $e');
      return false;
    }
  }

  static Future<String?> retrieveCodeVerifier() async {
    try {
      return _storage.read(key: _codeVerifierKey);
    } on Object catch (e) {
      debugPrint('retrieveCodeVerifier error: $e');
      return null;
    }
  }

  static Future<void> clearCodeVerifier() async {
    try {
      await _storage.delete(key: _codeVerifierKey);
    } on Object catch (e) {
      debugPrint('clearCodeVerifier error: $e');
    }
  }

  static Future<String?> readAccessToken() async {
    try {
      return _storage.read(key: _accessTokenKey);
    } on Object catch (e) {
      debugPrint('readAccessToken error: $e');
      return null;
    }
  }

  static Future<String?> readRefreshToken() async {
    try {
      return _storage.read(key: _refreshTokenKey);
    } on Object catch (e) {
      debugPrint('readRefreshToken error: $e');
      return null;
    }
  }

  static Future<DateTime?> readExpiresAt() async {
    try {
      final raw = await _storage.read(key: _expiresAtKey);
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } on Object catch (e) {
      debugPrint('readExpiresAt error: $e');
      return null;
    }
  }

  static Future<bool> hasStoredSession() async {
    final accessToken = await readAccessToken();
    final refreshToken = await readRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }

  static Future<void> clearStoredSession() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _expiresAtKey);
      stopTokenRefreshMonitor();
    } on Object catch (e) {
      debugPrint('clearStoredSession error: $e');
    }
  }

  /// Refresh stored Spotify token using refresh token from profile.
  static Future<bool> refreshToken({required String clientId}) async {
    try {
      final refreshToken = await readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final resp = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        },
      );

      if (resp.statusCode != 200) {
        debugPrint('Spotify refresh failed: ${resp.statusCode} ${resp.body}');
        return false;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final expiresIn = (data['expires_in'] as num?)?.toInt();

      if (accessToken == null) return false;

      final expiresAt = expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String()
          : null;

      await _storage.write(key: _accessTokenKey, value: accessToken);
      if (expiresAt != null) {
        await _storage.write(key: _expiresAtKey, value: expiresAt);
      }
      await scheduleTokenRefresh(clientId: clientId);
      return true;
    } on Object catch (e) {
      debugPrint('refreshToken error: $e');
      return false;
    }
  }

  static Future<void> startTokenRefreshMonitor({required String clientId}) async {
    stopTokenRefreshMonitor();
    await _maybeRefreshNow(clientId: clientId);
    _refreshMonitorTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => unawaited(_maybeRefreshNow(clientId: clientId)),
    );
  }

  static Future<void> scheduleTokenRefresh({required String clientId}) async {
    final expiresAt = await readExpiresAt();
    if (expiresAt == null) return;

    final refreshAt = expiresAt.subtract(const Duration(minutes: 5));
    final delay = refreshAt.difference(DateTime.now());
    final wait = delay.isNegative ? Duration.zero : delay;

    _refreshMonitorTimer?.cancel();
    _refreshMonitorTimer = Timer(wait, () async {
      final refreshed = await refreshToken(clientId: clientId);
      if (!refreshed) {
        _refreshMonitorTimer = Timer(
          const Duration(minutes: 2),
          () => unawaited(refreshToken(clientId: clientId)),
        );
      }
    });
  }

  static void stopTokenRefreshMonitor() {
    _refreshMonitorTimer?.cancel();
    _refreshMonitorTimer = null;
  }

  static Future<bool> _maybeRefreshNow({required String clientId}) async {
    final expiresAt = await readExpiresAt();
    if (expiresAt == null) return false;

    final shouldRefresh = DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 10)));
    if (!shouldRefresh) return false;
    final refreshed = await refreshToken(clientId: clientId);
    if (!refreshed) {
      _refreshMonitorTimer = Timer(
        const Duration(minutes: 2),
        () => unawaited(refreshToken(clientId: clientId)),
      );
    }
    return refreshed;
  }

  // -------------------------------------------------------------------------
  // Spotify Web API — playback control
  // -------------------------------------------------------------------------

  static const _apiBase = 'https://api.spotify.com/v1';

  /// Returns the current playback state, or null when nothing is playing
  /// or the token is missing / expired.
  static Future<SpotifyPlaybackState?> getPlaybackState() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final resp = await http.get(
        Uri.parse('$_apiBase/me/player'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 204) return null; // No active device
      if (resp.statusCode != 200) {
        debugPrint('getPlaybackState HTTP ${resp.statusCode}: ${resp.body}');
        return null;
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return SpotifyPlaybackState.fromJson(json);
    } on Object catch (e) {
      debugPrint('getPlaybackState error: $e');
      return null;
    }
  }

  /// Toggles play/pause. Pass [currentlyPlaying] = true to pause, false to
  /// resume. Returns true when the request succeeded (HTTP 204).
  static Future<bool> togglePlayPause({required bool currentlyPlaying}) async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return false;
    final endpoint = currentlyPlaying
        ? '$_apiBase/me/player/pause'
        : '$_apiBase/me/player/play';
    try {
      final resp = await http.put(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Length': '0',
        },
      ).timeout(const Duration(seconds: 8));
      return resp.statusCode == 204;
    } on Object catch (e) {
      debugPrint('togglePlayPause error: $e');
      return false;
    }
  }

  /// Skips to the next track. Returns true on HTTP 204.
  static Future<bool> skipToNext() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return false;
    try {
      final resp = await http.post(
        Uri.parse('$_apiBase/me/player/next'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Length': '0',
        },
      ).timeout(const Duration(seconds: 8));
      return resp.statusCode == 204;
    } on Object catch (e) {
      debugPrint('skipToNext error: $e');
      return false;
    }
  }

  /// Skips to the previous track. Returns true on HTTP 204.
  static Future<bool> skipToPrevious() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return false;
    try {
      final resp = await http.post(
        Uri.parse('$_apiBase/me/player/previous'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Length': '0',
        },
      ).timeout(const Duration(seconds: 8));
      return resp.statusCode == 204;
    } on Object catch (e) {
      debugPrint('skipToPrevious error: $e');
      return false;
    }
  }
}
