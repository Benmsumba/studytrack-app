import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/weekly_report_repository.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/app_state_view.dart';

class WeeklyWrappedScreen extends StatefulWidget {
  const WeeklyWrappedScreen({super.key});

  @override
  State<WeeklyWrappedScreen> createState() => _WeeklyWrappedScreenState();
}

class _WeeklyWrappedScreenState extends State<WeeklyWrappedScreen> {
  late final WeeklyReportRepository _weeklyReportRepository;
  late final ProfileRepository _profileRepository;
  final GeminiService _gemini = GeminiService();
  final PageController _pageController = PageController();
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _loading = true;
  bool _generating = false;
  bool _hasGeneratedThisWeek = false;
  String? _loadError;

  String studentName = 'Student';
  String weekDateRange = '';
  int topicsStudied = 0;
  int _lastWeekTopics = 0;
  double averageRating = 0;
  String bestSubject = 'No data yet';
  String weakestSubject = 'No data yet';
  int streak = 0;
  int sessionsCompleted = 0;
  int sessionsPlanned = 0;
  String aiSummary = 'You are building strong consistency. Keep going!';

  @override
  void initState() {
    super.initState();
    _weeklyReportRepository = getIt<WeeklyReportRepository>();
    _profileRepository = getIt<ProfileRepository>();
    _loadWeeklyWrapped();
  }

