import 'package:flutter/foundation.dart';

import '../../../models/topic_model.dart';
import '../../../models/topic_rating_history_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../topic_repository.dart';

/// Implementation of TopicRepository using SupabaseService
class TopicRepositoryImpl implements TopicRepository {
  TopicRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  @override
  Future<Result<List<TopicModel>>> getTopicsByModule(String moduleId) async {
    try {
      final topics = await _supabaseService.getTopics(moduleId) ?? const [];
      return Success(topics);
    } on Object catch (e, stack) {
      debugPrint('getTopicsByModule error: $e');
      return Failure(
        DataException(message: 'Failed to fetch topics: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<List<TopicModel>>> getTopicsByModuleIds(
    List<String> moduleIds,
  ) async {
    try {
      final topics = await _supabaseService.getTopicsByModuleIds(moduleIds);
      return Success(topics);
    } on Object catch (e, stack) {
      debugPrint('getTopicsByModuleIds error: $e');
      return Failure(
        DataException(message: 'Failed to fetch topics: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<TopicModel?>> getTopicById(String topicId) async {
    try {
      final topic = await _supabaseService.getTopic(topicId);
      if (topic == null) {
        throw DataException(message: 'Topic not found');
      }
      return Success(topic);
    } on Object catch (e, stack) {
      debugPrint('getTopicById error: $e');
      return Failure(
        DataException(message: 'Failed to fetch topic: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<TopicModel>> createTopic({
    required String moduleId,
    required String name,
    required String description,
  }) async {
    try {
      final topic = await _supabaseService.createTopic(
        moduleId: moduleId,
        name: name,
        description: description,
      );
      return Success(topic);
    } on Object catch (e, stack) {
      debugPrint('createTopic error: $e');
      return Failure(
        DataException(message: 'Failed to create topic: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<TopicModel>> updateTopic(TopicModel topic) async {
    try {
      final updated = await _supabaseService.updateTopic(topic);
      return Success(updated);
    } on Object catch (e, stack) {
      debugPrint('updateTopic error: $e');
      return Failure(
        DataException(message: 'Failed to update topic: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> deleteTopic(String topicId) async {
    try {
      await _supabaseService.deleteTopic(topicId);
      return const Success(null);
    } on Object catch (e, stack) {
      debugPrint('deleteTopic error: $e');
      return Failure(
        DataException(message: 'Failed to delete topic: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> rateTopic(String topicId, int rating) async {
    try {
      await _supabaseService.rateTopic(topicId, rating);
      return const Success(null);
    } on Object catch (e, stack) {
      debugPrint('rateTopic error: $e');
      return Failure(
        DataException(message: 'Failed to rate topic: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<List<TopicRatingHistoryModel>>> getTopicRatingHistory(
    String topicId,
  ) async {
    try {
      final history =
          await _supabaseService.getTopicRatingHistory(topicId) ?? const [];
      return Success(history.map(TopicRatingHistoryModel.fromJson).toList());
    } catch (e, stack) {
      debugPrint('getTopicRatingHistory error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch rating history: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<TopicModel>>> getRatedTopics({
    required int minRating,
    int? maxRating,
  }) async {
    try {
      final topics = await _supabaseService.getRatedTopics(
        minRating: minRating,
        maxRating: maxRating,
      );
      return Success(topics);
    } catch (e, stack) {
      debugPrint('getRatedTopics error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch rated topics: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateTopicNotes(String topicId, String notes) async {
    try {
      await _supabaseService.updateTopicNotes(topicId, notes);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('updateTopicNotes error: $e');
      return Failure(
        DataException(message: 'Failed to update notes: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<List<TopicModel>>> getTopicsDueForReview() async {
    try {
      final topics = await _supabaseService.getTopicsDueForReview();
      return Success(topics);
    } catch (e, stack) {
      debugPrint('getTopicsDueForReview error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch topics due for review: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markTopicAsReviewed(String topicId) async {
    try {
      await _supabaseService.markTopicAsReviewed(topicId);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('markTopicAsReviewed error: $e');
      return Failure(
        DataException(
          message: 'Failed to mark topic as reviewed: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> syncTopics() async {
    try {
      // Sync handled by offline sync service
      return const Success(null);
    } catch (e, stack) {
      debugPrint('syncTopics error: $e');
      return Failure(
        DataException(message: 'Failed to sync topics: $e', stackTrace: stack),
      );
    }
  }
}
