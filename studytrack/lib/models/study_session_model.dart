class StudySessionModel {
  const StudySessionModel({
    required this.id,
    required this.userId,
    this.topicId,
    this.moduleId,
    required this.title,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.status,
    this.actualDurationMinutes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? topicId;
  final String? moduleId;
  final String title;
  final DateTime scheduledDate;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final String status;
  final int? actualDurationMinutes;
  final DateTime createdAt;

  bool get isOverdue {
    final scheduled = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return status != 'completed' && scheduled.isBefore(todayDate);
  }

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    return StudySessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      topicId: json['topic_id'] as String?,
      moduleId: json['module_id'] as String?,
      title: json['title'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      status: json['status'] as String,
      actualDurationMinutes: (json['actual_duration_minutes'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'topic_id': topicId,
      'module_id': moduleId,
      'title': title,
      'scheduled_date': scheduledDate.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'status': status,
      'actual_duration_minutes': actualDurationMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  StudySessionModel copyWith({
    String? id,
    String? userId,
    String? topicId,
    String? moduleId,
    String? title,
    DateTime? scheduledDate,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    String? status,
    int? actualDurationMinutes,
    DateTime? createdAt,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}