import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/group_message_model.dart';
import '../../../models/study_group_model.dart';

class GroupsProvider extends ChangeNotifier {
  GroupsProvider({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  final SupabaseService _supabaseService;

  List<StudyGroupModel> _myGroups = const [];
  StudyGroupModel? _selectedGroup;
  List<GroupMessageModel> _messages = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<StudyGroupModel> get myGroups => _myGroups;
  StudyGroupModel? get selectedGroup => _selectedGroup;
  List<GroupMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadGroups(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final rows = await _supabaseService.getMyGroups(userId) ?? const [];
      _myGroups = rows
          .map((row) => row['study_groups'])
          .whereType<Map<String, dynamic>>()
          .map(StudyGroupModel.fromJson)
          .toList(growable: false);
    } catch (error) {
      _errorMessage = 'Failed to load groups: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createGroup({
    required String name,
    required String createdBy,
    String description = '',
  }) async {
    _errorMessage = null;

    final created = await _supabaseService.createGroup(
      name,
      description,
      createdBy,
    );
    if (created == null) {
      _errorMessage = 'Failed to create group.';
      notifyListeners();
      return;
    }

    _myGroups = [..._myGroups, StudyGroupModel.fromJson(created)];
    notifyListeners();
  }

  Future<void> joinGroup({
    required String inviteCode,
    required String userId,
  }) async {
    _errorMessage = null;
    final joined = await _supabaseService.joinGroup(inviteCode, userId);
    if (joined == null) {
      _errorMessage = 'Could not join group. Check invite code.';
      notifyListeners();
      return;
    }

    await loadGroups(userId);
  }

  Future<void> sendMessage({
    required String senderId,
    required String content,
    String? groupId,
    String? topicId,
  }) async {
    final sent = await _supabaseService.sendMessage({
      'group_id': groupId,
      'topic_id': topicId,
      'sender_id': senderId,
      'content': content,
      'message_type': 'text',
    });

    if (sent == null) {
      _errorMessage = 'Failed to send message.';
      notifyListeners();
      return;
    }

    final messageModel = GroupMessageModel.fromJson(sent);
    _messages = [..._messages, messageModel];
    notifyListeners();
  }

  Future<void> subscribeToMessages({String? groupId, String? topicId}) async {
    await _supabaseService.unsubscribeFromMessages();

    if (groupId != null && groupId.isNotEmpty) {
      await _supabaseService.subscribeToGroupMessages(groupId, _handleIncoming);
      return;
    }

    if (topicId != null && topicId.isNotEmpty) {
      await _supabaseService.subscribeToMessages(topicId, _handleIncoming);
    }
  }

  void setSelectedGroup(StudyGroupModel? group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void _handleIncoming(Map<String, dynamic> row) {
    final incoming = GroupMessageModel.fromJson(row);
    _messages = [..._messages, incoming];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _supabaseService.unsubscribeFromMessages();
    super.dispose();
  }
}