  Future<void> _loadWeeklyWrapped() async {
    _loadError = null;
    try {
      // Fetch profile from repository
      final profileResult = await _profileRepository.getCurrentProfile();
      profileResult.fold(
        (error) {
          studentName = 'Student';
          streak = 0;
          _loadError = 'We could not load your weekly wrap right now.';
        },
        (profile) {
          studentName = (profile?['name'] as String?)?.trim().isNotEmpty == true
              ? (profile?['name'] as String)
              : 'Student';
          streak = (profile?['streak_count'] as num?)?.toInt() ?? 0;
        },
      );

      // Fetch weekly reports from repository
      final reportsResult = await _weeklyReportRepository.getWeeklyReports(2);

      reportsResult.fold(
        (error) {
          debugPrint('Failed to load weekly reports: ${error.message}');
          _loadError = 'We could not load your weekly wrap right now.';
          if (mounted) {
            setState(() => _loading = false);
          }
        },
        (reports) {
          if (reports.isEmpty) {
            if (mounted) {
              setState(() {
                _loadError = null;
                _loading = false;
              });
            }
            return;
          }

          final current = reports.first;
          final previous = reports.length > 1 ? reports[1] : null;

          weekDateRange = _resolveWeekRange(current);

          topicsStudied = current.topicsStudied;
          _lastWeekTopics = previous?.topicsStudied ?? 0;
          averageRating = (current.averageRating ?? 0).clamp(0, 10);
          bestSubject = 'No data yet'; // Not available in WeeklyReportModel
          weakestSubject = 'No data yet'; // Not available in WeeklyReportModel
          sessionsCompleted = current.sessionsCompleted;
          sessionsPlanned = current.sessionsPlanned;

          _hasGeneratedThisWeek =
              (current.aiSummary?.isNotEmpty ?? false) &&
              (current.aiSummary != 'Keep your momentum this week.');
          if (_hasGeneratedThisWeek && current.aiSummary != null) {
            aiSummary = current.aiSummary!;
          } else {
            final lastWeekTopics = previous?.topicsStudied ?? 0;
            final diff = topicsStudied - lastWeekTopics;
            final trend = diff >= 0
                ? 'You covered $diff more topics than last week.'
                : 'You covered ${diff.abs()} fewer topics than last week.';
            aiSummary =
                'This week you studied $topicsStudied topics with an average rating of ${averageRating.toStringAsFixed(1)}/10. $trend';
          }

          if (mounted) {
            setState(() {
              _loadError = null;
              _loading = false;
            });
          }
        },
      );
    } catch (error) {
      debugPrint('WeeklyWrapped load error: $error');
      if (mounted) {
        setState(() {
          _loadError = 'We could not load your weekly wrap right now.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _regenerateSummary() async {
    if (_generating || _hasGeneratedThisWeek) return;
    setState(() => _generating = true);
    try {
      final generated = await _gemini.generateWeeklyWrappedSummary(
        studentName: studentName,
        topicsStudied: topicsStudied,
        averageRating: averageRating,
        bestSubject: bestSubject,
        weakestSubject: weakestSubject,
        streak: streak,
        sessionsCompleted: sessionsCompleted,
        sessionsMissed: (sessionsPlanned - sessionsCompleted).clamp(0, 999),
      );
      if (generated.trim().isNotEmpty) {
        setState(() {
          aiSummary = generated.trim();
          _hasGeneratedThisWeek = true;
        });
      }
    } catch (error) {
      debugPrint('WeeklyWrapped regenerate error: $error');
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<Uint8List?> _captureShareCard() async =>
      _screenshotController.capture(pixelRatio: 2.5);

  Future<void> _saveToGallery() async {
    final bytes = await _captureShareCard();
    if (bytes == null) return;
    await Gal.putImageBytes(bytes, name: 'studytrack_weekly_wrapped');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved to gallery')));
  }

  Future<void> _shareToWhatsApp() async {
    final bytes = await _captureShareCard();
    if (bytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/studytrack_wrapped.png');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'My StudyTrack Weekly Wrapped 🚀',
      ),
    );
  }

  String _streakMessage() {
    if (streak <= 3) return "You're getting started!";
    if (streak <= 7) return 'Building momentum 🔥';
    if (streak <= 14) return 'You are on fire! 🔥🔥';
    return 'Unstoppable! 🔥🔥🔥';
  }

  String _topicsDeltaText() {
    final diff = topicsStudied - _lastWeekTopics;
    if (diff == 0) {
      return 'No change from last week';
    }
    final icon = diff > 0 ? '▲' : '▼';
    final word = diff.abs() == 1 ? 'topic' : 'topics';
    final direction = diff > 0 ? 'more' : 'fewer';
    return '$icon ${diff.abs()} $word $direction than last week';
  }

  Color _topicsDeltaColor() {
    final diff = topicsStudied - _lastWeekTopics;
    if (diff > 0) return AppColors.success;
    if (diff < 0) return AppColors.danger;
    return Colors.white70;
  }

  String _resolveWeekRange(dynamic report) {
    if (report == null) {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${_fmtDate(start)} - ${_fmtDate(end)}';
    }

    DateTime? start;
    DateTime? end;

    if (report is Map<String, dynamic>) {
      final startRaw = report['week_start']?.toString();
      final endRaw = report['week_end']?.toString();
      start = startRaw != null ? DateTime.tryParse(startRaw) : null;
      end = endRaw != null ? DateTime.tryParse(endRaw) : null;
    } else {
      // Assume it's a WeeklyReportModel
      start = (report as dynamic).weekStart as DateTime?;
      end = (report as dynamic).weekEnd as DateTime?;
    }

    if (start == null || end == null) {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: now.weekday - 1));
      final endDate = startDate.add(const Duration(days: 6));
      return '${_fmtDate(startDate)} - ${_fmtDate(endDate)}';
    }

    return '${_fmtDate(start)} - ${_fmtDate(end)}';
  }

  String _fmtDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: AppStateView.loadingList(itemCount: 4, itemHeight: 110),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: AppStateView.error(
          title: 'Weekly wrap unavailable',
          message: _loadError!,
          onRetry: _loadWeeklyWrapped,
        ),
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          _animatedPage(index: 0, child: _introPage()),
          _animatedPage(index: 1, child: _topicsPage()),
          _animatedPage(index: 2, child: _bestSubjectPage()),
          _animatedPage(index: 3, child: _needsAttentionPage()),
          _animatedPage(index: 4, child: _streakPage()),
          _animatedPage(index: 5, child: _sessionsPage()),
          _animatedPage(index: 6, child: _aiSummaryPage()),
          _animatedPage(index: 7, child: _finalSharePage()),
        ],
      ),
    );
  }

  Widget _animatedPage({required int index, required Widget child}) =>
      AnimatedBuilder(
        animation: _pageController,
        builder: (context, _) {
          var currentPage = 0.0;
          if (_pageController.hasClients) {
            final rawPage = _pageController.page;
            currentPage = rawPage ?? _pageController.initialPage.toDouble();
          }

          final delta = (currentPage - index).abs().clamp(0.0, 1.0);
          final scale = 1.0 - (delta * 0.08);
          final opacity = 1.0 - (delta * 0.35);

          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
      );

  Widget _introPage() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7C3AED), Color(0xFF0F0F1A)],
      ),
    ),
    child: SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: _hasGeneratedThisWeek
                ? const SizedBox.shrink()
                : FilledButton.icon(
                    onPressed: _regenerateSummary,
                    icon: _generating
                        ? const Icon(Icons.hourglass_top_rounded, size: 14)
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      'Generate',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                      Icons.star_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 70,
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 700.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.08, 1.08),
                      duration: 1400.ms,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.08, 1.08),
                      end: const Offset(0.95, 0.95),
                      duration: 1400.ms,
                    ),
                const SizedBox(height: 20),
                Text(
                  'Your Week in Review',
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  weekDateRange,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  studentName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Swipe up to see ↑',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _topicsPage() => _solidPage(
    color: const Color(0xFF06B6D4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
              '$topicsStudied',
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 110,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
            .animate()
            .fadeIn(duration: 450.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        Text(
          'topics covered',
          style: AppTextStyles.headingSmall.copyWith(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        Text(
          'this week',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _topicsDeltaText(),
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color: _topicsDeltaColor(),
          ),
        ),
      ],
    ),
  );

  Widget _bestSubjectPage() => _gradientPage(
    colors: const [Color(0xFF7C3AED), Color(0xFF1F1B4D)],
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏆', style: TextStyle(fontSize: 66)),
        const SizedBox(height: 12),
        Text(
          'Your strongest subject',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          bestSubject,
          style: AppTextStyles.headingLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 40,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Avg rating ${averageRating.toStringAsFixed(1)} / 10',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final threshold = (index + 1) * 2;
            final active = averageRating >= threshold;
            return Icon(
              active ? Icons.star_rounded : Icons.star_outline_rounded,
              color: active ? Colors.amber : Colors.white54,
              size: 20,
            );
          }),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 220,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween<double>(
              begin: 0,
              end: (averageRating / 10).clamp(0, 1),
            ),
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _needsAttentionPage() => _gradientPage(
    colors: const [Color(0xFFF59E0B), Color(0xFF4D2E07)],
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('⚠️', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 10),
        Text(
          'Needs more love',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white70,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          weakestSubject,
          style: AppTextStyles.headingLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 38,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Text(
          'You’ve got this 💪',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );

  Widget _streakPage() => _solidPage(
    color: const Color(0xFF121224),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 70)),
        const SizedBox(height: 12),
        Text(
          '$streak',
          style: AppTextStyles.displayLarge.copyWith(
            color: Colors.white,
            fontSize: 92,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'day streak',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _streakMessage(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );

  Widget _sessionsPage() {
    final completed = sessionsCompleted;
    final planned = sessionsPlanned <= 0 ? sessionsCompleted : sessionsPlanned;
    final percent = planned == 0 ? 0.0 : completed / planned;

    return _solidPage(
      color: const Color(0xFF124A4F),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$completed of $planned sessions completed',
            style: AppTextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 12,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Missed: ${(planned - completed).clamp(0, 999)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiSummaryPage() => _solidPage(
    color: const Color(0xFF0F0F1A),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.psychology_alt_rounded,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 18),
          Text(
            '“',
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              fontSize: 46,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 1800),
            tween: Tween<int>(
              begin: 0,
              end: aiSummary.split(RegExp(r'\s+')).length,
            ),
            builder: (context, visibleWordCount, child) {
              final words = aiSummary.split(RegExp(r'\s+'));
              final safeCount = visibleWordCount.clamp(0, words.length);
              final partial = words.take(safeCount).join(' ');
              return Text(
                partial,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _finalSharePage() => _solidPage(
    color: const Color(0xFF121224),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'StudyTrack Weekly Wrapped',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          studentName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weekDateRange,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _shareStat('Topics', '$topicsStudied'),
                            _shareStat('Avg', averageRating.toStringAsFixed(1)),
                            _shareStat('Streak', '$streak'),
                            _shareStat(
                              'Sessions',
                              '$sessionsCompleted/$sessionsPlanned',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            'studytrack',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _shareToWhatsApp,
                            icon: const Icon(Icons.share),
                            label: const Text('Share to WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saveToGallery,
                            icon: const Icon(Icons.download),
                            label: const Text('Save to Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _shareStat(String label, String value) {
    final statWidth = MediaQuery.sizeOf(context).width > 600 ? 120.0 : 100.0;
    return Container(
      width: statWidth,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _solidPage({required Color color, required Widget child}) => Container(
    color: color,
    child: SafeArea(child: child),
  );

  Widget _gradientPage({required List<Color> colors, required Widget child}) =>
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: SafeArea(child: child),
      );
}
