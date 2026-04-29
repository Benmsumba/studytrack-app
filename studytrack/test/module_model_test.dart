import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/core/constants/app_colors.dart';
import 'package:studytrack/models/module_model.dart';

void main() {
  group('ModuleModel subjectColor', () {
    test('uses mapped subject color when module name key exists', () {
      final module = _module(name: 'anatomy');
      expect(module.subjectColor, AppColors.subjectColors['anatomy']);
    });

    test('falls back to accent color for unknown module names', () {
      final module = _module(name: 'unknown-subject');
      expect(module.subjectColor, AppColors.accent);
    });
  });

  group('ModuleModel serialization', () {
    test('fromJson applies default isActive when omitted', () {
      final module = ModuleModel.fromJson({
        'id': 'module-1',
        'user_id': 'user-1',
        'name': 'Physiology',
        'created_at': '2026-04-01T00:00:00.000Z',
      });

      expect(module.id, 'module-1');
      expect(module.userId, 'user-1');
      expect(module.name, 'Physiology');
      expect(module.isActive, isTrue);
    });

    test('toJson and copyWith preserve and update fields correctly', () {
      final original = _module(
        name: 'Biochemistry',
        color: '#06B6D4',
        semester: 'Semester 1',
        isActive: true,
      );
      final updated = original.copyWith(name: 'Pathology', isActive: false);
      final encoded = updated.toJson();

      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
      expect(updated.name, 'Pathology');
      expect(updated.color, '#06B6D4');
      expect(updated.semester, 'Semester 1');
      expect(updated.isActive, isFalse);
      expect(updated.createdAt, original.createdAt);

      expect(encoded['id'], 'module-1');
      expect(encoded['user_id'], 'user-1');
      expect(encoded['name'], 'Pathology');
      expect(encoded['color'], '#06B6D4');
      expect(encoded['semester'], 'Semester 1');
      expect(encoded['is_active'], isFalse);
    });
  });
}

ModuleModel _module({
  required String name,
  String? color,
  String? semester,
  bool isActive = true,
}) {
  return ModuleModel(
    id: 'module-1',
    userId: 'user-1',
    name: name,
    color: color,
    semester: semester,
    isActive: isActive,
    createdAt: DateTime.parse('2026-04-01T00:00:00.000Z'),
  );
}
