class StudyGroupModel {
  const StudyGroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.inviteCode,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String inviteCode;
  final DateTime createdAt;

  factory StudyGroupModel.fromJson(Map<String, dynamic> json) {
    return StudyGroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      inviteCode: json['invite_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  StudyGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    String? inviteCode,
    DateTime? createdAt,
  }) {
    return StudyGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}