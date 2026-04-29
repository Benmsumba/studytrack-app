import 'package:flutter/material.dart';

class StudyTrackErrorWidget extends StatelessWidget {
  const StudyTrackErrorWidget({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  String _friendlyTitle(String value) {
    final text = value.toLowerCase();
    if (text.contains('socket') || text.contains('network')) {
      return 'No internet connection';
    }
    if (text.contains('auth')) {
      return 'Authentication issue';
    }
    if (text.contains('server') || text.contains('500')) {
      return 'Server error';
    }
    return 'Something went wrong';
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFF43F5E),
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            _friendlyTitle(message),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );
}
