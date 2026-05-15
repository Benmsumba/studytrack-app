import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_provider.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _emailController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  // Two-step: first collect email, then collect code.
  bool _codeSent = false;
  bool _loading = false;
  String? _errorMessage;

  // OTP digit boxes state
  String _otpValue = '';
  final FocusNode _otpFocusNode = FocusNode();

  // Countdown timer
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _resendSeconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
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
      setState(() {
        _codeSent = true;
        _otpValue = '';
      });
      _startResendTimer();
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Future<void> _verifyCode() async {
    if (_otpValue.length < 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code.');
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.verifyOtpCode(
      email: _emailController.text.trim(),
      otp: _otpValue,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      context.go('/home');
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _otpValue = '';
      _errorMessage = null;
    });
    await _sendCode();
  }

  Widget _buildOtpBoxes() {
    return GestureDetector(
      onTap: () => _otpFocusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden input
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (v) => setState(() => _otpValue = v),
                autofocus: true,
              ),
            ),
          ),
          // 6 visual boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final char = i < _otpValue.length ? _otpValue[i] : '';
              final isActive = i == _otpValue.length && _otpFocusNode.hasFocus;
              return Container(
                width: 48,
                height: 58,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF4F46E5)
                        : Colors.white.withValues(alpha: 0.2),
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          const BoxShadow(
                            color: Color(0x554F46E5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  char,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0A1A), Color(0xFF1E0F55), Color(0xFF071A12)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button row
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (_codeSent) {
                        setState(() {
                          _codeSent = false;
                          _otpValue = '';
                          _errorMessage = null;
                          _resendTimer?.cancel();
                        });
                      } else {
                        context.pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 16),
                // Logo + App name
                Column(
                  children: [
                    const Icon(Icons.auto_stories_rounded, color: Color(0xFF818CF8), size: 26),
                    const SizedBox(height: 8),
                    const Text(
                      'StudyTrack',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 500.ms),
                const SizedBox(height: 28),

                if (!_codeSent) _buildEmailStep() else _buildOtpStep(),

                const SizedBox(height: 16),
                // Back to password login
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Sign in with password instead',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        // Glass card
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xCC1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Form(
                key: _emailFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter your email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We'll send you a one-time code. No password needed.",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _loading ? null : _sendCode(),
                      validator: Validators.email,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Email address',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54, size: 20),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.07),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
                        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _loading ? null : _sendCode,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _loading ? 0.6 : 1.0,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Send Code', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.12, end: 0, duration: 600.ms),
      ],
    );
  }

  Widget _buildOtpStep() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xCC1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'OTP Verification',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to ${_emailController.text.trim()}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildOtpBoxes(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              // Timer / Resend
              Center(
                child: _resendSeconds > 0
                    ? Text(
                        '⏱ Resend Code in 0:${_resendSeconds.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                      )
                    : GestureDetector(
                        onTap: _loading ? null : _resendCode,
                        child: const Text(
                          'Resend Code',
                          style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _loading ? null : _verifyCode,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _loading ? 0.6 : 1.0,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.12, end: 0, duration: 600.ms);
  }
}
