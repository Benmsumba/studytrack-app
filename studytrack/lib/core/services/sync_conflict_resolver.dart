import 'package:flutter/foundation.dart';

/// Represents a sync conflict between local and remote data
class SyncConflict {
  SyncConflict({
    required this.entity,
    required this.recordId,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
  });

  final String entity;
  final String recordId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;

  /// Determines if local data is newer
  bool get isLocalNewer => localTimestamp.isAfter(remoteTimestamp);

  /// Determines if remote data is newer
  bool get isRemoteNewer => remoteTimestamp.isAfter(localTimestamp);

  /// Check if timestamps are equal (concurrent modification)
  bool get isConcurrent => !isLocalNewer && !isRemoteNewer;
}

/// Resolution strategy for sync conflicts
enum ConflictResolutionStrategy {
  /// Keep remote version (server is source of truth)
  favorRemote,

  /// Keep local version (offline-first priority)
  favorLocal,

  /// Merge both versions intelligently
  merge,

  /// Manual resolution required
  manual,
}

/// Service for detecting and resolving sync conflicts
class SyncConflictResolver {
  /// Detect conflicts between local and remote data
  static SyncConflict? detectConflict({
    required String entity,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    DateTime? localTimestamp,
    DateTime? remoteTimestamp,
  }) {
    // Check if data differs
    if (mapEquals(localData, remoteData)) {
      return null; // No conflict
    }

    localTimestamp ??= DateTime.now();
    remoteTimestamp ??= DateTime.now();

    return SyncConflict(
      entity: entity,
      recordId: recordId,
      localData: localData,
      remoteData: remoteData,
      localTimestamp: localTimestamp,
      remoteTimestamp: remoteTimestamp,
    );
  }

  /// Resolve a conflict using the specified strategy
  static Map<String, dynamic> resolveConflict(
    SyncConflict conflict,
    ConflictResolutionStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.favorRemote:
        debugPrint(
          'Conflict resolved: favoring remote for ${conflict.entity}/${conflict.recordId}',
        );
        return conflict.remoteData;

      case ConflictResolutionStrategy.favorLocal:
        debugPrint(
          'Conflict resolved: favoring local for ${conflict.entity}/${conflict.recordId}',
        );
        return conflict.localData;

      case ConflictResolutionStrategy.merge:
        return _mergeData(conflict.localData, conflict.remoteData);

      case ConflictResolutionStrategy.manual:
        debugPrint(
          'Conflict requires manual resolution: ${conflict.entity}/${conflict.recordId}',
        );
        throw Exception(
          'Manual resolution required for ${conflict.entity}/${conflict.recordId}',
        );
    }
  }

  /// Intelligently merge local and remote data
  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = <String, dynamic>{...remoteData};

    // For each field in localData, check if it's been modified
    localData.forEach((key, localValue) {
      if (remoteData.containsKey(key)) {
        final remoteValue = remoteData[key];

        // If neither is null and values differ, prefer non-null values
        if (localValue != null && remoteValue == null) {
          merged[key] = localValue;
        } else if (localValue == null && remoteValue != null) {
          merged[key] = remoteValue;
        } else if (localValue is Map && remoteValue is Map) {
          // Recursively merge nested maps
          merged[key] = _mergeData(
            Map<String, dynamic>.from(localValue),
            Map<String, dynamic>.from(remoteValue),
          );
        }
        // Otherwise keep remote value (already in merged)
      } else {
        // Field only exists in local, add it
        merged[key] = localValue;
      }
    });

    return merged;
  }

  /// Get recommended resolution strategy based on conflict characteristics
  static ConflictResolutionStrategy getRecommendedStrategy(
    SyncConflict conflict,
  ) {
    // If remote is significantly newer (> 1 hour), favor remote
    if (conflict.isRemoteNewer &&
        conflict.remoteTimestamp.difference(conflict.localTimestamp).inHours >
            1) {
      return ConflictResolutionStrategy.favorRemote;
    }

    // If local is newer, favor local (offline-first priority)
    if (conflict.isLocalNewer) {
      return ConflictResolutionStrategy.favorLocal;
    }

    // If concurrent or close in time, try to merge
    return ConflictResolutionStrategy.merge;
  }
}
