import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

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

class _StudySessionScreenState extends State<StudySessionScreen> {
  final SupabaseService _service = SupabaseService();
  late final ConfettiController _confettiController;

  Timer? _timer;
  bool _isRunning = false;
  bool _isBreakMode = false;

  int _studyDurationMinutes = 25;
  static const int _breakDurationMinutes = 5;

  late int _totalSeconds;
  late int _remainingSeconds;
  DateTime? _startTimestamp;

  String _topicName = 'Focus Session';
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _totalSeconds = _studyDurationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _topicName = widget.topicName ?? 'Focus Session';
    _resolveTopicName();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _resolveTopicName() async {
    final topicId = widget.topicId;
    if (topicId == null || topicId.isEmpty || widget.topicName != null) {
      return;
    }

    final topic = await _service.client
        .from('topics')
        .select('name')
        .eq('id', topicId)
        .maybeSingle();

    final name = topic?['name']?.toString();
    if (!mounted || name == null || name.isEmpty) return;
    setState(() {
      _topicName = name;
    });
  }

  void _setStudyDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _studyDurationMinutes = minutes;
      _isBreakMode = false;
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _startTimer() {
    if (_isRunning) return;

    _startTimestamp ??= DateTime.now();
    setState(() {
      _isRunning = true;
    });

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
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreakMode = false;
      _startTimestamp = null;
      _totalSeconds = _studyDurationMinutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _startBreak() {
    _timer?.cancel();
    setState(() {
      _isBreakMode = true;
      _isRunning = false;
      _totalSeconds = _breakDurationMinutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  Future<void> _showRatingDialog() async {
    double tempRating = 7;

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text(
                'How well do you understand this now?',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tempRating.round()}/10',
                    style: GoogleFonts.outfit(
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
                  onPressed: () =>
                      Navigator.of(context).pop(tempRating.round()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Save Rating'),
                ),
              ],
            );
          },
        );
      },
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

    final sessionId = widget.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      await _service.updateSessionStatus(
        sessionId,
        'completed',
        elapsedMinutes,
      );
    }

    final topicId = widget.topicId;
    if (topicId != null && topicId.isNotEmpty) {
      await _service.updateTopicRating(topicId, rating);
    }

    _confettiController.play();
    if (!mounted) return;
    setState(() {
      _isCompleting = false;
    });

    await _showInfoDialog('Great session! Your progress has been saved.');
  }

  Future<void> _showInfoDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'StudyTrack',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
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

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0
        ? 0.0
        : _remainingSeconds / _totalSeconds;
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isBreakMode ? 'Break Time' : 'Study Session',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                Text(
                  _topicName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isBreakMode ? 'Recharge for 5 minutes' : 'Deep focus mode',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween<double>(begin: 0, end: progress),
                        builder: (context, value, _) {
                          return SizedBox(
                            width: 240,
                            height: 240,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 12,
                              color: _isBreakMode
                                  ? AppColors.accent
                                  : AppColors.primary,
                              backgroundColor: AppColors.border,
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$minutes:$seconds',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _isRunning ? 'In progress' : 'Paused',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final minutes in [15, 20, 25, 30, 45])
                      ChoiceChip(
                        label: Text('$minutes min'),
                        selected:
                            _studyDurationMinutes == minutes && !_isBreakMode,
                        onSelected: (_) => _setStudyDuration(minutes),
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.25,
                        ),
                        labelStyle: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.cardDark,
                        side: const BorderSide(color: AppColors.border),
                      ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.replay),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? _pauseTimer : _startTimer,
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRunning ? 'Pause' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _startBreak,
                    icon: const Icon(Icons.free_breakfast_outlined),
                    label: const Text('Take a break (5 min)'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                  ),
                ),
                if (_isCompleting)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          ConfettiWidget(
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
        ],
      ),
    );
  }
}
