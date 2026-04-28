import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../services/offline_sync_service.dart';

class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<OfflineSyncService?>(context);
    if (syncService == null) {
      return child;
    }

    final isOffline = !syncService.isOnline;
    final isSyncing = syncService.isSyncing;

    return Column(
      children: [
        if (isOffline || isSyncing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isOffline
                  ? const LinearGradient(
                      colors: [Color(0xFF7C2D12), Color(0xFFF97316)],
                    )
                  : AppColors.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Icon(
                    isOffline ? Icons.cloud_off_rounded : Icons.sync_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isOffline
                          ? 'Offline mode active. Changes will sync when you reconnect.'
                          : 'Syncing pending changes...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (syncService.hasPendingChanges)
                    Text(
                      '${syncService.pendingChanges} pending',
                      style: GoogleFonts.inter(
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
