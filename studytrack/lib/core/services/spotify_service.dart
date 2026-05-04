import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'supabase_service.dart';

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
  static Future<String?> startAuth({required String clientId, String scope = 'user-read-private user-read-email'}) async {
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
      if (user == null) return false;

      final expiresAt = expiresIn != null ? DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String() : null;

      final update = <String, dynamic>{
        if (accessToken != null) 'spotify_access_token': accessToken,
        if (refreshToken != null) 'spotify_refresh_token': refreshToken,
        if (expiresAt != null) 'spotify_token_expires_at': expiresAt,
      };

      await SupabaseService().updateProfile(user.id, update);
      return true;
    } on Object catch (e) {
      debugPrint('handleAuthCodeExchange error: $e');
      return false;
    }
  }

  /// Refresh stored Spotify token using refresh token from profile.
  static Future<bool> refreshToken({required String clientId}) async {
    try {
      final user = SupabaseService().getCurrentUser();
      if (user == null) return false;
      final profile = await SupabaseService().getProfile(user.id);
      final refreshToken = profile?['spotify_refresh_token'] as String?;
      if (refreshToken == null) return false;

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

      final expiresAt = expiresIn != null ? DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String() : null;

      final update = <String, dynamic>{
        if (accessToken != null) 'spotify_access_token': accessToken,
        if (expiresAt != null) 'spotify_token_expires_at': expiresAt,
      };

      await SupabaseService().updateProfile(user.id, update);
      return true;
    } on Object catch (e) {
      debugPrint('refreshToken error: $e');
      return false;
    }
  }
}
