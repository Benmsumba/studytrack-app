import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WrappedCard extends StatelessWidget {
  final Widget child;
  final List<Color>? customBorderColors;
  final double padding;

  const WrappedCard({
    super.key, 
    required this.child, 
    this.customBorderColors,
    this.padding = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // Phase 1.3 requirement
        gradient: LinearGradient(
          colors: customBorderColors ?? [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.01),
          ],
        ),
      ),
      padding: const EdgeInsets.all(1.2), // The 1px "Wrap" border
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: AppColors.cardDark.withValues(alpha: 0.85),
            padding: EdgeInsets.all(padding),
            child: child,
          ),
        ),
      ),
    );
  }
}