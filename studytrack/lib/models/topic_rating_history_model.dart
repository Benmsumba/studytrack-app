class TopicRatingHistoryModel {
  const TopicRatingHistoryModel({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.rating,
    required this.ratedAt,
  });

  final String id;
  final String topicId;
  final String userId;
  final int rating;
  final DateTime ratedAt;

  factory TopicRatingHistoryModel.fromJson(Map<String, dynamic> json) {
    return TopicRatingHistoryModel(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      userId: json['user_id'] as String,
      rating: (json['rating'] as num).toInt(),
      ratedAt: DateTime.parse(json['rated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'user_id': userId,
      'rating': rating,
      'rated_at': ratedAt.toIso8601String(),
    };
  }

  TopicRatingHistoryModel copyWith({
    String? id,
    String? topicId,
    String? userId,
    int? rating,
    DateTime? ratedAt,
  }) {
    return TopicRatingHistoryModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      ratedAt: ratedAt ?? this.ratedAt,
    );
  }
}