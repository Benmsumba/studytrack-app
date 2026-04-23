class ModuleModel {
  const ModuleModel({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    this.semester,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? color;
  final String? semester;
  final bool isActive;
  final DateTime createdAt;

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      semester: json['semester'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'semester': semester,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}