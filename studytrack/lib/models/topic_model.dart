class TopicModel {
  const TopicModel({
    required this.id,
    required this.moduleId,
    required this.userId,
    required this.name,
    required this.isStudied,
    this.currentRating,
    required this.studyCount,
    this.lastStudiedAt,
    this.nextReviewAt,
    this.notes,
    required this.createdAt,
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

  Map<String, dynamic> toJson() {
    return {
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
  }
}