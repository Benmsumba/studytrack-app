import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Mark all read',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF06B6D4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: const [
                  _NotificationTile(
                    title: 'Daily Briefing Ready',
                    body: 'You have 2 classes and 3 study sessions today.',
                    timeLabel: '7:00 AM',
                    icon: Icons.wb_sunny_outlined,
                    iconColor: Color(0xFF06B6D4),
                    unread: true,
                  ),
                  _NotificationTile(
                    title: 'Study Session in 15 Minutes',
                    body: 'Pharmacokinetics review starts at 2:00 PM.',
                    timeLabel: '1:45 PM',
                    icon: Icons.timer_outlined,
                    iconColor: Color(0xFF7C3AED),
                    unread: true,
                  ),
                  _NotificationTile(
                    title: 'Exam Countdown Alert',
                    body: 'Anatomy Final is in 7 days. Keep momentum high.',
                    timeLabel: 'Yesterday',
                    icon: Icons.warning_amber_rounded,
                    iconColor: Color(0xFFF59E0B),
                  ),
                  _NotificationTile(
                    title: 'Weekly Wrapped Available',
                    body: 'Your progress report is ready to view and share.',
                    timeLabel: 'Sunday',
                    icon: Icons.insights_outlined,
                    iconColor: Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    required this.iconColor,
    this.unread = false,
  });

  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unread ? const Color(0xFF7C3AED) : const Color(0xFF2D2D44),
          width: unread ? 1.2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF06B6D4),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
