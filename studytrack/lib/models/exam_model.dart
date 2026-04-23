class ExamModel {
  const ExamModel({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.title,
    required this.examDate,
    this.examTime,
    this.venue,
    required this.examType,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String moduleId;
  final String title;
  final DateTime examDate;
  final String? examTime;
  final String? venue;
  final String examType;
  final DateTime createdAt;

  int get daysUntilExam {
    final examDay = DateTime(examDate.year, examDate.month, examDate.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return examDay.difference(todayDay).inDays;
  }

  bool get isUrgent => daysUntilExam <= 7;

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      examDate: DateTime.parse(json['exam_date'] as String),
      examTime: json['exam_time'] as String?,
      venue: json['venue'] as String?,
      examType: json['exam_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'module_id': moduleId,
      'title': title,
      'exam_date': examDate.toIso8601String().split('T').first,
      'exam_time': examTime,
      'venue': venue,
      'exam_type': examType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExamModel copyWith({
    String? id,
    String? userId,
    String? moduleId,
    String? title,
    DateTime? examDate,
    String? examTime,
    String? venue,
    String? examType,
    DateTime? createdAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      examDate: examDate ?? this.examDate,
      examTime: examTime ?? this.examTime,
      venue: venue ?? this.venue,
      examType: examType ?? this.examType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}