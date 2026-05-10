import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/crash_reporter.dart';
import '../theme/app_palette.dart';

/// Wraps any subtree and catches synchronous widget-build errors that escape
/// to the nearest `ErrorWidget` boundary. Shows a friendly recovery screen
/// instead of the default red-box crash screen.
///
/// Usage (wrap the root `MaterialApp` or individual high-risk pages):
/// ```dart
/// AppErrorBoundary(child: MaterialApp(...))
/// ```
class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({required this.child, super.key});

  final Widget child;

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  void _reset() => setState(() {
        _error = null;
        _stack = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallbackScreen(error: _error!, onRetry: _reset);
    }

    // Override the local ErrorWidget builder so widget build errors in this
    // subtree are caught here rather than shown as red boxes.
    return Builder(
      builder: (context) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // Report to Sentry / crash service.
          CrashReporter.report(details.exception, details.stack ?? StackTrace.empty);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _error = details.exception;
                _stack = details.stack;
              });
            }
          });
          // Return transparent box while post-frame callback fires.
          return const SizedBox.shrink();
        };
        return widget.child;
      },
    );
  }
}

// ── Fallback screen ─────────────────────────────────────────────────────────

class _ErrorFallbackScreen extends StatelessWidget {
  const _ErrorFallbackScreen({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      palette.brandPrimary.withValues(alpha: 0.25),
                      palette.brandPrimary.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 52,
                  color: palette.brandPrimary,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Body
              Text(
                'StudyTrack hit an unexpected error. '
                'Your progress is safe — tap below to get back on track.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Retry button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Copy error (debug aid)
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: error.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error details copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(Icons.copy_rounded,
                    size: 16, color: palette.textSecondary),
                label: Text(
                  'Copy error details',
                  style: TextStyle(fontSize: 13, color: palette.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
