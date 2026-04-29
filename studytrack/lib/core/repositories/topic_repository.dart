import '../../models/topic_model.dart';
import '../../models/topic_rating_history_model.dart';
import '../utils/result.dart';

/// Abstract interface for topic operations
abstract class TopicRepository {
  /// Fetch all topics for a module
  Future<Result<List<TopicModel>>> getTopicsByModule(String moduleId);

  /// Fetch single topic by ID
  Future<Result<TopicModel?>> getTopicById(String topicId);

  /// Create new topic
  Future<Result<TopicModel>> createTopic({
    required String moduleId,
    required String name,
    required String description,
  });

  /// Update topic
  Future<Result<TopicModel>> updateTopic(TopicModel topic);

  /// Delete topic
  Future<Result<void>> deleteTopic(String topicId);

  /// Rate topic (1-10 scale)
  Future<Result<void>> rateTopic(String topicId, int rating);

  /// Get topic rating history
  Future<Result<List<TopicRatingHistoryModel>>> getTopicRatingHistory(
    String topicId,
  );

  /// Get all rated topics
  Future<Result<List<TopicModel>>> getRatedTopics({
    required int minRating,
    int? maxRating,
  });

  /// Update topic notes
  Future<Result<void>> updateTopicNotes(String topicId, String notes);

  /// Get topics due for spaced repetition review
  Future<Result<List<TopicModel>>> getTopicsDueForReview();

  /// Mark topic as reviewed
  Future<Result<void>> markTopicAsReviewed(String topicId);

  /// Sync topics with backend
  Future<Result<void>> syncTopics();
}
