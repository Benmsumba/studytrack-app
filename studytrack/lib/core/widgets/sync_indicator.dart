import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({
    this.isSynced = true,
    this.showLabel = true,
    this.size = 12,
    super.key,
  });

  final bool isSynced;
  final bool showLabel;
  final double size;

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (!widget.isSynced) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSynced != oldWidget.isSynced) {
      if (widget.isSynced) {
        _animationController.stop();
      } else {
        _animationController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.isSynced)
        Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
          ),
        )
      else
        ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.2).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning,
            ),
          ),
        ),
      if (widget.showLabel) ...[
        const SizedBox(width: 8),
        Text(
          widget.isSynced ? 'Synced' : 'Syncing...',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: widget.isSynced ? AppColors.success : AppColors.warning,
          ),
        ),
      ],
    ],
  );
}
