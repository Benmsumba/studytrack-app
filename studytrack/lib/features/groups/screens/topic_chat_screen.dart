import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/topic_chat_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/glass_card.dart';
import '../../voice_notes/widgets/voice_note_recorder_widget.dart';

class TopicChatScreen extends StatefulWidget {
  const TopicChatScreen({
    required this.topicId,
    super.key,
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
  late final TopicChatRepository _topicChatRepository;
  late final ProfileRepository _profileRepository;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];
  final Set<String> _struggleUserIds = {};
  final Map<String, Map<String, dynamic>> _senderMeta = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _topicChatRepository = getIt<TopicChatRepository>();
    _profileRepository = getIt<ProfileRepository>();
    _init();
  }

  Future<void> _init() async {
    await _loadMessages();
    await _topicChatRepository.subscribeToTopicMessages(widget.topicId, (
      message,
    ) {
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
      });
      _refreshFlagsFromMessages();
      _scrollToBottom();
    });
  }

  Future<void> _loadMessages() async {
    final result = await _topicChatRepository.getTopicMessages(widget.topicId);
    var messages = const <Map<String, dynamic>>[];
    result.fold((error) {}, (value) => messages = value);
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
    final profileResult = await _profileRepository.getCurrentProfile();
    Map<String, dynamic>? profile;
    profileResult.fold((error) {}, (value) => profile = value);
    if (profile == null) return;

    final currentProfile = profile!;
    _currentUserId = currentProfile['id']?.toString();
    for (final message in messages) {
      final senderId = message['sender_id']?.toString() ?? '';
      if (senderId.isEmpty || _senderMeta.containsKey(senderId)) continue;
      if (senderId == _currentUserId) {
        _senderMeta[senderId] = {
          'name': currentProfile['name']?.toString() ?? 'You',
          'course': currentProfile['course']?.toString() ?? 'N/A',
          'year': (currentProfile['year_level'] as num?)?.toInt(),
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
    final profileResult = await _profileRepository.getCurrentProfile();
    Map<String, dynamic>? user;
    profileResult.fold((error) {}, (value) => user = value);
    final text = (quickText ?? _messageController.text).trim();

    if (user == null || text.isEmpty || _sending) return;

    final currentUser = user!;

    setState(() => _sending = true);
    final sentResult = await _topicChatRepository.sendTopicMessage(
      topicId: widget.topicId,
      senderId: currentUser['id']?.toString() ?? '',
      content: text,
      messageType: 'text',
    );
    setState(() => _sending = false);

    if (!mounted) return;
    Map<String, dynamic>? sent;
    sentResult.fold((error) {}, (value) => sent = value);
    if (sent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message.')));
      return;
    }

    final sentMessage = sent!;
    _messageController.clear();
    await _hydrateSenderMeta([sentMessage]);
    setState(() {
      _messages = [..._messages, sentMessage];
    });
    _scrollToBottom();
  }

  Future<void> _flagStruggleAnonymously() async {
    final profileResult = await _profileRepository.getCurrentProfile();
    Map<String, dynamic>? user;
    profileResult.fold((error) {}, (value) => user = value);
    if (user == null) return;

    final currentUser = user!;

    final sentResult = await _topicChatRepository.sendTopicMessage(
      topicId: widget.topicId,
      senderId: currentUser['id']?.toString() ?? '',
      content: '[STRUGGLE_FLAG] I need help with this topic',
      messageType: 'system',
    );

    Map<String, dynamic>? sent;
    sentResult.fold((error) {}, (value) => sent = value);

    if (sent != null && mounted) {
      final sentMessage = sent!;
      await _hydrateSenderMeta([sentMessage]);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sentMessage];
      });
      _refreshFlagsFromMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anonymous struggle flag submitted.')),
      );
    }
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
          topicId: widget.topicId,
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _topicChatRepository.unsubscribeFromTopicMessages();
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
            Text(title, style: AppTextStyles.headingSmall),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_struggleUserIds.length >= 3)
            GlassCard(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              backgroundColor: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: AppSpacing.xs + 2,
              borderColors: [
                AppColors.warning.withValues(alpha: 0.4),
                AppColors.warning.withValues(alpha: 0.4),
              ],
              child: Text(
                'Multiple people are struggling with this topic.',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xxs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _promptChip('Anyone struggling with this?'),
                  const SizedBox(width: AppSpacing.xs),
                  _promptChip('Can someone explain?'),
                  const SizedBox(width: AppSpacing.xs),
                  _promptChip('Exam question tip 💡'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? AppStateView.loadingList(itemCount: 4, itemHeight: 88)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
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

                      final isMine =
                          _currentUserId != null && senderId == _currentUserId;
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: GlassCard(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            backgroundColor: isMine
                                ? AppColors.primary
                                : AppColors.cardDark,
                            borderRadius: AppSpacing.fieldRadius,
                            borderColors: isMine
                                ? null
                                : [AppColors.border, AppColors.border],
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
                                        displayName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Column(
                                      crossAxisAlignment: isMine
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: AppTextStyles.caption.copyWith(
                                            color: isMine
                                                ? Colors.white70
                                                : AppColors.accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          subtitle,
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  content,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  created.isEmpty
                                      ? ''
                                      : created
                                            .replaceFirst('T', ' ')
                                            .substring(0, 16),
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: AppTextStyles.bodySmall,
                          decoration: const InputDecoration(
                            hintText: 'Ask or share something...',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _openVoiceRecorder();
                        },
                        icon: const Icon(Icons.mic_none_rounded),
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      IconButton.filled(
                        onPressed: _sending
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _sendMessage();
                              },
                        icon: _sending
                            ? const Icon(Icons.hourglass_top_rounded, size: 16)
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _flagStruggleAnonymously();
                      },
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

  Widget _promptChip(String text) => ActionChip(
    label: Text(text),
    onPressed: () {
      HapticFeedback.selectionClick();
      _sendMessage(text);
    },
    backgroundColor: AppColors.surfaceDark,
    labelStyle: AppTextStyles.caption.copyWith(
      color: Colors.white,
      fontSize: 12,
    ),
    side: const BorderSide(color: AppColors.border),
  );
}
