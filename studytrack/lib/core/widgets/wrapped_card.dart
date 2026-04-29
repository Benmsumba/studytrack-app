import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class WrappedCard extends StatelessWidget {
  const WrappedCard({
    required this.child,
    super.key,
    this.customBorderColors,
    this.padding = 20.0,
    this.enableGlow = true,
    this.glowColor,
  });
  final Widget child;
  final List<Color>? customBorderColors;
  final double padding;
  final bool enableGlow;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: enableGlow
          ? [
              BoxShadow(
                color: glowColor ?? AppColors.violetGlowSoft,
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: AppColors.cyanGlowSoft,
                blurRadius: 16,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: customBorderColors ?? AppColors.borderGradient.colors,
          begin: customBorderColors == null
              ? Alignment.topLeft
              : Alignment.topLeft,
          end: customBorderColors == null
              ? Alignment.bottomRight
              : Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(1.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppColors.cardDark.withValues(alpha: 0.85),
              padding: EdgeInsets.all(padding),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Premium button with gradient and neon glow
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.gradient,
    this.isLoading = false,
    this.width,
  });
  final String label;
  final VoidCallback onPressed;
  final LinearGradient? gradient;
  final bool isLoading;
  final double? width;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  @override
  Widget build(BuildContext context) => Container(
    width: widget.width,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppColors.neonViolet.withValues(alpha: 0.4),
          blurRadius: 16,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: widget.gradient ?? AppColors.primaryGradient,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.label, style: AppTextStyles.button),
          ),
        ),
      ),
    ),
  );
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
  final Function(String)? onChanged;

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
