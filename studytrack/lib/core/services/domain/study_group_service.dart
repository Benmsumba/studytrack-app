import 'dart:async';
import '../../utils/app_logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/group_member_model.dart';
import '../../../models/group_message_model.dart';
import '../../../models/study_group_model.dart';
import '../../utils/helpers.dart';
import '../offline_sync_service.dart';
import 'domain_service_base.dart';

class StudyGroupService extends DomainServiceBase {
  StudyGroupService(this._client, OfflineSyncService offlineSync) : super(offlineSync);

  final SupabaseClient _client;
  SupabaseClient get client => _client;

// ---------------------------------------------------------------------------
// STUDY GROUPS
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>?> createGroup(
  String name,
  String description,
  String createdBy,
) async {
  try {
    final groupId = newId();
    final groupPayload = {
      'id': groupId,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': DateTime.now().toIso8601String(),
    };
    final membershipPayload = {
      'id': newId(),
      'group_id': groupId,
      'user_id': createdBy,
      'role': 'admin',
      'joined_at': DateTime.now().toIso8601String(),
    };

    if (await isOnline()) {
      final response = await client
          .from('study_groups')
          .insert(groupPayload)
          .select()
          .maybeSingle();

      if (response != null) {
        await client.from('group_members').insert(membershipPayload);
        await cacheRecord(
          'study_groups',
          response['id'].toString(),
          response,
        );
      }

      return response;
    }

    await queueChange(
      'study_groups',
      'insert',
      groupPayload,
      recordId: groupId,
    );
    await queueChange(
      'group_members',
      'insert',
      membershipPayload,
      recordId: membershipPayload['id'].toString(),
    );
    await cacheRecord('study_groups', groupId, groupPayload);
    return groupPayload;
  } catch (error) {
    AppLogger.warning('createGroup error', error: error);
    return null;
  }
}

Future<Map<String, dynamic>?> joinGroup(
  String inviteCode,
  String userId,
) async {
  try {
    if (await isOnline()) {
      final group = await client
          .from('study_groups')
          .select()
          .eq('invite_code', inviteCode.toUpperCase())
          .maybeSingle();

      if (group == null) {
        return null;
      }

      final response = await client
          .from('group_members')
          .upsert({
            'group_id': group['id'],
            'user_id': userId,
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();
      return response;
    }

    await queueChange('group_members', 'joinGroup', {
      'invite_code': inviteCode.toUpperCase(),
      'user_id': userId,
    });
    return {
      'invite_code': inviteCode.toUpperCase(),
      'user_id': userId,
      'status': 'pending',
    };
  } catch (error) {
    AppLogger.warning('joinGroup error', error: error);
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getMyGroups(String userId) async {
  try {
    if (await isOnline()) {
      // Fetch all memberships for this user with their groups
      final memberships =
          ((await client
                      .from('group_members')
                      .select('''
                        *,
                        study_groups(*)
                      ''')
                      .eq('user_id', userId)
                      .order('joined_at'))
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();

      await cacheList('my_groups', userId, memberships);
      return memberships;
    }

    return cachedList('my_groups', userId);
  } catch (error) {
    AppLogger.warning('getMyGroups error', error: error);
    return cachedList('my_groups', userId);
  }
}

Future<List<Map<String, dynamic>>?> getGroupMembers(String groupId) async {
  try {
    if (await isOnline()) {
      final response = await client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .order('joined_at');

      final currentUser = getCurrentUser();
      final currentProfile = currentUser == null
          ? null
          : await getProfile(currentUser.id);

      final rows = (response as List<dynamic>).map((item) {
        final member = item as Map<String, dynamic>;
        final isCurrentUser = member['user_id'] == currentUser?.id;
        if (isCurrentUser) {
          return {
            ...member,
            'name': currentProfile?['name']?.toString() ?? 'You',
            'course': currentProfile?['course']?.toString() ?? 'N/A',
            'year_level': (currentProfile?['year_level'] as num?)?.toInt(),
          };
        }

        final rawUserId = member['user_id']?.toString() ?? '';
        final anonId = Helpers.anonymizeUserId(rawUserId);
        return {
          ...member,
          'name': 'Member $anonId',
          'course': 'Private',
          'year_level': null,
        };
      }).toList();

      await cacheList('group_members', groupId, rows);
      return rows;
    }

    return cachedList('group_members', groupId);
  } catch (error) {
    AppLogger.warning('getGroupMembers error', error: error);
    return cachedList('group_members', groupId);
  }
}

Future<bool?> removeGroupMember(String groupId, String memberUserId) async {
  try {
    if (await isOnline()) {
      await client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', memberUserId);
      return true;
    }

    await queueChange('group_members', 'removeGroupMember', {
      'group_id': groupId,
      'user_id': memberUserId,
    });
    return true;
  } catch (error) {
    AppLogger.warning('removeGroupMember error', error: error);
    return null;
  }
}

Future<bool?> leaveGroup(String groupId, String userId) async {
  try {
    if (await isOnline()) {
      await client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
      return true;
    }

    await queueChange('group_members', 'leaveGroup', {
      'group_id': groupId,
      'user_id': userId,
    });
    return true;
  } catch (error) {
    AppLogger.warning('leaveGroup error', error: error);
    return null;
  }
}

}
