import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class TopicChatScreen extends StatefulWidget {
  const TopicChatScreen({
    super.key,
    required this.topicId,
    this.topicName,
    this.moduleName,
    this.groupName,
  });

  final String topicId;
  final String? topicName;
  final String? moduleName;
  final String? groupName;

  @override
  State<TopicChatScreen> createState() => _TopicChatScreenState();
}

class _TopicChatScreenState extends State<TopicChatScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];
  final Set<String> _struggleUserIds = {};
  final Map<String, Map<String, dynamic>> _senderMeta = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadMessages();
    await _service.subscribeToMessages(widget.topicId, (message) {
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
      });
      _refreshFlagsFromMessages();
      _scrollToBottom();
    });
  }

  Future<void> _loadMessages() async {
    final messages = await _service.getTopicMessages(widget.topicId) ?? [];
    await _hydrateSenderMeta(messages);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
    _refreshFlagsFromMessages();
    _scrollToBottom();
  }

  Future<void> _hydrateSenderMeta(List<Map<String, dynamic>> messages) async {
    final me = _service.getCurrentUser();
    if (me == null) return;

    final profile = await _service.getProfile(me.id);
    for (final message in messages) {
      final senderId = message['sender_id']?.toString() ?? '';
      if (senderId.isEmpty || _senderMeta.containsKey(senderId)) continue;
      if (senderId == me.id) {
        _senderMeta[senderId] = {
          'name': profile?['name']?.toString() ?? 'You',
          'course': profile?['course']?.toString() ?? 'N/A',
          'year': (profile?['year_level'] as num?)?.toInt(),
        };
      } else {
        final short = senderId.length > 8 ? senderId.substring(0, 8) : senderId;
        _senderMeta[senderId] = {
          'name': 'Member $short',
          'course': 'Private',
          'year': null,
        };
      }
    }
  }

  Color _avatarColor(String senderId) {
    final hash = senderId.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.6, 0.85).toColor();
  }

  void _refreshFlagsFromMessages() {
    final flags = <String>{};
    for (final message in _messages) {
      final type = message['message_type']?.toString() ?? 'text';
      final content = message['content']?.toString() ?? '';
      if (type == 'system' && content.startsWith('[STRUGGLE_FLAG]')) {
        final sender = message['sender_id']?.toString() ?? '';
        if (sender.isNotEmpty) flags.add(sender);
      }
    }
    setState(() {
      _struggleUserIds
        ..clear()
        ..addAll(flags);
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final user = _service.getCurrentUser();
    final text = (quickText ?? _messageController.text).trim();

    if (user == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final sent = await _service.sendMessage({
      'topic_id': widget.topicId,
      'sender_id': user.id,
      'content': text,
      'message_type': 'text',
    });
    setState(() => _sending = false);

    if (!mounted) return;
    if (sent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message.')));
      return;
    }

    _messageController.clear();
    await _hydrateSenderMeta([sent]);
    setState(() {
      _messages = [..._messages, sent];
    });
    _scrollToBottom();
  }

  Future<void> _flagStruggleAnonymously() async {
    final user = _service.getCurrentUser();
    if (user == null) return;

    final sent = await _service.sendMessage({
      'topic_id': widget.topicId,
      'sender_id': user.id,
      'content': '[STRUGGLE_FLAG] I need help with this topic',
      'message_type': 'system',
    });

    if (sent != null && mounted) {
      await _hydrateSenderMeta([sent]);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sent];
      });
      _refreshFlagsFromMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anonymous struggle flag submitted.')),
      );
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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _service.unsubscribeFromMessages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.topicName?.trim().isNotEmpty == true
        ? widget.topicName!
        : 'Topic Chat';
    final subtitle =
        '${widget.moduleName ?? 'Module'} • ${widget.groupName ?? 'Group'}';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_struggleUserIds.length >= 3)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'Multiple people are struggling with this topic.',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _promptChip('Anyone struggling with this?'),
                  const SizedBox(width: 8),
                  _promptChip('Can someone explain?'),
                  const SizedBox(width: 8),
                  _promptChip('Exam question tip 💡'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final senderId = msg['sender_id']?.toString() ?? '';
                      final content = msg['content']?.toString() ?? '';
                      final type = msg['message_type']?.toString() ?? 'text';
                      final created = msg['created_at']?.toString() ?? '';

                      if (type == 'system' &&
                          content.startsWith('[STRUGGLE_FLAG]')) {
                        return const SizedBox.shrink();
                      }

                      final me = _service.getCurrentUser();
                      final isMine = me != null && senderId == me.id;
                      final meta = _senderMeta[senderId] ?? const {};
                      final displayName = meta['name']?.toString() ?? 'Member';
                      final course = meta['course']?.toString() ?? 'N/A';
                      final year = meta['year'] as int?;
                      final subtitle =
                          '$course${year == null ? '' : ' • Year $year'}';

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMine
                                ? AppColors.primary
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: isMine
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: _avatarColor(senderId),
                                    child: Text(
                                      displayName.substring(0, 1).toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: isMine
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: GoogleFonts.inter(
                                          color: isMine
                                              ? Colors.white70
                                              : AppColors.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        subtitle,
                                        style: GoogleFonts.inter(
                                          color: Colors.white60,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                content,
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                created.isEmpty
                                    ? ''
                                    : created
                                          .replaceFirst('T', ' ')
                                          .substring(0, 16),
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ask or share something...',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _sendMessage,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _flagStruggleAnonymously,
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text("I'm struggling with this"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promptChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () => _sendMessage(text),
      backgroundColor: AppColors.surfaceDark,
      labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      side: BorderSide(color: AppColors.border),
    );
  }
}
