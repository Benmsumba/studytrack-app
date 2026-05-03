import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/offline_sync_service.dart';

class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<OfflineSyncService?>(context);
    if (syncService == null) {
      return child;
    }

    final isOffline = !syncService.isOnline;
    final isSyncing = syncService.isSyncing;
    final hasError = syncService.lastSyncError != null;
    final hasPending = syncService.hasPendingChanges;

    String message;
    IconData icon;
    LinearGradient gradient;

    if (isOffline) {
      message = 'Offline mode active. Changes will sync when you reconnect.';
      icon = Icons.cloud_off_rounded;
      gradient = const LinearGradient(
        colors: [Color(0xFF7C2D12), Color(0xFFF97316)],
      );
    } else if (isSyncing) {
      message = 'Syncing pending changes...';
      icon = Icons.sync_rounded;
      gradient = AppColors.primaryGradient;
    } else if (hasError) {
      message = syncService.lastSyncError!;
      icon = Icons.sync_problem_rounded;
      gradient = const LinearGradient(
        colors: [Color(0xFF7F1D1D), Color(0xFFEF4444)],
      );
    } else if (hasPending) {
      message =
          'Waiting to sync ${syncService.pendingChanges} pending change${syncService.pendingChanges == 1 ? '' : 's'}.';
      icon = Icons.schedule_rounded;
      gradient = AppColors.primaryGradient;
    } else {
      return child;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasPending)
                  Text(
                    '${syncService.pendingChanges} pending',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
