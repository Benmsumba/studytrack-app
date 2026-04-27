import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Weekly Report Card - Shows student's weekly statistics
class WeeklyReportCard extends StatelessWidget {
  final String studentName;
  final String course;
  final int weekNumber;
  final int topicsStudied;
  final double averageRating;
  final int streak;
  final String bestSubject;
  final GlobalKey boundaryKey;

  const WeeklyReportCard({
    super.key,
    required this.studentName,
    required this.course,
    required this.weekNumber,
    required this.topicsStudied,
    required this.averageRating,
    required this.streak,
    required this.bestSubject,
    required this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 1080,
        height: 1080,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1A),
              const Color(0xFF16213E),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week $weekNumber Report',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    studentName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              // Stats Grid
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBox('Topics\nStudied', topicsStudied.toString()),
                      _buildStatBox('Avg\nRating', '${averageRating.toStringAsFixed(1)}/10'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBox('🔥 Streak', '$streak days'),
                      _buildStatBox('Best\nSubject', bestSubject),
                    ],
                  ),
                ],
              ),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'StudyTrack',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Study smarter. Know where you stand.',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 20,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.primary,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Topic Mastered Card - Celebrates mastering a topic
class TopicMasteredCard extends StatelessWidget {
  final String topicName;
  final String moduleName;
  final int rating;
  final int studyCount;
  final int previousRating;
  final GlobalKey boundaryKey;

  const TopicMasteredCard({
    super.key,
    required this.topicName,
    required this.moduleName,
    required this.rating,
    required this.studyCount,
    required this.previousRating,
    required this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 1080,
        height: 1080,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF10B981).withAlpha(30),
              const Color(0xFF10B981).withAlpha(60),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '🏆',
                style: GoogleFonts.outfit(fontSize: 200),
                textAlign: TextAlign.center,
              ),
              Column(
                children: [
                  Text(
                    'Topic Mastered!',
                    style: GoogleFonts.outfit(
                      color: AppColors.success,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    topicName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    moduleName,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Rating Journey',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$previousRating/10',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '→',
                        style: GoogleFonts.outfit(
                          color: AppColors.primary,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '$rating/10',
                        style: GoogleFonts.outfit(
                          color: AppColors.success,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Studied $studyCount times',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              Text(
                'StudyTrack',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exam Countdown Card - Shows exam dates and readiness
class ExamCountdownCard extends StatelessWidget {
  final String examName;
  final int daysRemaining;
  final double readinessPercent;
  final GlobalKey boundaryKey;
  final bool isUrgent;

  const ExamCountdownCard({
    super.key,
    required this.examName,
    required this.daysRemaining,
    required this.readinessPercent,
    required this.boundaryKey,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradientStart = isUrgent ? AppColors.warning : AppColors.primary;
    final gradientEnd = isUrgent
        ? AppColors.warning.withAlpha(200)
        : AppColors.primary.withAlpha(200);

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 1080,
        height: 1080,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox.shrink(),
              Column(
                children: [
                  Text(
                    'Countdown',
                    style: GoogleFonts.inter(
                      color: Colors.white.withAlpha(180),
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '$daysRemaining',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 180,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'days left',
                    style: GoogleFonts.inter(
                      color: Colors.white.withAlpha(180),
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    examName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: 32,
                          width: 1080 * (readinessPercent / 100) - 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${readinessPercent.toStringAsFixed(0)}% Ready',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'StudyTrack',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streak Card - Celebrates study streaks
class StreakCard extends StatelessWidget {
  final String studentName;
  final int streakCount;
  final GlobalKey boundaryKey;

  const StreakCard({
    super.key,
    required this.studentName,
    required this.streakCount,
    required this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 1080,
        height: 1080,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1A),
              const Color(0xFF16213E),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '🔥',
                    style: GoogleFonts.outfit(fontSize: 160),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Keep it going!',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFF59E0B),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '$streakCount',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 200,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Column(
                children: [
                  Text(
                    'Day Streak',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    studentName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'StudyTrack',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
