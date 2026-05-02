import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'custom_button.dart';
import 'glass_card.dart';

class WrappedCard extends GlassCard {
  const WrappedCard({
    required super.child,
    super.key,
    this.customBorderColors,
    super.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    super.enableGlow = true,
    this.glowColor,
  }) : super(borderColors: customBorderColors, glowColor: glowColor);

  final List<Color>? customBorderColors;
  @override
  final Color? glowColor;
}

/// Premium button with gradient and neon glow
class PremiumButton extends GlowingButton {
  const PremiumButton({
    required super.label,
    required super.onPressed,
    super.key,
    super.gradient,
    super.isLoading,
    super.width,
    super.height,
    super.borderRadius,
    super.padding,
    super.textStyle,
    super.glowColor,
    super.enableHaptics,
    super.icon,
    super.trailingIcon,
    super.showPressScale,
  });
}

/// Premium input field with gradient border and neon focus state
class PremiumTextField extends StatefulWidget {
  const PremiumTextField({
    required this.label,
    required this.controller,
    super.key,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label, style: AppTextStyles.label),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused ? AppColors.neonCyan : AppColors.border,
            width: _isFocused ? 2 : 1.5,
          ),
          boxShadow: _isFocused
              ? [
                  const BoxShadow(
                    color: AppColors.cyanGlow,
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.bodyMediumSecondary,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ),
    ],
  );
}
