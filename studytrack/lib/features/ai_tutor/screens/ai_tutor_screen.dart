import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../models/topic_model.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({required this.topicId, super.key});

  final String topicId;

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  late final TopicRepository _topicRepository;
  late final ModuleRepository _moduleRepository;
  late final ProfileRepository _profileRepository;
  final GeminiService _gemini = GeminiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _loadError;
  bool _isThinking = false;
  bool _isStreaming = false;
  TopicModel? _topic;
  String _course = 'Health Sciences';
  String _moduleName = 'General';

  // Personalization fields loaded from the user's profile
  StudyPersonalization _personalization = const StudyPersonalization();

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _topicRepository = getIt<TopicRepository>();
    _moduleRepository = getIt<ModuleRepository>();
    _profileRepository = getIt<ProfileRepository>();
    _loadContext();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final topicResult = await _topicRepository.getTopicById(widget.topicId);
    TopicModel? topic;
    final topicFailed = topicResult is Failure<TopicModel?>;
    topicResult.fold((error) {}, (value) => topic = value);

    var moduleName = 'General';
    if (topic != null) {
      final moduleResult = await _moduleRepository.getModuleById(
        topic!.moduleId,
      );
      moduleResult.fold((error) {}, (value) {
        moduleName = value?.name ?? 'General';
      });
    }

    var course = 'Health Sciences';
    var personalization = const StudyPersonalization();
    final profileResult = await _profileRepository.getCurrentProfile();
    final profileFailed = profileResult is Failure<Map<String, dynamic>?>;
    profileResult.fold((error) {}, (profile) {
      final profileCourse = profile?['course']?.toString();
      if (profileCourse != null && profileCourse.trim().isNotEmpty) {
        course = profileCourse;
      }
      personalization = StudyPersonalization(
        primeStudyTime: profile?['prime_study_time'] as String?,
        studyPreference: profile?['study_preference'] as String?,
        studyHoursPerDay:
            (profile?['study_hours_per_day'] as num?)?.toInt(),
      );
    });

    if (!mounted) return;
    setState(() {
      _topic = topic;
      _moduleName = moduleName;
      _course = course;
      _personalization = personalization;
      _loadError = topicFailed || profileFailed
          ? 'We could not load the tutor context right now.'
          : null;
      _isLoading = false;
    });
  }

  Future<void> _sendUserMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || _isThinking || _isStreaming || _topic == null) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage.user(message));
      _isThinking = true;
    });
    _inputController.clear();
    _scrollToBottom();

    // Build conversation history from all messages so far (excluding the one
    // we just added so the prompt doesn't repeat the new message twice).
    final history = _messages
        .take(_messages.length - 1)
        .map(
          (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
        )
        .toList();

    // Add an empty AI bubble that will fill in as chunks arrive.
    setState(() {
      _messages.add(_ChatMessage.ai(''));
      _isThinking = false;
      _isStreaming = true;
    });
    _scrollToBottom();

    final stream = _gemini.chatWithTutorStream(
      message: message,
      conversationHistory: history,
      currentTopic: _topic!.name,
      course: _course,
      notesContext: _topic!.notes,
      personalization: _personalization,
    );

    await for (final chunk in stream) {
      if (!mounted) return;
      setState(() {
        final lastIndex = _messages.length - 1;
        _messages[lastIndex] = _ChatMessage.ai(
          _messages[lastIndex].text + chunk,
        );
      });
      _scrollToBottom();
    }

    if (!mounted) return;
    setState(() => _isStreaming = false);
    _scrollToBottom();
  }

  Future<void> _runExplain() async {
    if (_isThinking || _isStreaming || _topic == null) return;
    setState(() {
      _messages.add(_ChatMessage.user('Explain this topic'));
      _isThinking = true;
    });
    _scrollToBottom();

    final text = await _gemini.explainTopic(
      topicName: _topic!.name,
      moduleName: _moduleName,
      course: _course,
      currentRating: _topic!.currentRating ?? 0,
      notesContent: _topic!.notes,
      personalization: _personalization,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage.ai(text));
      _isThinking = false;
    });
    _scrollToBottom();
  }

  Future<void> _runMnemonic() async {
    if (_isThinking || _isStreaming || _topic == null) return;
    setState(() {
      _messages.add(_ChatMessage.user('Give a mnemonic'));
      _isThinking = true;
    });
    _scrollToBottom();

    final text = await _gemini.generateMnemonic(
      topicName: _topic!.name,
      content: (_topic!.notes?.trim().isNotEmpty ?? false)
          ? _topic!.notes!
          : _topic!.name,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage.ai(text));
      _isThinking = false;
    });
    _scrollToBottom();
  }

  Future<void> _runPredictQuestions() async {
    if (_isThinking || _isStreaming || _topic == null) return;
    setState(() {
      _messages.add(_ChatMessage.user('Predict questions'));
      _isThinking = true;
    });
    _scrollToBottom();

    final text = await _gemini.predictExamQuestions(
      topicName: _topic!.name,
      moduleName: _moduleName,
      notesContent: _topic!.notes,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage.ai(text));
      _isThinking = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final topicName = _topic?.name ?? 'Topic';
    final hasNotes = _topic?.notes?.trim().isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const Icon(Icons.psychology_rounded, color: AppColors.accent),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topicName,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'AI Tutor',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? AppStateView.loadingList(itemCount: 4, itemHeight: 88)
          : _loadError != null
          ? AppStateView.error(
              title: 'AI Tutor unavailable',
              message: _loadError!,
              onRetry: _loadContext,
            )
          : Column(
              children: [
                if (hasNotes)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      'Based on your uploaded notes',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? _EmptyTutorState(topicName: topicName)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          itemCount: _messages.length + (_isThinking ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return const _TypingBubble();
                            }
                            final message = _messages[index];
                            final isLastAiMessage = !message.isUser &&
                                index == _messages.length - 1 &&
                                _isStreaming;
                            return _ChatBubble(
                              message: message,
                              showCursor: isLastAiMessage,
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceDark,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _QuickChip(
                              label: 'Explain this',
                              onTap: _runExplain,
                            ),
                            _QuickChip(
                              label: 'Test me',
                              onTap: () => context.push(
                                '/topics/${widget.topicId}/quiz',
                              ),
                            ),
                            _QuickChip(
                              label: 'Give a mnemonic',
                              onTap: _runMnemonic,
                            ),
                            _QuickChip(
                              label: 'Predict questions',
                              onTap: _runPredictQuestions,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ask me anything about $topicName',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                filled: true,
                                fillColor: AppColors.cardDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                              onSubmitted: _sendUserMessage,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                _sendUserMessage(_inputController.text),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: (_isThinking || _isStreaming)
                                    ? null
                                    : AppColors.primaryGradient,
                                color: (_isThinking || _isStreaming)
                                    ? AppColors.cardDark
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.send_rounded,
                                color: (_isThinking || _isStreaming)
                                    ? AppColors.textMuted
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChatMessage {
  factory _ChatMessage.user(String text) =>
      _ChatMessage(text: text, isUser: true);
  factory _ChatMessage.ai(String text) =>
      _ChatMessage(text: text, isUser: false);
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, this.showCursor = false});

  final _ChatMessage message;
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: message.isUser ? AppColors.primaryGradient : null,
          color: message.isUser ? null : AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: message.isUser ? null : Border.all(color: AppColors.border),
        ),
        child: message.isUser
            ? Text(
                message.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              )
            : message.text.isEmpty
            ? const _StreamingDots()
            : _MarkdownText(text: message.text, showCursor: showCursor),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      onPressed: onTap,
      backgroundColor: AppColors.cardDark,
      side: const BorderSide(color: AppColors.border),
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _EmptyTutorState extends StatelessWidget {
  const _EmptyTutorState({required this.topicName});

  final String topicName;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.psychology_alt_rounded,
            color: AppColors.accent,
            size: 50,
          ),
          const SizedBox(height: 14),
          Text(
            'Ask me anything about $topicName',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try: "Explain the core concept", "Give me a mnemonic", or "Predict exam questions"',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMediumSecondary,
          ),
        ],
      ),
    ),
  );
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const _StreamingDots(),
    ),
  );
}

/// Three animated dots shown while waiting for the first streaming chunk.
class _StreamingDots extends StatelessWidget {
  const _StreamingDots();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Dot(delay: 0),
      SizedBox(width: 4),
      _Dot(delay: 180),
      SizedBox(width: 4),
      _Dot(delay: 360),
    ],
  );
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});

  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.2, end: 1).animate(_controller),
    child: const CircleAvatar(
      radius: 3,
      backgroundColor: AppColors.textSecondary,
    ),
  );
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text, this.showCursor = false});

  final String text;
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...lines.map((line) {
          final trimmed = line.trim();
          if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Expanded(child: _buildInline(trimmed.substring(2))),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildInline(line),
          );
        }),
        if (showCursor)
          Container(
            width: 8,
            height: 14,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }

  Widget _buildInline(String value) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    var cursor = 0;

    for (final match in regex.allMatches(value)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1) ?? '',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      cursor = match.end;
    }
    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor)));
    }

    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }
}
