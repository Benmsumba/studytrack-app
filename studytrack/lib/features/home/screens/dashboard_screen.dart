import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/wrapped_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  String _userName = 'Chifundo';
  final int _readinessPulse = 12;
  final double _sessionProgress = 0.0;
  String? _currentTopicName;
  String? _currentModuleName;
  final int _dailyGoalHours = 3;
  final int _dailyHoursFilled = 0;
  final int _examDaysRemaining = 12;
  final double _examReadiness = 0.98;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final user = _service.getCurrentUser();
    if (!mounted) return;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _service.getProfile(user.id);
    final displayName = (profile?['display_name'] ?? 'Chifundo') as String;

    setState(() {
      _userName = displayName;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StudyTrack',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Good Morning, $_userName!',
                        style: AppTextStyles.headingLarge.copyWith(
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neonCyan, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyanGlow,
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: AppColors.neonCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _readinessPulse.toString().padLeft(2, '0'),
                          style: GoogleFonts.inter(
                            color: AppColors.neonCyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // START STUDY SESSION card
              WrappedCard(
                padding: 20,
                enableGlow: true,
                glowColor: AppColors.violetGlowSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START STUDY SESSION',
                      style: AppTextStyles.labelSecondary.copyWith(
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer circle (progress indicator)
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 2,
                                ),
                              ),
                            ),
                            // Progress ring (animated)
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 4,
                                ),
                              ),
                              child: CircularProgressIndicator(
                                value: _sessionProgress,
                                strokeWidth: 6,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.neonViolet.withValues(alpha: 0.6),
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                            // Center percentage
                            Text(
                              '${(_sessionProgress * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Topic: $_currentTopicName',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'from $_currentModuleName module',
                      style: AppTextStyles.bodySmallSecondary,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/study-session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'START SESSION',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Daily Goal card
              WrappedCard(
                padding: 16,
                enableGlow: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Goal: $_dailyHoursFilled/$_dailyGoalHours Hours',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _dailyHoursFilled / _dailyGoalHours,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.neonCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${((_dailyHoursFilled / _dailyGoalHours) * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Exam Readiness card
              WrappedCard(
                padding: 16,
                enableGlow: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anatomy Final: $_examDaysRemaining Days',
                            style: AppTextStyles.bodyMedium,
                          ),
                          Text(
                            'Readiness pulse',
                            style: AppTextStyles.bodySmallSecondary,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFB74D),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFB74D,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${(_examReadiness * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFB74D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
