import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
}
