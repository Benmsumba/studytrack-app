import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LoadingWidget extends StatefulWidget {
  final String? label;
  final double size;

  const LoadingWidget({
    super.key,
    this.label,
    this.size = 50,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonViolet.withValues(alpha: 0.3),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(widget.size / 2),
              ),
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.neonCyan.withValues(alpha: 0.8),
                    ),
                    strokeWidth: 3,
                  ),
                  Positioned(
                    right: 0,
                    top: widget.size / 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonViolet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
