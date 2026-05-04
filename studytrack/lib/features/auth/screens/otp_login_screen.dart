import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_provider.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  // Two-step: first collect email, then collect code.
  bool _codeSent = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.sendOtp(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      setState(() => _codeSent = true);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Future<void> _verifyCode() async {
    if (!_otpFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.verifyOtpCode(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      context.go('/home');
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  void _goBack() {
    if (_codeSent) {
      setState(() {
        _codeSent = false;
        _otpController.clear();
        _errorMessage = null;
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.screenVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: _goBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Header
            _buildHeader(),
            const SizedBox(height: AppSpacing.xxxl),

            // Body
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _codeSent
                  ? _OtpStep(
                      key: const ValueKey('otp'),
                      formKey: _otpFormKey,
                      otpController: _otpController,
                      email: _emailController.text.trim(),
                      loading: _loading,
                      errorMessage: _errorMessage,
                      onVerify: _verifyCode,
                      onResend: () {
                        setState(() {
                          _codeSent = false;
                          _otpController.clear();
                        });
                      },
                    )
                  : _EmailStep(
                      key: const ValueKey('email'),
                      formKey: _emailFormKey,
                      emailController: _emailController,
                      loading: _loading,
                      errorMessage: _errorMessage,
                      onSend: _sendCode,
                    ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Back to password login
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Sign in with password instead',
                  style: AppTextStyles.bodyMediumSecondary.copyWith(
                    color: AppColors.neonCyan,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Animated icon
      Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.violetGlowSoft,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_unread_rounded,
              color: Colors.white,
              size: 28,
            ),
          )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
      const SizedBox(height: AppSpacing.lg),
      Text(
        _codeSent ? 'Check your inbox' : 'Sign in with email',
        style: AppTextStyles.headingLarge,
      ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
      const SizedBox(height: AppSpacing.sm),
      Text(
        _codeSent
            ? 'We sent a 6-digit code to ${_emailController.text.trim()}.'
            : "Enter your email and we'll send you a one-time code. No password needed.",
        style: AppTextStyles.bodyMediumSecondary,
      ).animate().fadeIn(delay: 180.ms, duration: 350.ms),
    ],
  );
}

// ---------------------------------------------------------------------------
// Step 1 — email input
// ---------------------------------------------------------------------------

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    required this.formKey,
    required this.emailController,
    required this.loading,
    required this.errorMessage,
    required this.onSend,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSend(),
          validator: Validators.email,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            label: 'Email address',
            icon: Icons.email_outlined,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorMessage!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _GradientButton(
          label: 'Send code',
          loading: loading,
          onTap: loading ? null : onSend,
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Step 2 — OTP input
// ---------------------------------------------------------------------------

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.formKey,
    required this.otpController,
    required this.email,
    required this.loading,
    required this.errorMessage,
    required this.onVerify,
    required this.onResend,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final String email;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onFieldSubmitted: (_) => onVerify(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter the 6-digit code.';
            if (v.trim().length < 6) return 'Code must be 6 digits.';
            return null;
          },
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 8,
          ),
          textAlign: TextAlign.center,
          decoration: _inputDecoration(
            label: '6-digit code',
            icon: Icons.pin_rounded,
          ),
          autofocus: true,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorMessage!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _GradientButton(
          label: 'Verify & sign in',
          loading: loading,
          onTap: loading ? null : onVerify,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: loading ? null : onResend,
            child: Text(
              "Didn't receive it? Resend code",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
}) => InputDecoration(
  labelText: label,
  hintText: label,
  prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 20),
  filled: true,
  fillColor: AppColors.cardDark,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.neonCyan),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.danger),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.danger),
  ),
  labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
);

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onTap == null ? 0.7 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
        ),
      ),
    ),
  );
}
