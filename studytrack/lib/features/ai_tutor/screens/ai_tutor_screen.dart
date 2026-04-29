import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/topic_model.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({required this.topicId, super.key});

  final String topicId;

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final SupabaseService _supabase = SupabaseService();
  final GeminiService _gemini = GeminiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isThinking = false;
  TopicModel? _topic;
  String _course = 'Health Sciences';
  String _moduleName = 'General';

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final topic = await _supabase.getTopicById(widget.topicId);
    var moduleName = 'General';
    if (topic != null) {
      final module = await _supabase.getModuleById(topic.moduleId);
      moduleName = module?.name ?? 'General';
    }

    final user = _supabase.getCurrentUser();
    var course = 'Health Sciences';
    if (user != null) {
      final profile = await _supabase.getProfile(user.id);
      final profileCourse = profile?['course']?.toString();
      if (profileCourse != null && profileCourse.trim().isNotEmpty) {
        course = profileCourse;
      }
    }

    if (!mounted) return;
    setState(() {
      _topic = topic;
      _moduleName = moduleName;
      _course = course;
      _isLoading = false;
    });
  }

  Future<void> _sendUserMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || _isThinking || _topic == null) return;

    setState(() {
      _messages.add(_ChatMessage.user(message));
      _isThinking = true;
    });
    _inputController.clear();
    _scrollToBottom();

    final history = _messages
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    final aiText = await _gemini.chatWithTutor(
      message: message,
      conversationHistory: history,
      currentTopic: _topic!.name,
      course: _course,
      notesContext: _topic!.notes,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage.ai(aiText));
      _isThinking = false;
    });
    _scrollToBottom();
  }

  Future<void> _runExplain() async {
    if (_isThinking || _topic == null) return;
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
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage.ai(text));
      _isThinking = false;
    });
    _scrollToBottom();
  }

  Future<void> _runMnemonic() async {
    if (_isThinking || _topic == null) return;
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
    if (_isThinking || _topic == null) return;
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
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'AI Tutor',
                  style: GoogleFonts.inter(
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (hasNotes)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      'Based on your uploaded notes',
                      style: GoogleFonts.inter(
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
                            return _ChatBubble(message: message);
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
                            _QuickChip(label: 'Explain this', onTap: _runExplain),
                            _QuickChip(
                              label: 'Test me',
                              onTap: () => context.push('/topics/${widget.topicId}/quiz'),
                            ),
                            _QuickChip(label: 'Give a mnemonic', onTap: _runMnemonic),
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
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Ask me anything about $topicName',
                                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                                filled: true,
                                fillColor: AppColors.cardDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              onSubmitted: _sendUserMessage,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _sendUserMessage(_inputController.text),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white),
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

  factory _ChatMessage.user(String text) => _ChatMessage(text: text, isUser: true);
  factory _ChatMessage.ai(String text) => _ChatMessage(text: text, isUser: false);
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
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
          border: message.isUser
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: message.isUser
            ? Text(
                message.text,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              )
            : _MarkdownText(text: message.text),
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
          style: GoogleFonts.inter(
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
            const Icon(Icons.psychology_alt_rounded, color: AppColors.accent, size: 50),
            const SizedBox(height: 14),
            Text(
              'Ask me anything about $topicName',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try: "Explain the core concept", "Give me a mnemonic", or "Predict exam questions"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 180),
            SizedBox(width: 4),
            _Dot(delay: 360),
          ],
        ),
      ),
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
      child: const CircleAvatar(radius: 3, backgroundColor: AppColors.textSecondary),
    );
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: GoogleFonts.inter(color: Colors.white)),
                Expanded(child: _buildInline(trimmed.substring(2))),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _buildInline(line),
        );
      }).toList(),
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
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.4),
        children: spans,
      ),
    );
  }
}
