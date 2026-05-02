import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    required this.label,
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.width,
    this.height = 54,
    this.borderRadius = AppSpacing.buttonRadius,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    this.textStyle,
    this.glowColor,
    this.enableHaptics = true,
    this.icon,
    this.trailingIcon,
    this.showPressScale = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final LinearGradient? gradient;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final Color? glowColor;
  final bool enableHaptics;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool showPressScale;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    if (widget.enableHaptics) {
      await HapticFeedback.lightImpact();
    }

    widget.onPressed?.call();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppColors.primaryGradient;
    final radius = BorderRadius.circular(widget.borderRadius);

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: widget.showPressScale && _isPressed ? 0.98 : 1,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: (widget.glowColor ?? AppColors.violetGlow).withValues(
                alpha: _isPressed ? 0.72 : 0.5,
              ),
              blurRadius: _isPressed ? 28 : 22,
              spreadRadius: _isPressed ? 1.5 : 0.5,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: AppColors.cyanGlowSoft,
              blurRadius: 12,
              spreadRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : _handleTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: radius,
            splashColor: AppColors.neonCyan.withValues(alpha: 0.22),
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: gradient,
              ),
              child: Padding(
                padding: widget.padding,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              widget.icon!,
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Text(
                              widget.label,
                              style: widget.textStyle ?? AppTextStyles.button,
                            ),
                            if (widget.trailingIcon != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              widget.trailingIcon!,
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlowingButton extends CustomButton {
  const GlowingButton({
    required super.label,
    super.key,
    super.onPressed,
    super.isLoading,
    super.gradient = AppColors.primaryGradient,
    super.width,
    super.height = 56,
    super.borderRadius = AppSpacing.buttonRadius,
    super.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    super.textStyle,
    super.glowColor = AppColors.neonViolet,
    super.enableHaptics,
    super.icon,
    super.trailingIcon,
    super.showPressScale,
  });
}
