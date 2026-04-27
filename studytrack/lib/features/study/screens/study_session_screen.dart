import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  int _seconds = 25 * 60;
  final int _session = 1;
  late AnimationController _pulseController;

  String get _timeDisplay {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1.0 - (_seconds / (25 * 60));

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildHeader(context),
              const Spacer(),
              _buildTimer(),
              const SizedBox(height: 24),
              _buildTopicLabel(),
              const SizedBox(height: 12),
              _buildSessionIndicator(),
              const Spacer(),
              _buildControls(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 22),
        ),
        const Spacer(),
        Text(
          'Study Session',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 22),
      ],
    );
  }

  Widget _buildTimer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, _) {
        final glowOpacity = _isRunning
            ? 0.2 + (_pulseController.value * 0.3)
            : 0.15;
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: glowOpacity),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFF2D2D44),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7C3AED),
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeDisplay,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    _isRunning ? 'Focus' : 'Ready',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicLabel() {
    // TODO: Replace with actual topic data
    const topicName = 'Pharmacokinetics';
    const moduleName = 'Pharmacology';

    return Column(
      children: [
        Text(
          topicName,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'from $moduleName',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Text(
        'Session $_session / 4  •  Focus Mode',
        style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume button
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF16213E),
            border: Border.all(color: const Color(0xFF2D2D44)),
          ),
          child: IconButton(
            icon: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              color: const Color(0xFF7C3AED),
              size: 28,
            ),
            onPressed: () {
              setState(() => _isRunning = !_isRunning);
              // TODO: Implement timer logic
            },
          ),
        ),
        const SizedBox(width: 20),
        // Stop button
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF16213E),
            border: Border.all(color: const Color(0xFF2D2D44)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Color(0xFFF43F5E),
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isRunning = false;
                _seconds = 25 * 60;
              });
              // TODO: Implement stop logic
            },
          ),
        ),
      ],
    );
  }
}
