import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class TopicModel {

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      isStudied: json['is_studied'] as bool? ?? false,
      currentRating: json['current_rating'] as int?,
      studyCount: json['study_count'] as int? ?? 0,
      lastStudiedAt: json['last_studied_at'] == null
          ? null
          : DateTime.parse(json['last_studied_at'] as String),
      nextReviewAt: json['next_review_at'] == null
          ? null
          : DateTime.parse(json['next_review_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  const TopicModel({
    required this.id,
    required this.moduleId,
    required this.userId,
    required this.name,
    required this.isStudied,
    required this.studyCount, required this.createdAt, this.currentRating,
    this.lastStudiedAt,
    this.nextReviewAt,
    this.notes,
  });

  final String id;
  final String moduleId;
  final String userId;
  final String name;
  final bool isStudied;
  final int? currentRating;
  final int studyCount;
  final DateTime? lastStudiedAt;
  final DateTime? nextReviewAt;
  final String? notes;
  final DateTime createdAt;

  String get masteryLevel {
    final rating = currentRating ?? 0;
    if (rating <= 2) return 'Needs Work';
    if (rating <= 4) return 'Learning';
    if (rating <= 7) return 'Good';
    return 'Mastered';
  }

  Color get ratingColor {
    final rating = currentRating ?? 0;
    if (rating <= 2) return AppColors.danger;
    if (rating <= 4) return AppColors.warning;
    if (rating <= 7) return AppColors.accent;
    return AppColors.success;
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'module_id': moduleId,
      'user_id': userId,
      'name': name,
      'is_studied': isStudied,
      'current_rating': currentRating,
      'study_count': studyCount,
      'last_studied_at': lastStudiedAt?.toIso8601String(),
      'next_review_at': nextReviewAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };

  TopicModel copyWith({
    String? id,
    String? moduleId,
    String? userId,
    String? name,
    bool? isStudied,
    int? currentRating,
    int? studyCount,
    DateTime? lastStudiedAt,
    DateTime? nextReviewAt,
    String? notes,
    DateTime? createdAt,
  }) => TopicModel(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isStudied: isStudied ?? this.isStudied,
      currentRating: currentRating ?? this.currentRating,
      studyCount: studyCount ?? this.studyCount,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
}