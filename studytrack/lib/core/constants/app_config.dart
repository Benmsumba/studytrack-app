/// Application-wide configuration constants
/// Extracted from hardcoded values throughout the codebase for maintainability
class AppConfig {
  // Gemini AI Service Configuration
  static const int geminoCacheTtl = 3600; // 1 hour in seconds
  static const int geminoCacheMaxEntries = 100;
  static const int geminiRateLimitMs = 500; // Minimum interval between requests
  static const int geminiRetryAttempts = 3;

  // Offline Data Store Configuration
  static const int offlineCacheTtlDays = 30;
  static const int maxCachedRecords = 500;
  static const int maxCachedQueries = 200;
  static const int maxErrorHistoryEntries = 100;

  // Network & Sync Configuration
  static const int syncBatchSize = 50;
  static const int maxPendingChanges = 1000;
  static const Duration syncCheckInterval = Duration(seconds: 30);

  // UI Configuration
  static const int messagesPaginationSize = 50;
  static const int listItemsPaginationSize = 25;
  static const int maxScreenContentLines =
      300; // Screens should not exceed this LOC

  // Hashing & Security
  static const int anonymizedIdLength = 8;
  static const int encryptionKeyLength = 32; // 256-bit key

  // Performance Thresholds
  static const Duration animationDuration = Duration(milliseconds: 220);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Date/Time Configuration
  static const int spaceRepMinDays = 1;
  static const int spaceRepMaxDays = 30;
  static const List<int> spaceRepIntervals = [1, 3, 7, 14, 30];

  // Error Handling
  static const int errorRetryAttempts = 3;
  static const Duration errorRetryDelay = Duration(seconds: 2);
}
