import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _logoSvg = '''
<svg width="128" height="128" viewBox="0 0 128 128" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="studytrackGradient" x1="20" y1="20" x2="108" y2="108" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#7C3AED" />
      <stop offset="100%" stop-color="#06B6D4" />
    </linearGradient>
  </defs>
  <rect x="12" y="18" width="104" height="92" rx="20" fill="url(#studytrackGradient)" opacity="0.14"/>
  <path d="M28 34C28 29.5817 31.5817 26 36 26H66.5C71.6344 26 76.5096 28.1552 80 31.9L83.5 35.65L87 31.9C90.4904 28.1552 95.3656 26 100.5 26H92C96.4183 26 100 29.5817 100 34V88C100 92.4183 96.4183 96 92 96H74.5C69.8507 96 65.4183 97.7929 62 100.95C58.5817 97.7929 54.1493 96 49.5 96H36C31.5817 96 28 92.4183 28 88V34Z" fill="#0F0F1A" stroke="url(#studytrackGradient)" stroke-width="4" stroke-linejoin="round"/>
  <path d="M47 45C47 41.6863 49.6863 39 53 39H75C78.3137 39 81 41.6863 81 45V63C81 66.3137 78.3137 69 75 69H53C49.6863 69 47 66.3137 47 63V45Z" fill="url(#studytrackGradient)" opacity="0.22"/>
  <path d="M54 48C57.5 44.4 63.2 44.4 66.7 48C70.2 51.6 70.2 57.4 66.7 61C64.9 62.9 63.6 65.4 63.2 68.1L62.7 71.5H60.3L59.8 68.1C59.4 65.4 58.1 62.9 56.3 61C52.8 57.4 52.8 51.6 56.3 48H54Z" fill="#FFFFFF"/>
  <circle cx="60" cy="52" r="1.8" fill="#06B6D4"/>
  <circle cx="66" cy="52" r="1.8" fill="#7C3AED"/>
  <path d="M44 78H84" stroke="url(#studytrackGradient)" stroke-width="4" stroke-linecap="round"/>
  <path d="M50 85H78" stroke="#06B6D4" stroke-width="4" stroke-linecap="round" opacity="0.95"/>
</svg>
''';

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2500), _handleRedirect);
  }

  Future<void> _handleRedirect() async {
    if (!mounted) return;

    bool isLoggedIn = false;
    try {
      isLoggedIn = SupabaseService().isLoggedIn();
    } catch (_) {
      isLoggedIn = false;
    }

    if (!mounted) return;

    if (isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/onboarding-welcome');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.string(_logoSvg, width: 128, height: 128)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.0, 1.0),
                    duration: 900.ms,
                    curve: Curves.easeOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.03, 1.03),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
              Text(
                'StudyTrack',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 200.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.12, end: 0.0, duration: 700.ms, curve: Curves.easeOut),
              const SizedBox(height: 8),
              Text(
                'Study smarter. Know where you stand.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.12, end: 0.0, duration: 700.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}