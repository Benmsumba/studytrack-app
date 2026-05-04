import 'package:flutter/foundation.dart';

import '../../models/badge_model.dart';
import '../../models/topic_model.dart';
import 'supabase_service.dart';

class StreakUpdateResult {
  const StreakUpdateResult({
    required this.newStreak,
    required this.streakBroken,
  });

  final int newStreak;
  final bool streakBroken;
}

class AchievementService {
  AchievementService({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  final SupabaseService _supabaseService;

  Future<StreakUpdateResult> checkAndUpdateStreak(String userId) async {
    final profile = await _supabaseService.getProfile(userId);
    if (profile == null) {
      return const StreakUpdateResult(newStreak: 0, streakBroken: false);
    }

    final currentStreak = (profile['streak_count'] as num?)?.toInt() ?? 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    DateTime? lastStudy;
    final rawLastStudy = profile['last_study_date'];
    if (rawLastStudy != null) {
      lastStudy = DateTime.tryParse(rawLastStudy.toString());
      if (lastStudy != null) {
        lastStudy = DateTime(lastStudy.year, lastStudy.month, lastStudy.day);
      }
    }

    final yesterday = todayDate.subtract(const Duration(days: 1));
    final isSameDay = lastStudy != null && _sameDate(lastStudy, todayDate);
    final isConsecutive = lastStudy != null && _sameDate(lastStudy, yesterday);

    final nextStreak = isSameDay
        ? currentStreak
        : isConsecutive
        ? currentStreak + 1
        : 1;
    final streakBroken = !isSameDay && !isConsecutive && currentStreak > 0;

    await _supabaseService.updateProfile(userId, {
      'streak_count': nextStreak,
      'last_study_date': todayDate.toIso8601String().split('T').first,
    });

    return StreakUpdateResult(
      newStreak: nextStreak,
      streakBroken: streakBroken,
    );
  }

  Future<List<BadgeModel>> checkAllBadges(String userId) async {
    final earned = await _loadEarnedBadges(userId);
    final earnedTypes = earned.map((badge) => badge.badgeType).toSet();

    final profile = await _supabaseService.getProfile(userId);
    final streak = (profile?['streak_count'] as num?)?.toInt() ?? 0;

    final modules = await _supabaseService.getModules(userId) ?? const [];
    final topicBuckets = <TopicModel>[];
    for (final module in modules) {
      final topics = await _supabaseService.getTopics(module.id) ?? const [];
      topicBuckets.addAll(topics);
    }

    final pendingAwards = <String>[];

    if (topicBuckets.isNotEmpty && !earnedTypes.contains('first_step')) {
      pendingAwards.add('first_step');
    }
    if (streak >= 7 && !earnedTypes.contains('week_warrior')) {
      pendingAwards.add('week_warrior');
    }
    if (topicBuckets.any((topic) => topic.currentRating == 10) &&
        !earnedTypes.contains('perfectionist')) {
      pendingAwards.add('perfectionist');
    }
    if (topicBuckets.where((topic) => topic.isStudied).length >= 50 &&
        !earnedTypes.contains('bookworm')) {
      pendingAwards.add('bookworm');
    }
    if (topicBuckets.where((topic) => (topic.currentRating ?? 0) >= 8).length >=
            10 &&
        !earnedTypes.contains('master')) {
      pendingAwards.add('master');
    }
    if (streak >= 30 && !earnedTypes.contains('month_streak')) {
      pendingAwards.add('month_streak');
    }
    if (topicBuckets.length >= 100 && !earnedTypes.contains('century')) {
      pendingAwards.add('century');
    }

    for (final badgeType in pendingAwards) {
      final awarded = await awardBadge(userId, badgeType);
      if (awarded != null) {
        earned.add(awarded);
      }
    }

    return earned;
  }

  Future<BadgeModel?> awardBadge(String userId, String badgeType) async {
    try {
      final row = await _supabaseService.client
          .from('badges')
          .insert({
            'user_id': userId,
            'badge_type': badgeType,
            'earned_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return BadgeModel.fromJson(row);
    } on Object catch (error) {
      debugPrint('awardBadge error: $error');
      return null;
    }
  }

  Future<List<BadgeModel>> _loadEarnedBadges(String userId) async {
    try {
      final rows = await _supabaseService.client
          .from('badges')
          .select()
          .eq('user_id', userId)
          .order('earned_at');

      return (rows as List<dynamic>)
          .map((row) => BadgeModel.fromJson(row as Map<String, dynamic>))
          .toList(growable: true);
    } on Object catch (error) {
      debugPrint('load badges error: $error');
      return <BadgeModel>[];
    }
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
