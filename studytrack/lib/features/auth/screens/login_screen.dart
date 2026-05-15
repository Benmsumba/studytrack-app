import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Keep Google sign-in stub — UI button removed per Stitch design.
  Future<void> _onGoogleSignInTap() async {
    final auth = context.read<AuthProvider>();
    try {
      final result = await auth.signInWithGoogle();
      if (!mounted) return;
      if (!result.success) {
        SnackbarHelper.show(context, result.message, type: AppSnackbarType.error);
      }
    } catch (_) {}
  }

  Future<void> _onLoginTap() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await context.read<AuthProvider>().signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      context.go('/home');
      return;
    }

    SnackbarHelper.show(context, result.message, type: AppSnackbarType.error);
  }

  Future<void> _onForgotPasswordTap() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        title: const Text(
          'Reset password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Email address',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send link', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final email = emailController.text.trim();
    if (email.isEmpty) return;

    final result = await context.read<AuthProvider>().resetPassword(email);

    if (!mounted) return;

    SnackbarHelper.show(
      context,
      result.message,
      type: result.success ? AppSnackbarType.success : AppSnackbarType.error,
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
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
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
                    // Welcome heading
                    const Text(
                      'Welcome Back',
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.15, end: 0, duration: 500.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue your study journey',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                    const SizedBox(height: 32),
                    // Glass Card
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
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
                              const SizedBox(height: 14),
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: Validators.requiredField,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: Colors.white54,
                                      size: 20,
                                    ),
                                  ),
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
                              const SizedBox(height: 4),
                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _onForgotPasswordTap,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Login gradient button
                              GestureDetector(
                                onTap: auth.isLoading ? null : _onLoginTap,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: auth.isLoading ? 0.6 : 1.0,
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
                                    child: auth.isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // OTP secondary button
                              GestureDetector(
                                onTap: () => context.push('/otp-login'),
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('Login with OTP', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.12, end: 0, duration: 600.ms),
                    const SizedBox(height: 24),
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(color: Color(0xFF818CF8), fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
