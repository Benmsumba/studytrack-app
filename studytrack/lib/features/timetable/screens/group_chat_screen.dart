import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/study_group_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/group_message_model.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({required this.groupId, super.key, this.group});

  final String groupId;
  final Map<String, dynamic>? group;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late final StudyGroupRepository _groupRepository;
  late final ProfileRepository _profileRepository;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  List<GroupMessageModel> _messages = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _groupRepository = getIt<StudyGroupRepository>();
    _profileRepository = getIt<ProfileRepository>();
    _init();
  }

  Future<void> _init() async {
    await _loadMessages();
    _groupRepository.subscribeToGroupMessages(widget.groupId).listen((
      messages,
    ) {
      if (!mounted) return;
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messagesResult = await _groupRepository.getGroupMessages(
      widget.groupId,
    );
    List<GroupMessageModel> messages = const [];
    messagesResult.fold((error) {}, (value) => messages = value);

    final profileResult = await _profileRepository.getCurrentProfile();
    Map<String, dynamic>? profile;
    profileResult.fold((error) {}, (value) => profile = value);
    _currentUserId = profile?['id']?.toString();

    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (_currentUserId == null || content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final sentResult = await _groupRepository.sendGroupMessage(
      groupId: widget.groupId,
      content: content,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    GroupMessageModel? sent;
    sentResult.fold((error) {}, (value) => sent = value);
    if (sent != null) {
      _messageController.clear();
      setState(() {
        _messages = [..._messages, sent!];
      });
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message.')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.group?['name']?.toString() ?? 'Group Chat';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final sender = message.senderId;
                      final content = message.content;
                      final isMine =
                          _currentUserId != null && sender == _currentUserId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                sender.isEmpty
                                    ? '?'
                                    : sender.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? AppColors.primary
                                      : AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sender,
                                      style: GoogleFonts.inter(
                                        color: isMine
                                            ? Colors.white
                                            : AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      content,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: AppColors.backgroundDark,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
