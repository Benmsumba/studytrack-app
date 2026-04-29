class GroupMessageModel {
  factory GroupMessageModel.fromJson(Map<String, dynamic> json) =>
      GroupMessageModel(
        id: json['id'] as String,
        groupId: json['group_id'] as String?,
        topicId: json['topic_id'] as String?,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        messageType: json['message_type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  const GroupMessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.groupId,
    this.topicId,
  });

  final String id;
  final String? groupId;
  final String? topicId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'topic_id': topicId,
    'sender_id': senderId,
    'content': content,
    'message_type': messageType,
    'created_at': createdAt.toIso8601String(),
  };

  GroupMessageModel copyWith({
    String? id,
    String? groupId,
    String? topicId,
    String? senderId,
    String? content,
    String? messageType,
    DateTime? createdAt,
  }) => GroupMessageModel(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    topicId: topicId ?? this.topicId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    messageType: messageType ?? this.messageType,
    createdAt: createdAt ?? this.createdAt,
  );
}
