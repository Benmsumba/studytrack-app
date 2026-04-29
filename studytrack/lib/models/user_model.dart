class ProfileModel {

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      course: json['course'] as String?,
      yearLevel: (json['year_level'] as num?)?.toInt(),
      primeStudyTime: json['prime_study_time'] as String?,
      studyHoursPerDay: (json['study_hours_per_day'] as num?)?.toInt(),
      studyPreference: json['study_preference'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      lastStudyDate: json['last_study_date'] == null
          ? null
          : DateTime.parse(json['last_study_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  const ProfileModel({
    required this.id,
    required this.streakCount, required this.createdAt, required this.updatedAt, this.name,
    this.course,
    this.yearLevel,
    this.primeStudyTime,
    this.studyHoursPerDay,
    this.studyPreference,
    this.avatarUrl,
    this.lastStudyDate,
  });

  final String id;
  final String? name;
  final String? course;
  final int? yearLevel;
  final String? primeStudyTime;
  final int? studyHoursPerDay;
  final String? studyPreference;
  final String? avatarUrl;
  final int streakCount;
  final DateTime? lastStudyDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'course': course,
      'year_level': yearLevel,
      'prime_study_time': primeStudyTime,
      'study_hours_per_day': studyHoursPerDay,
      'study_preference': studyPreference,
      'avatar_url': avatarUrl,
      'streak_count': streakCount,
      'last_study_date': lastStudyDate?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  ProfileModel copyWith({
    String? id,
    String? name,
    String? course,
    int? yearLevel,
    String? primeStudyTime,
    int? studyHoursPerDay,
    String? studyPreference,
    String? avatarUrl,
    int? streakCount,
    DateTime? lastStudyDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      primeStudyTime: primeStudyTime ?? this.primeStudyTime,
      studyHoursPerDay: studyHoursPerDay ?? this.studyHoursPerDay,
      studyPreference: studyPreference ?? this.studyPreference,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streakCount: streakCount ?? this.streakCount,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
}