import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/topic_model.dart';

class WeeklyWrappedScreen extends StatefulWidget {
  const WeeklyWrappedScreen({super.key});

  @override
  State<WeeklyWrappedScreen> createState() => _WeeklyWrappedScreenState();
}

class _WeeklyWrappedScreenState extends State<WeeklyWrappedScreen> {
  final SupabaseService _supabase = SupabaseService();
  final GeminiService _gemini = GeminiService();
  final PageController _pageController = PageController();

  late int topicsStudied;
  late double averageRating;
  late String bestSubject;
  late String weakestSubject;
  late int streak;
  late int sessionsCompleted;
  late int sessionsMissed;
  String aiSummary = '';
  String? studentName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = _supabase.getCurrentUser();
      if (user == null) return;

      final profile = await _supabase.getProfile(user.id);
      studentName = (profile?['name'] as String?) ?? 'Student';
      streak = (profile?['streak_count'] as num?)?.toInt() ?? 0;

      final report = await _supabase.getLastWeekReport(user.id);
      final topics =
          await _supabase.getTopicsNeedingReview(user.id) ??
          const <TopicModel>[];
      final sessions =
          await _supabase.getStudySessions(user.id, DateTime.now()) ??
          const <Map<String, dynamic>>[];

      topicsStudied =
          (report?['topics_studied'] as num?)?.toInt() ?? topics.length;
      averageRating =
          (report?['average_rating'] as num?)?.toDouble() ??
          _averageRating(topics);
      final bestSubjectFromReport = report?['best_subject']?.toString().trim();
      bestSubject =
          bestSubjectFromReport != null && bestSubjectFromReport.isNotEmpty
          ? bestSubjectFromReport
          : _bestTopicName(topics) ?? 'Top Topic';
      final weakestSubjectFromReport = report?['weakest_subject']
          ?.toString()
          .trim();
      weakestSubject =
          weakestSubjectFromReport != null &&
              weakestSubjectFromReport.isNotEmpty
          ? weakestSubjectFromReport
          : _weakestTopicName(topics) ?? 'Focus Topic';
      sessionsCompleted =
          (report?['sessions_completed'] as num?)?.toInt() ??
          sessions
              .where((row) => (row['status']?.toString() ?? '') == 'completed')
              .length;
      sessionsMissed =
          (report?['sessions_missed'] as num?)?.toInt() ??
          (sessions.length - sessionsCompleted).clamp(0, 999);

      final reportSummary = report?['ai_summary']?.toString().trim();
      aiSummary = reportSummary != null && reportSummary.isNotEmpty
          ? reportSummary
          : await _gemini.generateWeeklyWrappedSummary(
              studentName: studentName!,
              topicsStudied: topicsStudied,
              averageRating: averageRating,
              bestSubject: bestSubject,
              weakestSubject: weakestSubject,
              streak: streak,
              sessionsCompleted: sessionsCompleted,
              sessionsMissed: sessionsMissed,
            );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading wrapped: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _averageRating(List<TopicModel> topics) {
    final rated = topics.where((topic) => topic.currentRating != null).toList();
    if (rated.isEmpty) {
      return 0;
    }

    final total = rated.fold<int>(
      0,
      (sum, topic) => sum + (topic.currentRating ?? 0),
    );

    return total / rated.length;
  }

  String? _bestTopicName(List<TopicModel> topics) {
    if (topics.isEmpty) return null;
    final sorted = [...topics]
      ..sort((a, b) => (b.currentRating ?? 0).compareTo(a.currentRating ?? 0));
    return sorted.first.name;
  }

  String? _weakestTopicName(List<TopicModel> topics) {
    if (topics.isEmpty) return null;
    final sorted = [...topics]
      ..sort((a, b) => (a.currentRating ?? 0).compareTo(b.currentRating ?? 0));
    return sorted.first.name;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: AppColors.backgroundDark,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          _buildIntroPage(),
          _buildTopicsPage(),
          _buildBestPage(),
          _buildWeakestPage(),
          _buildStreakPage(),
          _buildSessionsPage(),
          _buildSummaryPage(),
          _buildSharePage(),
        ],
      ),
    );
  }

  Widget _buildIntroPage() => Container(
      color: AppColors.backgroundDark,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.backgroundDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(),
          Column(
            children: [
              Text(
                'Your Week in Review',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Week of ${DateTime.now().year}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                studentName ?? 'Student',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                const Icon(Icons.arrow_upward, color: Colors.white38, size: 28),
                const SizedBox(height: 8),
                Text(
                  'Swipe up',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildTopicsPage() => Container(
      color: AppColors.accent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            topicsStudied.toString(),
            style: GoogleFonts.outfit(
              fontSize: 96,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'topics covered',
            style: GoogleFonts.inter(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'this week',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );

  Widget _buildBestPage() => Container(
      color: AppColors.backgroundDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            'Your strongest subject',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bestSubject,
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${averageRating.toStringAsFixed(1)}/10',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );

  Widget _buildWeakestPage() => Container(
      color: AppColors.backgroundDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            'Needs more love',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            weakestSubject,
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "You've got this 💪",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );

  Widget _buildStreakPage() => Container(
      color: AppColors.backgroundDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text(
            streak.toString(),
            style: GoogleFonts.outfit(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'day streak',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

  Widget _buildSessionsPage() {
    final total = sessionsCompleted + sessionsMissed;
    final percent = total == 0 ? 0 : (sessionsCompleted / total * 100).toInt();

    return Container(
      color: AppColors.backgroundDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$sessionsCompleted of $total sessions',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '$percent%',
            style: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() => Container(
      color: AppColors.backgroundDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              aiSummary.isEmpty
                  ? 'Great work this week! Keep it up.'
                  : aiSummary,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

  Widget _buildSharePage() => Container(
      color: AppColors.backgroundDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'StudyTrack Weekly',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$studentName',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Topics: $topicsStudied',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            child: Text(
              'Share',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
}
