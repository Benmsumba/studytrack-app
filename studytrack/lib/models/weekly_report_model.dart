class WeeklyReportModel {

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) => WeeklyReportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      topicsStudied: (json['topics_studied'] as num).toInt(),
      topicsPlanned: (json['topics_planned'] as num).toInt(),
      sessionsCompleted: (json['sessions_completed'] as num).toInt(),
      sessionsPlanned: (json['sessions_planned'] as num).toInt(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      bestSubject: json['best_subject'] as String?,
      weakestSubject: json['weakest_subject'] as String?,
      streakAtEnd: (json['streak_at_end'] as num).toInt(),
      aiSummary: json['ai_summary'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  const WeeklyReportModel({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.topicsStudied,
    required this.topicsPlanned,
    required this.sessionsCompleted,
    required this.sessionsPlanned,
    required this.streakAtEnd, required this.createdAt, this.averageRating,
    this.bestSubject,
    this.weakestSubject,
    this.aiSummary,
  });

  final String id;
  final String userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int topicsStudied;
  final int topicsPlanned;
  final int sessionsCompleted;
  final int sessionsPlanned;
  final double? averageRating;
  final String? bestSubject;
  final String? weakestSubject;
  final int streakAtEnd;
  final String? aiSummary;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId,
      'week_start': weekStart.toIso8601String().split('T').first,
      'week_end': weekEnd.toIso8601String().split('T').first,
      'topics_studied': topicsStudied,
      'topics_planned': topicsPlanned,
      'sessions_completed': sessionsCompleted,
      'sessions_planned': sessionsPlanned,
      'average_rating': averageRating,
      'best_subject': bestSubject,
      'weakest_subject': weakestSubject,
      'streak_at_end': streakAtEnd,
      'ai_summary': aiSummary,
      'created_at': createdAt.toIso8601String(),
    };

  WeeklyReportModel copyWith({
    String? id,
    String? userId,
    DateTime? weekStart,
    DateTime? weekEnd,
    int? topicsStudied,
    int? topicsPlanned,
    int? sessionsCompleted,
    int? sessionsPlanned,
    double? averageRating,
    String? bestSubject,
    String? weakestSubject,
    int? streakAtEnd,
    String? aiSummary,
    DateTime? createdAt,
  }) => WeeklyReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      topicsStudied: topicsStudied ?? this.topicsStudied,
      topicsPlanned: topicsPlanned ?? this.topicsPlanned,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      sessionsPlanned: sessionsPlanned ?? this.sessionsPlanned,
      averageRating: averageRating ?? this.averageRating,
      bestSubject: bestSubject ?? this.bestSubject,
      weakestSubject: weakestSubject ?? this.weakestSubject,
      streakAtEnd: streakAtEnd ?? this.streakAtEnd,
      aiSummary: aiSummary ?? this.aiSummary,
      createdAt: createdAt ?? this.createdAt,
    );
}