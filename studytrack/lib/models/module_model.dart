import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ModuleModel {
  factory ModuleModel.fromJson(Map<String, dynamic> json) => ModuleModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    color: json['color'] as String?,
    semester: json['semester'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
  const ModuleModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    this.color,
    this.semester,
  });

  final String id;
  final String userId;
  final String name;
  final String? color;
  final String? semester;
  final bool isActive;
  final DateTime createdAt;

  Color get subjectColor {
    final key = name.trim();
    return AppColors.subjectColors[key] ?? AppColors.accent;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'color': color,
    'semester': semester,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  ModuleModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    String? semester,
    bool? isActive,
    DateTime? createdAt,
  }) => ModuleModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    color: color ?? this.color,
    semester: semester ?? this.semester,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
}
