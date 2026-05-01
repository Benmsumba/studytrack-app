import '../utils/result.dart';

/// Abstract interface for topic chat operations
abstract class TopicChatRepository {
  /// Fetch topic messages
  Future<Result<List<Map<String, dynamic>>>> getTopicMessages(String topicId);

  /// Send a topic message
  Future<Result<Map<String, dynamic>>> sendTopicMessage({
    required String topicId,
    required String senderId,
    required String content,
    required String messageType,
  });

  /// Subscribe to topic message updates
  Future<void> subscribeToTopicMessages(
    String topicId,
    void Function(Map<String, dynamic> message) onMessage,
  );

  /// Unsubscribe from topic message updates
  void unsubscribeFromTopicMessages();
}
