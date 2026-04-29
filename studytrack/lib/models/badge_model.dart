class BadgeModel {
  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    badgeType: json['badge_type'] as String,
    earnedAt: DateTime.parse(json['earned_at'] as String),
  );
  const BadgeModel({
    required this.id,
    required this.userId,
    required this.badgeType,
    required this.earnedAt,
  });

  final String id;
  final String userId;
  final String badgeType;
  final DateTime earnedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'badge_type': badgeType,
    'earned_at': earnedAt.toIso8601String(),
  };

  BadgeModel copyWith({
    String? id,
    String? userId,
    String? badgeType,
    DateTime? earnedAt,
  }) => BadgeModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    badgeType: badgeType ?? this.badgeType,
    earnedAt: earnedAt ?? this.earnedAt,
  );
}
