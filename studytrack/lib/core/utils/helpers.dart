import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/topic_model.dart';
import '../constants/app_config.dart';

class Helpers {
  static String formatTitle(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF43F5E),
      ),
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  static String formatDate(DateTime date) =>
      DateFormat('EEE, d MMM').format(date);

  static String formatTime(TimeOfDay time) {
    final date = DateTime(2000, 1, 1, time.hour, time.minute);
    return DateFormat('hh:mm a').format(date);
  }

  static String getGreeting({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static double calculateReadinessScore(List<TopicModel> topics) {
    final rated = topics.where((topic) => topic.currentRating != null).toList();
    if (rated.isEmpty) return 0;

    final total = rated.fold<int>(
      0,
      (sum, topic) => sum + (topic.currentRating ?? 0),
    );

    final average = total / rated.length;
    return (average / 10) * 100;
  }

  static DateTime getSpacedRepetitionDate(int rating, {DateTime? from}) {
    final now = from ?? DateTime.now();
    if (rating <= 3) return now.add(const Duration(days: 1));
    if (rating <= 5) return now.add(const Duration(days: 3));
    if (rating <= 7) return now.add(const Duration(days: 7));
    if (rating <= 9) return now.add(const Duration(days: 14));
    return now.add(const Duration(days: 30));
  }

  /// Generates a secure, stable anonymized ID from a user ID
  /// Uses SHA-256 hash for privacy without exposing original UUIDs
  static String anonymizeUserId(String userId, {int? length}) {
    length ??= AppConfig.anonymizedIdLength;
    if (userId.isEmpty) return 'anonymous';
    final hash = sha256.convert(userId.codeUnits).toString();
    return 'user_${hash.substring(0, length)}';
  }
}
