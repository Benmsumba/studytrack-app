class StudyGroupModel {
  factory StudyGroupModel.fromJson(Map<String, dynamic> json) =>
      StudyGroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        createdBy: json['created_by'] as String,
        inviteCode: json['invite_code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  const StudyGroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.inviteCode,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String inviteCode;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'created_by': createdBy,
    'invite_code': inviteCode,
    'created_at': createdAt.toIso8601String(),
  };

  StudyGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    String? inviteCode,
    DateTime? createdAt,
  }) => StudyGroupModel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    createdBy: createdBy ?? this.createdBy,
    inviteCode: inviteCode ?? this.inviteCode,
    createdAt: createdAt ?? this.createdAt,
  );
}
