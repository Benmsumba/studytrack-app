import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../voice_notes/widgets/voice_note_recorder_widget.dart';

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

  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];
  final Map<String, Map<String, dynamic>> _senderMeta = {};

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

  Future<void> _loadMessages() async {
    final messages = await _service.getGroupMessages(widget.groupId) ?? [];
    await _hydrateSenderMeta(messages);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
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

  Future<void> _sendMessage([String? quickText]) async {
    final user = _service.getCurrentUser();
    final content = (quickText ?? _messageController.text).trim();
    if (user == null || content.isEmpty || _sending) return;

    setState(() => _sending = true);
    final sent = await _service.sendMessage({
      'group_id': widget.groupId,
      'sender_id': user.id,
      'content': content,
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

  Future<void> _openVoiceRecorder() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: VoiceNoteRecorderWidget(
            topicId: null,
            allowUpload: false,
            title: 'Record a voice message',
            subtitle: 'Transcribe, then send to the group chat',
            onSaved: (result) async {
              final navigator = Navigator.of(sheetContext);
              await _sendMessage('🎙 Voice note: ${result.transcription}');
              if (navigator.mounted) {
                navigator.pop();
              }
            },
          ),
        ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
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
    final title = widget.group?['name']?.toString() ?? 'Group Chat';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
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
                      final me = _service.getCurrentUser();
                      final mine = me != null && sender == me.id;
                      final meta = _senderMeta[sender] ?? const {};
                      final displayName = meta['name']?.toString() ?? sender;
                      final course = meta['course']?.toString() ?? 'N/A';
                      final year = meta['year'] as int?;
                      final subtitle =
                          '$course${year == null ? '' : ' • Year $year'}';

                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppColors.primary
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: mine
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: mine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: _avatarColor(sender),
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
                                    crossAxisAlignment: mine
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: GoogleFonts.inter(
                                          color: mine
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
                  IconButton(
                    onPressed: _openVoiceRecorder,
                    icon: const Icon(Icons.mic_none_rounded),
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
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
