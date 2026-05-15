import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/controllers/auth_provider.dart';
import '../constants/app_colors.dart';

/// Glass-morphic drawer with Stitch design.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentUser;
    final authUser = Supabase.instance.client.auth.currentUser;
    final name = profile?.name ?? 'Student';
    final email = authUser?.email ?? 'Welcome to StudyTrack';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'S';

    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(0xEE1A1A2E),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      const Text(
                        'StudyTrack',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // User row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.indigoPrimary,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 8),
                // Menu items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    children: [
                      _buildDrawerItem(
                        context,
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        route: '/profile',
                        isActive: currentLocation.contains('/profile'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/profile');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.emoji_events_rounded,
                        label: 'Achievements',
                        route: '/home/progress',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                          context.go('/home/progress');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        route: '/settings',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/settings');
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.feedback_rounded,
                        label: 'Feedback',
                        route: '',
                        onTap: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Feedback coming soon')),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.logout_rounded,
                        label: 'Logout',
                        route: '',
                        isDanger: true,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? const Color(0x1A4F46E5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isDanger
                      ? const Color(0xFFEF4444)
                      : isActive
                          ? AppColors.indigoPrimary
                          : Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isDanger ? const Color(0xFFEF4444) : Colors.white,
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
