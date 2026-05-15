import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // Always true so sign-up logic works without the checkbox UI
  final bool _acceptedTerms = true;

  // Keep Google stub — UI button removed per Stitch design.
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccountTap() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      SnackbarHelper.show(context, 'Please accept terms and conditions.', type: AppSnackbarType.warning);
      return;
    }

    final result = await context.read<AuthProvider>().signUpWithEmail(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      if (context.read<AuthProvider>().isAuthenticated) {
        context.go('/onboarding');
      } else {
        SnackbarHelper.show(
          context,
          'Account created. Check your email to verify your account, then login.',
          type: AppSnackbarType.success,
        );
        context.go('/login');
      }
      return;
    }

    SnackbarHelper.show(context, result.message, type: AppSnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // Radial glow blob
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x554F46E5), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, duration: 500.ms),
                    const SizedBox(height: 24),
                    // Glass card with form
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
                              // Full Name
                              TextFormField(
                                controller: _nameController,
                                validator: Validators.requiredField,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Full Name',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white54, size: 20),
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
                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.email,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Email Address',
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
                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: Validators.password,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white54, size: 20),
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
                              const SizedBox(height: 14),
                              // Confirm Password
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Confirm Password',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white54, size: 20),
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
                              const SizedBox(height: 8),
                              // Create Account gradient button
                              GestureDetector(
                                onTap: auth.isLoading ? null : _onCreateAccountTap,
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
                                        : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Log in link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Already have an account? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: const Text('Log In', style: TextStyle(color: Color(0xFF818CF8), fontSize: 14, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 650.ms, delay: 150.ms).slideY(begin: 0.14, end: 0, duration: 650.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
