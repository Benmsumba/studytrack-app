import 'package:flutter/foundation.dart';

import '../../../models/group_member_model.dart';
import '../../../models/group_message_model.dart';
import '../../../models/study_group_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../study_group_repository.dart';

/// Implementation of StudyGroupRepository using SupabaseService
class StudyGroupRepositoryImpl implements StudyGroupRepository {
  StudyGroupRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  @override
  Future<Result<List<StudyGroupModel>>> getAllGroups() async {
    try {
      final groups = await _supabaseService.getStudyGroups();
      return Success(groups);
    } catch (e, stack) {
      debugPrint('getAllGroups error: $e');
      return Failure(
        DataException(message: 'Failed to fetch groups: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<StudyGroupModel?>> getGroupById(String groupId) async {
    try {
      final group = await _supabaseService.getStudyGroup(groupId);
      return Success(group);
    } catch (e, stack) {
      debugPrint('getGroupById error: $e');
      return Failure(
        DataException(message: 'Failed to fetch group: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<StudyGroupModel>> createGroup({
    required String name,
    required String description,
    String? topicId,
  }) async {
    try {
      final group = await _supabaseService.createStudyGroup(
        name: name,
        description: description,
        topicId: topicId,
      );
      return Success(group);
    } catch (e, stack) {
      debugPrint('createGroup error: $e');
      return Failure(
        DataException(message: 'Failed to create group: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<StudyGroupModel>> updateGroup(StudyGroupModel group) async {
    try {
      final updated = await _supabaseService.updateStudyGroup(group);
      return Success(updated);
    } catch (e, stack) {
      debugPrint('updateGroup error: $e');
      return Failure(
        DataException(message: 'Failed to update group: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> deleteGroup(String groupId) async {
    try {
      await _supabaseService.deleteStudyGroup(groupId);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('deleteGroup error: $e');
      return Failure(
        DataException(message: 'Failed to delete group: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> joinGroupByCode(String inviteCode) async {
    try {
      await _supabaseService.joinGroupByCode(inviteCode);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('joinGroupByCode error: $e');
      return Failure(
        DataException(message: 'Failed to join group: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> leaveGroup(String groupId) async {
    try {
      await _supabaseService.leaveStudyGroup(groupId);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('leaveGroup error: $e');
      return Failure(
        DataException(message: 'Failed to leave group: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<List<GroupMemberModel>>> getGroupMembers(String groupId) async {
    try {
      final members = await _supabaseService.getGroupMembers(groupId);
      return Success(members);
    } catch (e, stack) {
      debugPrint('getGroupMembers error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch group members: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<GroupMessageModel>>> getGroupMessages(
    String groupId,
  ) async {
    try {
      final messages = await _supabaseService.getGroupMessages(groupId);
      return Success(messages);
    } catch (e, stack) {
      debugPrint('getGroupMessages error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch group messages: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<GroupMessageModel>> sendGroupMessage({
    required String groupId,
    required String content,
    String? topicId,
  }) async {
    try {
      final message = await _supabaseService.sendGroupMessage(
        groupId: groupId,
        content: content,
        topicId: topicId,
      );
      return Success(message);
    } catch (e, stack) {
      debugPrint('sendGroupMessage error: $e');
      return Failure(
        DataException(message: 'Failed to send message: $e', stackTrace: stack),
      );
    }
  }

  @override
  Stream<List<GroupMessageModel>> subscribeToGroupMessages(String groupId) =>
      _supabaseService.subscribeToGroupMessages(groupId);

  @override
  Future<Result<void>> inviteUserToGroup({
    required String groupId,
    required String userEmail,
  }) async {
    try {
      await _supabaseService.inviteUserToGroup(
        groupId: groupId,
        userEmail: userEmail,
      );
      return const Success(null);
    } catch (e, stack) {
      debugPrint('inviteUserToGroup error: $e');
      return Failure(
        DataException(message: 'Failed to invite user: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _supabaseService.removeGroupMember(
        groupId: groupId,
        userId: userId,
      );
      return const Success(null);
    } catch (e, stack) {
      debugPrint('removeMemberFromGroup error: $e');
      return Failure(
        DataException(
          message: 'Failed to remove member: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> syncGroups() async {
    try {
      // Sync handled by offline sync service
      return const Success(null);
    } catch (e, stack) {
      debugPrint('syncGroups error: $e');
      return Failure(
        DataException(message: 'Failed to sync groups: $e', stackTrace: stack),
      );
    }
  }
}
