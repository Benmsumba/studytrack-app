import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/models/group_member_model.dart';

void main() {
  group('GroupMemberModel', () {
    test('fromJson creates GroupMemberModel with correct values', () {
      final joinedAt = DateTime(2026, 3, 1, 14, 0, 0);
      final json = {
        'id': 'member-1',
        'group_id': 'group-123',
        'user_id': 'user-456',
        'role': 'admin',
        'joined_at': joinedAt.toIso8601String(),
      };

      final member = GroupMemberModel.fromJson(json);

      expect(member.id, 'member-1');
      expect(member.groupId, 'group-123');
      expect(member.userId, 'user-456');
      expect(member.role, 'admin');
      expect(member.joinedAt, joinedAt);
    });

    test('toJson converts GroupMemberModel to JSON correctly', () {
      final joinedAt = DateTime(2026, 3, 1, 14, 0, 0);
      final member = GroupMemberModel(
        id: 'member-2',
        groupId: 'group-456',
        userId: 'user-789',
        role: 'member',
        joinedAt: joinedAt,
      );

      final json = member.toJson();

      expect(json['id'], 'member-2');
      expect(json['group_id'], 'group-456');
      expect(json['user_id'], 'user-789');
      expect(json['role'], 'member');
      expect(json['joined_at'], joinedAt.toIso8601String());
    });

    test('copyWith updates specified fields only', () {
      final joinedAt = DateTime(2026, 3, 1);
      final newJoinedAt = DateTime(2026, 4, 1);
      final original = GroupMemberModel(
        id: 'member-1',
        groupId: 'group-123',
        userId: 'user-456',
        role: 'member',
        joinedAt: joinedAt,
      );

      final updated = original.copyWith(role: 'admin', joinedAt: newJoinedAt);

      expect(updated.id, 'member-1');
      expect(updated.groupId, 'group-123');
      expect(updated.userId, 'user-456');
      expect(updated.role, 'admin');
      expect(updated.joinedAt, newJoinedAt);
    });
  });
}
