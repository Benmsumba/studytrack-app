import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Logo matches the StudyTrack brand: split brain (purple left / cyan right)
  // rising from an open book, with soft glow halos behind each hemisphere.
  static const String _logoAsset = 'assets/icon/app_icon.jpeg';

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1000), _handleRedirect);
  }

  Future<void> _handleRedirect() async {
    if (!mounted) {
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.refreshCurrentUser(silent: true);

    if (!mounted) {
      return;
    }

    // Let the router's redirect logic handle all navigation
    // This ensures consistent routing based on auth state and onboarding status
    if (auth.isAuthenticated) {
      context.go('/home/timetable');
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
                  _logoAsset,
                  width: 128,
                  height: 128,
                  fit: BoxFit.contain,
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1, 1),
                  duration: 900.ms,
                  curve: Curves.easeOut,
                )
                .then()
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.03, 1.03),
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            Text('StudyTrack', style: AppTextStyles.displayMedium)
                .animate()
                .fadeIn(duration: 700.ms, delay: 200.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 700.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 8),
            Text(
                  'Study smarter. Know where you stand.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMediumSecondary,
                )
                .animate()
                .fadeIn(duration: 700.ms, delay: 350.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 700.ms,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
    ),
  );
}
