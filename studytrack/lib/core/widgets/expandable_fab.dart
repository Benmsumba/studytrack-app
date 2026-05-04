import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

typedef FABAction = ({String label, IconData icon, VoidCallback onTap});

class ExpandableFAB extends StatefulWidget {
  const ExpandableFAB({
    required this.actions,
    this.heroTag = 'expandable_fab',
    super.key,
  });

  final List<FABAction> actions;
  final String heroTag;

  @override
  State<ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isExpanded) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_isExpanded)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
            child: Column(
              children: List.generate(widget.actions.length, (index) {
                final delay = (widget.actions.length - index - 1) * 80.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              delay / 300,
                              1,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                    child: _FABAction(
                      action: widget.actions[index],
                      onTap: () {
                        widget.actions[index].onTap();
                        _toggle();
                      },
                    ),
                  ),
                );
              }).reversed.toList(),
            ),
          ),
        ),
      FloatingActionButton(
        heroTag: widget.heroTag,
        backgroundColor: AppColors.neonViolet,
        onPressed: _toggle,
        child: RotationTransition(
          turns: Tween<double>(begin: 0, end: 0.125).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    ],
  );
}

class _FABAction extends StatelessWidget {
  const _FABAction({required this.action, required this.onTap});

  final FABAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            action.label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        FloatingActionButton(
          mini: true,
          backgroundColor: AppColors.neonCyan,
          onPressed: onTap,
          child: Icon(action.icon, color: Colors.white, size: 18),
        ),
      ],
    ),
  );
}
