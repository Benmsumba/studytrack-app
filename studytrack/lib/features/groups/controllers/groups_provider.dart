import 'package:flutter/foundation.dart';

import '../../../core/repositories/study_group_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/group_message_model.dart';
import '../../../models/study_group_model.dart';

class GroupActionResult {
  const GroupActionResult({
    required this.success,
    required this.statusCode,
    required this.message,
  });

  final bool success;
  final int statusCode;
  final String message;
}

class GroupsProvider extends ChangeNotifier {
  GroupsProvider({StudyGroupRepository? studyGroupRepository})
    : _studyGroupRepository =
          studyGroupRepository ?? getIt<StudyGroupRepository>();

  final StudyGroupRepository _studyGroupRepository;

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

  Future<GroupActionResult> loadGroups(String userId) async {
    if (userId.trim().isEmpty) {
      _errorMessage = 'User context is missing. Please sign in again.';
      notifyListeners();
      return const GroupActionResult(
        success: false,
        statusCode: 401,
        message: 'User context is missing. Please sign in again.',
      );
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _studyGroupRepository.getAllGroups();

      if (result is Failure<List<StudyGroupModel>>) {
        _errorMessage = result.error.message;
        return GroupActionResult(
          success: false,
          statusCode: 500,
          message: _errorMessage ?? 'Failed to load groups.',
        );
      }

      if (result is Success<List<StudyGroupModel>>) {
        _myGroups = result.data;
      }

      return const GroupActionResult(
        success: true,
        statusCode: 200,
        message: 'Groups loaded successfully.',
      );
    } catch (error) {
      _errorMessage = 'Failed to load groups: $error';
      return GroupActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage!,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<GroupActionResult> createGroup({
    required String name,
    required String description,
  }) async {
    final nameText = name.trim();
    if (nameText.isEmpty) {
      _errorMessage = 'Group name is required.';
      notifyListeners();
      return const GroupActionResult(
        success: false,
        statusCode: 422,
        message: 'Group name is required.',
      );
    }

    _errorMessage = null;
    final result = await _studyGroupRepository.createGroup(
      name: nameText,
      description: description.trim(),
    );

    if (result is Failure<StudyGroupModel>) {
      _errorMessage = result.error.message;
      notifyListeners();
      return GroupActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage ?? 'Failed to create group.',
      );
    }

    if (result is Success<StudyGroupModel>) {
      final created = result.data;
      _myGroups = [..._myGroups, created];
      _selectedGroup = created;
      notifyListeners();
    }

    return const GroupActionResult(
      success: true,
      statusCode: 201,
      message: 'Group created successfully.',
    );
  }

  Future<GroupActionResult> joinGroup({required String inviteCode}) async {
    if (inviteCode.trim().isEmpty) {
      _errorMessage = 'Invite code is required.';
      notifyListeners();
      return const GroupActionResult(
        success: false,
        statusCode: 422,
        message: 'Invite code is required.',
      );
    }

    _errorMessage = null;
    final result = await _studyGroupRepository.joinGroupByCode(inviteCode);

    if (result is Failure<void>) {
      _errorMessage = result.error.message;
      return GroupActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage ?? 'Could not join group. Check invite code.',
      );
    }

    // Reload groups after successful join
    await loadGroups('');

    return const GroupActionResult(
      success: true,
      statusCode: 200,
      message: 'Successfully joined group.',
    );
  }

  Future<GroupActionResult> sendMessage({
    required String groupId,
    required String content,
    String? topicId,
  }) async {
    if (groupId.trim().isEmpty) {
      return const GroupActionResult(
        success: false,
        statusCode: 422,
        message: 'Group ID is required.',
      );
    }

    if (content.trim().isEmpty) {
      return const GroupActionResult(
        success: false,
        statusCode: 422,
        message: 'Message content is required.',
      );
    }

    _errorMessage = null;
    final result = await _studyGroupRepository.sendGroupMessage(
      groupId: groupId,
      content: content.trim(),
      topicId: topicId,
    );

    if (result is Failure<GroupMessageModel>) {
      _errorMessage = result.error.message;
      return GroupActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage ?? 'Failed to send message.',
      );
    }

    if (result is Success<GroupMessageModel>) {
      final messageModel = result.data;
      _messages = [..._messages, messageModel];
      notifyListeners();
    }

    return const GroupActionResult(
      success: true,
      statusCode: 201,
      message: 'Message sent successfully.',
    );
  }

  /// Subscribe to real-time group messages
  void subscribeToMessages({required String groupId}) {
    if (groupId.isEmpty) {
      return;
    }

    // Listen to the repository's message stream and update local state
    _studyGroupRepository
        .subscribeToGroupMessages(groupId)
        .listen(
          (messages) {
            _messages = messages;
            notifyListeners();
          },
          onError: (Object error) {
            _errorMessage = 'Failed to subscribe to messages: $error';
            notifyListeners();
          },
        );
  }

  void setSelectedGroup(StudyGroupModel? group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
