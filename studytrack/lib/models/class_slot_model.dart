class ClassSlotModel {
  const ClassSlotModel({
    required this.id,
    required this.userId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.lecturer,
    this.color,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String subjectName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? lecturer;
  final String? color;
  final DateTime createdAt;

  factory ClassSlotModel.fromJson(Map<String, dynamic> json) {
    return ClassSlotModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectName: json['subject_name'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      room: json['room'] as String?,
      lecturer: json['lecturer'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_name': subjectName,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'lecturer': lecturer,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ClassSlotModel copyWith({
    String? id,
    String? userId,
    String? subjectName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    String? lecturer,
    String? color,
    DateTime? createdAt,
  }) {
    return ClassSlotModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectName: subjectName ?? this.subjectName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      lecturer: lecturer ?? this.lecturer,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}