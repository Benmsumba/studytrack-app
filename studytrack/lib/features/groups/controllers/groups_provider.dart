import 'package:flutter/foundation.dart';

import '../../../core/repositories/study_group_repository.dart';
import '../../../core/utils/app_exception.dart';
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

  /// Auth is resolved inside the repository — no userId required here.
  Future<GroupActionResult> loadGroups() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _studyGroupRepository.getAllGroups();

      return result.fold(
        (error) {
          _errorMessage = error.message;
          return GroupActionResult(
            success: false,
            statusCode: _statusCode(error),
            message: error.message,
          );
        },
        (groups) {
          _myGroups = groups;
          return const GroupActionResult(
            success: true,
            statusCode: 200,
            message: 'Groups loaded successfully.',
          );
        },
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
      return _validationFailure('Group name is required.');
    }

    _errorMessage = null;
    final result = await _studyGroupRepository.createGroup(
      name: nameText,
      description: description.trim(),
    );

    return result.fold(
      (error) {
        _errorMessage = error.message;
        notifyListeners();
        return GroupActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (created) {
        _myGroups = [..._myGroups, created];
        _selectedGroup = created;
        notifyListeners();
        return const GroupActionResult(
          success: true,
          statusCode: 201,
          message: 'Group created successfully.',
        );
      },
    );
  }

  Future<GroupActionResult> joinGroup({required String inviteCode}) async {
    final code = inviteCode.trim();
    if (code.isEmpty) {
      return _validationFailure('Invite code is required.');
    }

    _errorMessage = null;
    final result = await _studyGroupRepository.joinGroupByCode(code);

    return result.fold(
      (error) {
        _errorMessage = error.message;
        notifyListeners();
        return GroupActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (_) async {
        // Reload the groups list after a successful join.
        await loadGroups();
        return const GroupActionResult(
          success: true,
          statusCode: 200,
          message: 'Successfully joined group.',
        );
      },
    );
  }

  Future<GroupActionResult> sendMessage({
    required String groupId,
    required String content,
    String? topicId,
  }) async {
    if (groupId.trim().isEmpty) {
      return _validationFailure('Group ID is required.');
    }
    if (content.trim().isEmpty) {
      return _validationFailure('Message content is required.');
    }

    _errorMessage = null;
    final result = await _studyGroupRepository.sendGroupMessage(
      groupId: groupId,
      content: content.trim(),
      topicId: topicId,
    );

    return result.fold(
      (error) {
        _errorMessage = error.message;
        notifyListeners();
        return GroupActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (messageModel) {
        _messages = [..._messages, messageModel];
        notifyListeners();
        return const GroupActionResult(
          success: true,
          statusCode: 201,
          message: 'Message sent successfully.',
        );
      },
    );
  }

  void subscribeToMessages({required String groupId}) {
    if (groupId.isEmpty) return;

    _studyGroupRepository.subscribeToGroupMessages(groupId).listen(
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

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  GroupActionResult _validationFailure(String message) {
    _errorMessage = message;
    notifyListeners();
    return GroupActionResult(success: false, statusCode: 422, message: message);
  }

  int _statusCode(AppException error) => switch (error) {
    ValidationException() => 422,
    AuthException() => 401,
    OfflineException() => 503,
    _ => 500,
  };

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
