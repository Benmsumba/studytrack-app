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
  // Logo matches the StudyTrack brand: split brain (purple left / cyan right)
  // rising from an open book, with soft glow halos behind each hemisphere.
  static const String _logoSvg = '''
<svg width="160" height="140" viewBox="0 0 160 140" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="stGrad" x1="0" y1="0" x2="160" y2="140" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#7C3AED"/>
      <stop offset="100%" stop-color="#06B6D4"/>
    </linearGradient>
    <!-- Purple glow behind left brain hemisphere -->
    <radialGradient id="glowL" cx="42%" cy="44%" r="34%">
      <stop offset="0%" stop-color="#7C3AED" stop-opacity="0.55"/>
      <stop offset="100%" stop-color="#7C3AED" stop-opacity="0"/>
    </radialGradient>
    <!-- Cyan glow behind right brain hemisphere -->
    <radialGradient id="glowR" cx="58%" cy="44%" r="34%">
      <stop offset="0%" stop-color="#06B6D4" stop-opacity="0.55"/>
      <stop offset="100%" stop-color="#06B6D4" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <!-- Soft glow halos (mimics the 3-D render in the logo photo) -->
  <ellipse cx="62" cy="56" rx="38" ry="32" fill="url(#glowL)"/>
  <ellipse cx="98" cy="56" rx="38" ry="32" fill="url(#glowR)"/>

  <!-- ── OPEN BOOK ────────────────────────────────────────────────── -->
  <!-- Left page -->
  <path d="M18 100 L18 76 Q18 72 22 70 L78 62 L78 88 Q54 90 22 104 Z"
        fill="#7C3AED" fill-opacity="0.18" stroke="#7C3AED" stroke-width="2.2"
        stroke-linejoin="round"/>
  <!-- Right page -->
  <path d="M142 100 L142 76 Q142 72 138 70 L82 62 L82 88 Q106 90 138 104 Z"
        fill="#06B6D4" fill-opacity="0.18" stroke="#06B6D4" stroke-width="2.2"
        stroke-linejoin="round"/>
  <!-- Spine -->
  <line x1="80" y1="62" x2="80" y2="90" stroke="url(#stGrad)" stroke-width="2.5"
        stroke-linecap="round"/>

  <!-- ── LEFT BRAIN HEMISPHERE (purple) ──────────────────────────── -->
  <g stroke="#A78BFA" stroke-width="2.4" fill="none" stroke-linecap="round"
     stroke-linejoin="round">
    <!-- Outer lobe -->
    <path d="M80 28 C80 18 56 14 48 24 C38 28 34 40 38 50
             C36 60 42 68 52 68 L80 64 Z"/>
    <!-- Inner fold curves -->
    <path d="M64 26 C58 30 55 36 57 42"/>
    <path d="M56 38 C52 42 51 50 55 56"/>
    <path d="M70 20 C65 24 63 32 66 38"/>
  </g>

  <!-- ── RIGHT BRAIN HEMISPHERE (cyan) ───────────────────────────── -->
  <g stroke="#67E8F9" stroke-width="2.4" fill="none" stroke-linecap="round"
     stroke-linejoin="round">
    <!-- Outer lobe (mirrored) -->
    <path d="M80 28 C80 18 104 14 112 24 C122 28 126 40 122 50
             C124 60 118 68 108 68 L80 64 Z"/>
    <!-- Inner fold curves (mirrored) -->
    <path d="M96 26 C102 30 105 36 103 42"/>
    <path d="M104 38 C108 42 109 50 105 56"/>
    <path d="M90 20 C95 24 97 32 94 38"/>
  </g>

  <!-- Centre divider line -->
  <line x1="80" y1="26" x2="80" y2="66" stroke="url(#stGrad)"
        stroke-width="1.8" stroke-linecap="round"/>
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

    var isLoggedIn = false;
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
  Widget build(BuildContext context) => Scaffold(
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