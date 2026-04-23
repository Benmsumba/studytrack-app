class GroupMessageModel {
  const GroupMessageModel({
    required this.id,
    this.groupId,
    this.topicId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.createdAt,
  });

  final String id;
  final String? groupId;
  final String? topicId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    return GroupMessageModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String?,
      topicId: json['topic_id'] as String?,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'topic_id': topicId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GroupMessageModel copyWith({
    String? id,
    String? groupId,
    String? topicId,
    String? senderId,
    String? content,
    String? messageType,
    DateTime? createdAt,
  }) {
    return GroupMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      topicId: topicId ?? this.topicId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}