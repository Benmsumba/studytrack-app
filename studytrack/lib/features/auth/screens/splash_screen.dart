import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../controllers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _logoAsset = 'assets/icon/app_icon.jpeg';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1100), _handleRedirect);
  }

  Future<void> _handleRedirect() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.refreshCurrentUser(silent: true);
    if (!mounted) return;
    if (auth.isAuthenticated) {
      context.go('/home/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return AppScaffold(
      ambientGlow: true,
      ambientIntensity: 1.5,
      useDeepBackground: true,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: palette.brandGradient,
                  boxShadow: [
                    BoxShadow(
                      color: palette.glowPrimary.withValues(alpha: 0.55),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: palette.glowSecondary.withValues(alpha: 0.4),
                      blurRadius: 28,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: ClipOval(
                  child: Image.asset(_logoAsset, fit: BoxFit.cover),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 700.ms)
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 900.ms,
                    curve: Curves.easeOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.04, 1.04),
                    duration: 1400.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (rect) =>
                    palette.brandGradient.createShader(rect),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'StudyTrack',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 200.ms)
                  .slideY(begin: 0.12, end: 0, duration: 700.ms),
              const SizedBox(height: 8),
              Text(
                'Study smarter. Know where you stand.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 350.ms)
                  .slideY(begin: 0.12, end: 0, duration: 700.ms),
              const SizedBox(height: 40),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: palette.brandSecondary,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
