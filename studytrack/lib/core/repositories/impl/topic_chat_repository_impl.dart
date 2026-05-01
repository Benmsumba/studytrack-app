import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../topic_chat_repository.dart';

/// Implementation of TopicChatRepository using SupabaseService
class TopicChatRepositoryImpl implements TopicChatRepository {
  TopicChatRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  @override
  Future<Result<List<Map<String, dynamic>>>> getTopicMessages(
    String topicId,
  ) async {
    try {
      final messages = await _supabaseService.getTopicMessages(topicId) ?? [];
      return Success(messages);
    } catch (e, stack) {
      debugPrint('getTopicMessages error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch topic messages: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> sendTopicMessage({
    required String topicId,
    required String senderId,
    required String content,
    required String messageType,
  }) async {
    try {
      final message = await _supabaseService.sendMessage({
        'topic_id': topicId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
      });
      if (message == null) {
        return Failure(DataException(message: 'Failed to send topic message'));
      }
      return Success(message);
    } catch (e, stack) {
      debugPrint('sendTopicMessage error: $e');
      return Failure(
        DataException(
          message: 'Failed to send topic message: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<void> subscribeToTopicMessages(
    String topicId,
    void Function(Map<String, dynamic> message) onMessage,
  ) async {
    await _supabaseService.subscribeToMessages(topicId, onMessage);
  }

  @override
  void unsubscribeFromTopicMessages() {
    _supabaseService.unsubscribeFromMessages();
  }
}
