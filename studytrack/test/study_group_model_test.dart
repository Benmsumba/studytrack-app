import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/models/study_group_model.dart';

void main() {
  group('StudyGroupModel', () {
    test('fromJson creates StudyGroupModel with all fields', () {
      final createdAt = DateTime(2026, 2, 15, 9, 0, 0);
      final json = {
        'id': 'group-1',
        'name': 'Physics Study Group',
        'description': 'Preparing for final exams',
        'created_by': 'user-123',
        'invite_code': 'PHY2026',
        'created_at': createdAt.toIso8601String(),
      };

      final group = StudyGroupModel.fromJson(json);

      expect(group.id, 'group-1');
      expect(group.name, 'Physics Study Group');
      expect(group.description, 'Preparing for final exams');
      expect(group.createdBy, 'user-123');
      expect(group.inviteCode, 'PHY2026');
      expect(group.createdAt, createdAt);
    });

    test('fromJson handles null description', () {
      final createdAt = DateTime(2026, 2, 15, 9, 0, 0);
      final json = {
        'id': 'group-2',
        'name': 'Math Enthusiasts',
        'description': null,
        'created_by': 'user-456',
        'invite_code': 'MATH2026',
        'created_at': createdAt.toIso8601String(),
      };

      final group = StudyGroupModel.fromJson(json);

      expect(group.description, isNull);
    });

    test('toJson converts StudyGroupModel to JSON correctly', () {
      final createdAt = DateTime(2026, 2, 15, 9, 0, 0);
      final group = StudyGroupModel(
        id: 'group-1',
        name: 'Chemistry Circle',
        description: 'Organic chemistry focus',
        createdBy: 'user-123',
        inviteCode: 'CHEM101',
        createdAt: createdAt,
      );

      final json = group.toJson();

      expect(json['id'], 'group-1');
      expect(json['name'], 'Chemistry Circle');
      expect(json['description'], 'Organic chemistry focus');
      expect(json['created_by'], 'user-123');
      expect(json['invite_code'], 'CHEM101');
      expect(json['created_at'], createdAt.toIso8601String());
    });

    test('copyWith updates specified fields only', () {
      final createdAt = DateTime(2026, 2, 15);
      final original = StudyGroupModel(
        id: 'group-1',
        name: 'Old Name',
        description: 'Old description',
        createdBy: 'user-123',
        inviteCode: 'OLD001',
        createdAt: createdAt,
      );

      final updated = original.copyWith(
        name: 'New Name',
        description: 'Updated description',
      );

      expect(updated.id, 'group-1');
      expect(updated.name, 'New Name');
      expect(updated.description, 'Updated description');
      expect(updated.createdBy, 'user-123');
      expect(updated.inviteCode, 'OLD001');
    });
  });
}
