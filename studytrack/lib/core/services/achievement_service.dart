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

    return StreakUpdateResult(newStreak: nextStreak, streakBroken: streakBroken);
  }

  Future<List<BadgeModel>> checkAllBadges(String userId) async {
    final earned = await _loadEarnedBadges(userId);
    final earnedTypes = earned.map((b) => b.badgeType).toSet();

    final profile = await _supabaseService.getProfile(userId);
    final streak = (profile?['streak_count'] as num?)?.toInt() ?? 0;

    // Single query for all topics across all modules — avoids N+1.
    final modules = await _supabaseService.getModules(userId) ?? const [];
    final moduleIds = modules.map((m) => m.id).toList();
    final topics = moduleIds.isEmpty
        ? <TopicModel>[]
        : await _supabaseService.getTopicsByModuleIds(moduleIds);

    final studiedCount = topics.where((t) => t.isStudied).length;
    final highRatingCount = topics.where((t) => (t.currentRating ?? 0) >= 8).length;

    final pendingAwards = <String>[
      if (topics.isNotEmpty && !earnedTypes.contains('first_step')) 'first_step',
      if (streak >= 7 && !earnedTypes.contains('week_warrior')) 'week_warrior',
      if (topics.any((t) => t.currentRating == 10) &&
          !earnedTypes.contains('perfectionist'))
        'perfectionist',
      if (studiedCount >= 50 && !earnedTypes.contains('bookworm')) 'bookworm',
      if (highRatingCount >= 10 && !earnedTypes.contains('master')) 'master',
      if (streak >= 30 && !earnedTypes.contains('month_streak')) 'month_streak',
      if (topics.length >= 100 && !earnedTypes.contains('century')) 'century',
    ];

    for (final badgeType in pendingAwards) {
      final awarded = await awardBadge(userId, badgeType);
      if (awarded != null) earned.add(awarded);
    }

    return earned;
  }

  Future<BadgeModel?> awardBadge(String userId, String badgeType) async {
    try {
      // upsert with onConflict prevents duplicate rows if called concurrently
      // or if the badge was already awarded before we loaded earned badges.
      final row = await _supabaseService.client
          .from('badges')
          .upsert(
            {
              'user_id': userId,
              'badge_type': badgeType,
              'earned_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id,badge_type',
            ignoreDuplicates: true,
          )
          .select()
          .maybeSingle();

      return row == null ? null : BadgeModel.fromJson(row);
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
      debugPrint('_loadEarnedBadges error: $error');
      return <BadgeModel>[];
    }
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
