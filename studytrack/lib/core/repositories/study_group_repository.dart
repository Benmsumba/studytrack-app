import '../../models/group_member_model.dart';
import '../../models/group_message_model.dart';
import '../../models/study_group_model.dart';
import '../utils/result.dart';

/// Abstract interface for study group operations
abstract class StudyGroupRepository {
  /// Fetch all study groups for current user
  Future<Result<List<StudyGroupModel>>> getAllGroups();

  /// Fetch single group by ID
  Future<Result<StudyGroupModel?>> getGroupById(String groupId);

  /// Create new study group
  Future<Result<StudyGroupModel>> createGroup({
    required String name,
    required String description,
    String? topicId,
  });

  /// Update group details
  Future<Result<StudyGroupModel>> updateGroup(StudyGroupModel group);

  /// Delete study group
  Future<Result<void>> deleteGroup(String groupId);

  /// Join group using invite code
  Future<Result<void>> joinGroupByCode(String inviteCode);

  /// Leave group
  Future<Result<void>> leaveGroup(String groupId);

  /// Get group members
  Future<Result<List<GroupMemberModel>>> getGroupMembers(String groupId);

  /// Get group messages
  Future<Result<List<GroupMessageModel>>> getGroupMessages(String groupId);

  /// Send message to group
  Future<Result<GroupMessageModel>> sendGroupMessage({
    required String groupId,
    required String content,
    String? topicId,
  });

  /// Subscribe to real-time group updates
  Stream<List<GroupMessageModel>> subscribeToGroupMessages(String groupId);

  /// Invite user to group
  Future<Result<void>> inviteUserToGroup({
    required String groupId,
    required String userEmail,
  });

  /// Remove member from group
  Future<Result<void>> removeMemberFromGroup({
    required String groupId,
    required String userId,
  });

  /// Sync groups with backend
  Future<Result<void>> syncGroups();
}
