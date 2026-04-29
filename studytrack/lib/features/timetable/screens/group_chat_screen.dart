import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({required this.groupId, super.key, this.group});

  final String groupId;
  final Map<String, dynamic>? group;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadMessages();
    await _service.subscribeToGroupMessages(widget.groupId, (message) {
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _service.unsubscribeFromMessages();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messages = await _service.getGroupMessages(widget.groupId) ?? [];
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final user = _service.getCurrentUser();
    final content = _messageController.text.trim();
    if (user == null || content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final sent = await _service.sendMessage({
      'group_id': widget.groupId,
      'sender_id': user.id,
      'content': content,
      'message_type': 'text',
    });

    if (!mounted) return;
    setState(() => _isSending = false);

    if (sent != null) {
      _messageController.clear();
      setState(() {
        _messages = [..._messages, sent];
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
                      final sender =
                          message['sender_id']?.toString() ?? 'unknown';
                      final content = message['content']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                sender.substring(0, 1).toUpperCase(),
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
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sender,
                                      style: GoogleFonts.inter(
                                        color: AppColors.primary,
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
