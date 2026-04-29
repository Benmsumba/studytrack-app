import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/models/group_message_model.dart';

void main() {
  group('GroupMessageModel', () {
    test('fromJson creates GroupMessageModel with all fields', () {
      final createdAt = DateTime(2026, 4, 20, 15, 30, 0);
      final json = {
        'id': 'msg-1',
        'group_id': 'group-123',
        'topic_id': 'topic-456',
        'sender_id': 'user-789',
        'content': 'Can everyone solve problem 5?',
        'message_type': 'discussion',
        'created_at': createdAt.toIso8601String(),
      };

      final message = GroupMessageModel.fromJson(json);

      expect(message.id, 'msg-1');
      expect(message.groupId, 'group-123');
      expect(message.topicId, 'topic-456');
      expect(message.senderId, 'user-789');
      expect(message.content, 'Can everyone solve problem 5?');
      expect(message.messageType, 'discussion');
      expect(message.createdAt, createdAt);
    });

    test('fromJson handles null groupId and topicId', () {
      final createdAt = DateTime(2026, 4, 20, 15, 30, 0);
      final json = {
        'id': 'msg-2',
        'group_id': null,
        'topic_id': null,
        'sender_id': 'user-111',
        'content': 'General announcement',
        'message_type': 'announcement',
        'created_at': createdAt.toIso8601String(),
      };

      final message = GroupMessageModel.fromJson(json);

      expect(message.groupId, isNull);
      expect(message.topicId, isNull);
      expect(message.senderId, 'user-111');
    });

    test('toJson converts GroupMessageModel to JSON correctly', () {
      final createdAt = DateTime(2026, 4, 20, 15, 30, 0);
      final message = GroupMessageModel(
        id: 'msg-3',
        groupId: 'group-456',
        topicId: 'topic-789',
        senderId: 'user-999',
        content: 'Here is the solution',
        messageType: 'solution',
        createdAt: createdAt,
      );

      final json = message.toJson();

      expect(json['id'], 'msg-3');
      expect(json['group_id'], 'group-456');
      expect(json['topic_id'], 'topic-789');
      expect(json['sender_id'], 'user-999');
      expect(json['content'], 'Here is the solution');
      expect(json['message_type'], 'solution');
      expect(json['created_at'], createdAt.toIso8601String());
    });

    test('copyWith updates specified fields only', () {
      final createdAt = DateTime(2026, 4, 20);
      final original = GroupMessageModel(
        id: 'msg-1',
        groupId: 'group-1',
        topicId: 'topic-1',
        senderId: 'user-1',
        content: 'Original message',
        messageType: 'discussion',
        createdAt: createdAt,
      );

      final updated = original.copyWith(
        content: 'Edited message',
        messageType: 'edited',
      );

      expect(updated.id, 'msg-1');
      expect(updated.groupId, 'group-1');
      expect(updated.content, 'Edited message');
      expect(updated.messageType, 'edited');
      expect(updated.createdAt, createdAt);
    });
  });
}
