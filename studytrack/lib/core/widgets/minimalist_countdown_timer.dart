import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class MinimalistCountdownTimer extends StatefulWidget {
  const MinimalistCountdownTimer({
    required this.duration,
    required this.onTick,
    required this.onComplete,
    this.size = 200,
    this.isRunning = false,
    super.key,
  });

  final Duration duration;
  final void Function(Duration remaining) onTick;
  final VoidCallback onComplete;
  final double size;
  final bool isRunning;

  @override
  State<MinimalistCountdownTimer> createState() =>
      _MinimalistCountdownTimerState();
}

class _MinimalistCountdownTimerState extends State<MinimalistCountdownTimer>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _remaining;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.isRunning) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(MinimalistCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _startTimer();
      } else {
        _timer.cancel();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining - const Duration(milliseconds: 100);
        if (_remaining.isNegative) {
          _timer.cancel();
          widget.onComplete();
          return;
        }
        widget.onTick(_remaining);
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (widget.isRunning) {
      _timer.cancel();
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final percentage =
        1.0 - (_remaining.inMilliseconds / widget.duration.inMilliseconds);

    return Center(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 3),
                    ),
                  ),
                  // Progress arc
                  CustomPaint(
                    painter: _CountdownArcPainter(
                      progress: percentage,
                      color: AppColors.neonViolet,
                      strokeWidth: 4,
                    ),
                    size: Size(widget.size, widget.size),
                  ),
                  // Timer text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDuration(_remaining),
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (widget.isRunning)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neonViolet.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Focus Mode Active',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neonViolet,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }
}

class _CountdownArcPainter extends CustomPainter {
  _CountdownArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = -3.14159265359 / 2;
    final sweepAngle = 2 * 3.14159265359 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CountdownArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
