import 'dart:async';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/badge_celebration_overlay.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({
    super.key,
    this.topicId,
    this.topicName,
    this.sessionId,
  });

  final String? topicId;
  final String? topicName;
  final String? sessionId;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with WidgetsBindingObserver {
  final StudySessionRepository _studySessionRepository =
      getIt<StudySessionRepository>();
  final TopicRepository _topicRepository = getIt<TopicRepository>();
  late final ConfettiController _confettiController;

  Timer? _timer;
  bool _isRunning = false;
  bool _isBreakMode = false;

  int _studyDurationMinutes = 25;
  static const int _breakDurationMinutes = 5;

  late int _totalSeconds;
  late int _remainingSeconds;

  String _topicName = 'Focus Session';
  bool _isCompleting = false;

  String get _statePrefix =>
      'study_session_${widget.sessionId ?? widget.topicId ?? 'default'}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _totalSeconds = _studyDurationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _topicName = widget.topicName ?? 'Focus Session';
    _restoreSessionState();
    _resolveTopicName();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_persistSessionState());
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_restoreSessionState());
    }
  }

  Future<void> _resolveTopicName() async {
    final topicId = widget.topicId;
    if (topicId == null || topicId.isEmpty || widget.topicName != null) {
      return;
    }

    final result = await _topicRepository.getTopicById(topicId);
    final name = switch (result) {
      Success(data: final topic) => topic?.name,
      Failure() => null,
    };
    if (!mounted || name == null || name.isEmpty) return;
    setState(() {
      _topicName = name;
    });
    unawaited(_persistSessionState());
  }

  Future<void> _restoreSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRemaining = prefs.getInt('${_statePrefix}_remainingSeconds');
    final savedTotal = prefs.getInt('${_statePrefix}_totalSeconds');
    final savedStudyMinutes = prefs.getInt(
      '${_statePrefix}_studyDurationMinutes',
    );
    final savedRunning = prefs.getBool('${_statePrefix}_isRunning') ?? false;
    final savedBreakMode =
        prefs.getBool('${_statePrefix}_isBreakMode') ?? false;
    final savedTopicName = prefs.getString('${_statePrefix}_topicName');
    final savedAt = prefs.getInt('${_statePrefix}_savedAt');

    if (!mounted) return;

    setState(() {
      if (savedStudyMinutes != null && savedStudyMinutes > 0) {
        _studyDurationMinutes = savedStudyMinutes;
      }

      if (savedTotal != null && savedTotal > 0) {
        _totalSeconds = savedTotal;
      }

      if (savedRemaining != null && savedRemaining >= 0) {
        _remainingSeconds = savedRemaining;
      }

      _isBreakMode = savedBreakMode;
      if (savedTopicName != null && savedTopicName.isNotEmpty) {
        _topicName = savedTopicName;
      }
      _isRunning = savedRunning;
    });

    if (_isRunning && savedAt != null) {
      final elapsedSeconds = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(savedAt))
          .inSeconds;
      if (elapsedSeconds > 0) {
        setState(() {
          _remainingSeconds = (_remainingSeconds - elapsedSeconds).clamp(
            0,
            _totalSeconds,
          );
        });
      }
    }

    if (_isRunning && _remainingSeconds > 0) {
      _startTimer();
    } else if (_isRunning && _remainingSeconds == 0) {
      _isRunning = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_showRatingDialog());
        }
      });
    }
  }

  void _setStudyDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _studyDurationMinutes = minutes;
      _isBreakMode = false;
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
    });
    unawaited(_persistSessionState());
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });
    unawaited(_persistSessionState());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });

        if (_isBreakMode) {
          _showInfoDialog('Break complete. Ready for your next focus session?');
        } else {
          _showRatingDialog();
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _remainingSeconds -= 1;
      });
      unawaited(_persistSessionState());
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    unawaited(_persistSessionState());
  }

  // _pauseResume is used by the UI buttons
  void _pauseResume() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreakMode = false;
      _totalSeconds = _studyDurationMinutes * 60;
      _remainingSeconds = _totalSeconds;
    });
    unawaited(_clearSessionState());
  }

  // _stopSession is used by the Stop button
  void _stopSession() {
    _resetTimer();
  }

  void _startBreak() {
    _timer?.cancel();
    setState(() {
      _isBreakMode = true;
      _isRunning = false;
      _totalSeconds = _breakDurationMinutes * 60;
      _remainingSeconds = _totalSeconds;
    });
    unawaited(_persistSessionState());
  }

  Future<void> _persistSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '${_statePrefix}_studyDurationMinutes',
      _studyDurationMinutes,
    );
    await prefs.setInt('${_statePrefix}_totalSeconds', _totalSeconds);
    await prefs.setInt('${_statePrefix}_remainingSeconds', _remainingSeconds);
    await prefs.setBool('${_statePrefix}_isRunning', _isRunning);
    await prefs.setBool('${_statePrefix}_isBreakMode', _isBreakMode);
    await prefs.setString('${_statePrefix}_topicName', _topicName);
    await prefs.setInt(
      '${_statePrefix}_savedAt',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _clearSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_statePrefix}_studyDurationMinutes');
    await prefs.remove('${_statePrefix}_totalSeconds');
    await prefs.remove('${_statePrefix}_remainingSeconds');
    await prefs.remove('${_statePrefix}_isRunning');
    await prefs.remove('${_statePrefix}_isBreakMode');
    await prefs.remove('${_statePrefix}_topicName');
    await prefs.remove('${_statePrefix}_savedAt');
  }

  Future<void> _showRatingDialog() async {
    double tempRating = 7;

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'How well do you understand this now?',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tempRating.round()}/10',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Slider(
                value: tempRating,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                label: tempRating.round().toString(),
                onChanged: (value) {
                  setDialogState(() {
                    tempRating = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempRating.round()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save Rating'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _completeSession(result);
    }
  }

  Future<void> _completeSession(int rating) async {
    if (_isCompleting) return;
    setState(() {
      _isCompleting = true;
    });

    final elapsedSeconds = (_totalSeconds - _remainingSeconds).clamp(
      0,
      _totalSeconds,
    );
    final elapsedMinutes = (elapsedSeconds / 60).ceil();

    final achievementService = getIt<AchievementService>();
    final userId = SupabaseService.instance.getCurrentUser()?.id;

    // Snapshot pre-session badges so we can detect newly earned ones.
    final preSessionBadgeTypes = userId == null
        ? <String>{}
        : (await achievementService.getEarnedBadges(
            userId,
          )).map((b) => b.badgeType).toSet();

    final sessionId = widget.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      final sessionResult = await _studySessionRepository.updateSessionStatus(
        sessionId: sessionId,
        status: 'completed',
        actualDurationMinutes: elapsedMinutes,
      );
      if (sessionResult is Failure<void>) {
        if (!mounted) return;
        setState(() {
          _isCompleting = false;
        });
        await _showInfoDialog(sessionResult.error.message);
        return;
      }
    }

    final topicId = widget.topicId;
    if (topicId != null && topicId.isNotEmpty) {
      final ratingResult = await _topicRepository.rateTopic(topicId, rating);
      if (ratingResult is Failure<void>) {
        if (!mounted) return;
        setState(() {
          _isCompleting = false;
        });
        await _showInfoDialog(ratingResult.error.message);
        return;
      }
    }

    Analytics.sessionCompleted(durationMinutes: elapsedMinutes, rating: rating);

    _confettiController.play();
    if (!mounted) return;
    setState(() {
      _isCompleting = false;
    });

    await _showInfoDialog('Great session! Your progress has been saved.');

    // Check for newly earned badges and celebrate each one.
    if (userId != null && mounted) {
      final allBadges = await achievementService.checkAllBadges(userId);
      final newBadges = allBadges
          .where((b) => !preSessionBadgeTypes.contains(b.badgeType))
          .toList();
      for (final badge in newBadges) {
        if (!mounted) break;
        Analytics.badgeEarned(badgeType: badge.badgeType);
        await _showBadgeCelebration(badge.badgeType);
      }
    }

    await _clearSessionState();
  }

  Future<void> _showBadgeCelebration(String badgeType) async {
    if (!mounted) return;
    final titles = <String, String>{
      'first_step': 'First Step',
      'week_warrior': 'Week Warrior',
      'perfectionist': 'Perfectionist',
      'bookworm': 'Bookworm',
      'master': 'Master',
      'month_streak': 'Month Streak',
      'century': 'Century Club',
    };
    final descriptions = <String, String>{
      'first_step': 'You studied your first topic!',
      'week_warrior': 'You maintained a 7-day study streak!',
      'perfectionist': 'You rated a topic 10/10!',
      'bookworm': 'You have studied 50 topics!',
      'master': 'You rated 10 topics 8+/10!',
      'month_streak': 'You maintained a 30-day study streak!',
      'century': 'You have 100 topics across all modules!',
    };
    final title = titles[badgeType] ?? badgeType;
    final description = descriptions[badgeType] ?? 'Badge earned!';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BadgeCelebrationOverlay(
        badgeTitle: title,
        badgeDescription: description,
        onDismiss: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  }

  Future<void> _showInfoDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'StudyTrack',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(message, style: AppTextStyles.bodyMediumSecondary),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color, Colors.transparent],
      ),
    ),
  );

  Widget _buildTimerCircle() {
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds
        : 0.0;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glass circle background
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          // Emerald arc ring
          CustomPaint(
            painter: _TimerRingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: const Color(0xFF10B981),
            ),
            size: const Size(260, 260),
          ),
          // Time text
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // Background glow blobs
          Positioned(
            top: -50,
            right: -50,
            child: _glowBlob(200, const Color(0x2210B981)),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: _glowBlob(250, const Color(0x224F46E5)),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Topic label
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Text(
                    'Topic: $_topicName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Duration chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final minutes in [15, 20, 25, 30, 45])
                        GestureDetector(
                          onTap: () => _setStudyDuration(minutes),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _studyDurationMinutes == minutes &&
                                      !_isBreakMode
                                  ? const Color(0xFF4F46E5).withValues(
                                      alpha: 0.3,
                                    )
                                  : Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _studyDurationMinutes == minutes &&
                                        !_isBreakMode
                                    ? const Color(0xFF4F46E5)
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              '$minutes min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Large timer circle (centered, takes remaining space)
                Expanded(
                  child: Center(child: _buildTimerCircle()),
                ),
                // Status label
                if (_isCompleting)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          color: AppColors.accent,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Saving progress...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Break button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: GestureDetector(
                    onTap: _startBreak,
                    child: Text(
                      _isBreakMode
                          ? 'Break mode active (5 min)'
                          : 'Take a break (5 min)',
                      style: TextStyle(
                        color: AppColors.accent.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Control buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Row(
                    children: [
                      // Pause/Resume
                      Expanded(
                        child: GestureDetector(
                          onTap: _isCompleting ? null : _pauseResume,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF).withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: const Color(0xFF93C5FD),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isRunning ? 'Pause' : 'Resume',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Stop
                      Expanded(
                        child: GestureDetector(
                          onTap: _isCompleting ? null : _stopSession,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF991B1B).withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.stop_rounded,
                                  color: Color(0xFFFCA5A5),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Stop',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppColors.primary,
                AppColors.accent,
                AppColors.success,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const pi = 3.14159265359;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    if (progress <= 0) return;
    // Glow effect — draw thicker, dimmer arc first
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 20
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Main arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) => old.progress != progress;
}
