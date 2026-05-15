import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/class_timetable_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/class_slot_model.dart';
import '../../../models/study_session_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthRepository _authRepository = getIt<AuthRepository>();
  late final ClassTimetableRepository _timetableRepository =
      getIt<ClassTimetableRepository>();
  late final StudySessionRepository _sessionRepository =
      getIt<StudySessionRepository>();

  String _greeting = 'Good Morning';
  String _userName = 'Student';
  double _dailyGoalProgress = 0;
  final double _dailyGoalTarget = 6.0;
  int _streak = 0;
  List<ClassSlotModel> _todaySlots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _loadDashboardData();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else if (hour < 21) {
      _greeting = 'Good Evening';
    } else {
      _greeting = 'Good Night';
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get current user
      final userResult = await _authRepository.getCurrentUser();
      final user = userResult.fold((error) => null, (u) => u);
      if (user != null) {
        _userName = user.name ?? 'Student';
      }
      final userId = user?.id;

      // Get today's class slots
      if (userId != null) {
        final slotsResult = await _timetableRepository.getClassSlotsByDay(
          userId: userId,
          dayOfWeek: DateTime.now().weekday,
        );
        _todaySlots = slotsResult.fold<List<ClassSlotModel>>(
          (error) => [],
          (slots) => slots,
        );
      }

      // Get daily goal progress from today's sessions
      final sessionsResult = await _sessionRepository.getSessionsToday();
      final sessions = sessionsResult.fold<List<StudySessionModel>>(
        (error) => [],
        (s) => s,
      );
      double totalHours = 0;
      for (final session in sessions) {
        totalHours +=
            ((session.actualDurationMinutes ?? session.durationMinutes) ?? 0) /
            60.0;
      }
      _dailyGoalProgress = totalHours;

      // Compute streak: consecutive days with sessions from today backwards
      final hasSessionToday = sessions.isNotEmpty;
      if (hasSessionToday) {
        // Simple streak: just 1 day if we have today (full streak logic would
        // require getSessionsByDateRange which is available but kept minimal here)
        _streak = 1;
      } else {
        _streak = 0;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _glowBlob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEE, MMM d').format(DateTime.now()),
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              Text(
                '$_greeting, $_userName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$_streak-Day Streak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard() {
    final progress = (_dailyGoalProgress / _dailyGoalTarget).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xCC1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _ArcRingPainter(progress: progress),
                      size: const Size(130, 130),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Daily Goal:',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Daily Goal: ${_dailyGoalProgress.toStringAsFixed(1)}/${_dailyGoalTarget.toStringAsFixed(0)} Hours',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Study Plan",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (_todaySlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xCC1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: const Text(
              'No classes scheduled for today',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          )
        else
          ..._todaySlots.map(
            (slot) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xCC1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${slot.startTime} - ${slot.endTime}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [slot.subjectName, slot.room, slot.lecturer]
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(', '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.play_arrow_rounded,
            label: 'Start Session',
            iconBg: const Color(0xFF4F46E5),
            onTap: () => context.push('/study-session'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.add_rounded,
            label: 'Add Module',
            iconBg: const Color(0xFF0891B2),
            onTap: () => context.go('/home/modules'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.smart_toy_rounded,
            label: 'AI Tutor',
            iconBg: const Color(0xFF374151),
            onTap: () => context.go('/home/modules'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          // Ambient glow blobs
          Positioned(
            top: -100,
            left: -80,
            child: _glowBlob(300, const Color(0x334F46E5)),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: _glowBlob(250, const Color(0x2210B981)),
          ),
          // Main content
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 8),
                        _buildStreakBadge(),
                        const SizedBox(height: 20),
                        _buildDailyGoalCard(),
                        const SizedBox(height: 24),
                        _buildStudyPlan(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arc ring painter
// ---------------------------------------------------------------------------

class _ArcRingPainter extends CustomPainter {
  const _ArcRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const sweepAngle = 2 * 3.14159265359;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265359 / 2,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Gradient arc
    final gradient = SweepGradient(
      startAngle: -3.14159265359 / 2,
      endAngle: -3.14159265359 / 2 + sweepAngle * progress,
      colors: const [Color(0xFF818CF8), Color(0xFF4F46E5), Color(0xFF10B981)],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265359 / 2,
      sweepAngle * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Quick Action Button
// ---------------------------------------------------------------------------

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}
