import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

class _CacheEntry {
  _CacheEntry(this.value) : timestamp = DateTime.now();

  final String value;
  final DateTime timestamp;

  bool isExpired(Duration ttl) => DateTime.now().difference(timestamp) > ttl;
}

class QuizQuestion {
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();

    return QuizQuestion(
      question: (json['question'] ?? '').toString(),
      options: rawOptions.length == 4
          ? rawOptions
          : <String>['Option A', 'Option B', 'Option C', 'Option D'],
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: (json['explanation'] ?? '').toString(),
    );
  }
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'explanation': explanation,
  };
}

/// Holds the student's personal study preferences loaded from their profile.
/// Injected into AI prompts to personalise responses.
class StudyPersonalization {
  const StudyPersonalization({
    this.primeStudyTime,
    this.studyPreference,
    this.studyHoursPerDay,
  });

  final String? primeStudyTime;
  final String? studyPreference;
  final int? studyHoursPerDay;

  bool get hasAnyData =>
      primeStudyTime != null ||
      studyPreference != null ||
      studyHoursPerDay != null;

  String toPromptSnippet() {
    if (!hasAnyData) return '';
    final lines = <String>[];
    if (studyPreference != null) {
      lines.add('- Study style: ${studyPreference!} (solo vs group)');
    }
    if (primeStudyTime != null) {
      lines.add('- Peak focus time: ${primeStudyTime!}');
    }
    if (studyHoursPerDay != null) {
      lines.add('- Daily study target: ${studyHoursPerDay!} hrs/day');
    }
    return '\nStudent study profile:\n${lines.join('\n')}';
  }
}

class GeminiService {
  factory GeminiService() => _instance;
  GeminiService._internal();

  static final GeminiService _instance = GeminiService._internal();

  final Map<int, _CacheEntry> _cache = {};
  static const _cacheTtl = Duration(hours: 1);
  static const _maxCacheEntries = 100;
  static const _maxRetries = 3;
  static const _minRequestInterval = Duration(milliseconds: 500);

  DateTime? _lastRequestAt;

  bool get _isEdgeFunctionConfigured => AppConstants.isSupabaseConfigured;

  String get _edgeFunctionUrl =>
      '${AppConstants.resolvedSupabaseUrl}/functions/v1/gemini-proxy';

  void clearCache() => _cache.clear();

  Future<String> explainTopic({
    required String topicName,
    required String moduleName,
    required String course,
    required int currentRating,
    String? notesContent,
    StudyPersonalization? personalization,
  }) async {
    final prompt = '''
You are an expert academic tutor for health sciences students.
${personalization?.toPromptSnippet() ?? ''}

Student course: $course
Module: $moduleName
Topic: $topicName
Current self-rating: $currentRating/10

Instruction:
- Tailor explanation depth to rating ($currentRating/10).
- If notes are provided, explain from those notes first and then fill gaps.
- Keep response under 400 words.
- Use clear structure with short headings and bullets.
- Use analogies where helpful.
- End with exactly: Key point to remember: <one sentence>

Student notes:
${(notesContent == null || notesContent.trim().isEmpty) ? 'No notes provided.' : notesContent}
''';

    return _generateText(
      prompt,
      fallback: 'Could not generate explanation right now.',
    );
  }

  Future<List<QuizQuestion>> generateQuiz({
    required String topicName,
    required String course,
    String? notesContent,
    StudyPersonalization? personalization,
  }) async {
    final prompt = '''
Generate 5 multiple-choice questions for the topic "$topicName" (course: $course).
${personalization?.toPromptSnippet() ?? ''}

Rules:
- Exactly 5 questions.
- Each has exactly 4 options.
- Include correctIndex (0..3).
- Include explanation for each answer.
- If notes are provided, prioritize those notes.
- Return ONLY valid JSON with this structure:
{
  "questions": [
    {
      "question": "...",
      "options": ["...","...","...","..."],
      "correctIndex": 1,
      "explanation": "..."
    }
  ]
}

Notes:
${(notesContent == null || notesContent.trim().isEmpty) ? 'No notes provided.' : notesContent}
''';

    try {
      final raw = await _generateText(prompt, fallback: '');
      final jsonText = _extractJson(raw);
      if (jsonText.isEmpty) {
        return _fallbackQuiz('Failed to parse quiz response.');
      }

      final decoded = _decodeJson(jsonText);
      if (decoded == null || decoded['questions'] is! List<dynamic>) {
        return _fallbackQuiz('Quiz response format was invalid.');
      }

      final questions = (decoded['questions'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestion.fromJson)
          .toList();

      if (questions.length < 5) {
        return _fallbackQuiz('Quiz generation returned too few questions.');
      }

      return questions.take(5).toList();
    } on Object catch (error) {
      return _fallbackQuiz('Quiz generation failed: $error');
    }
  }

  Future<String> generateMnemonic({
    required String topicName,
    required String content,
  }) async {
    final prompt = '''
Create a creative and memorable mnemonic for this topic:
Topic: $topicName
Content: $content

Return:
- Mnemonic phrase
- Quick breakdown of what each part maps to
''';

    return _generateText(
      prompt,
      fallback: 'Could not generate mnemonic right now.',
    );
  }

  Future<String> summarizeNotes({
    required String topicName,
    required String notesContent,
  }) async {
    final prompt = '''
Summarize these notes for topic "$topicName" in under 300 words.
Use concise bullet points and prioritize exam-relevant facts.

Notes:
$notesContent
''';

    return _generateText(
      prompt,
      fallback: 'Could not summarize notes right now.',
    );
  }

  Future<String> predictExamQuestions({
    required String topicName,
    required String moduleName,
    String? notesContent,
  }) async {
    final prompt = '''
Predict 5 likely exam questions for:
Topic: $topicName
Module: $moduleName

For each predicted question, add 1-2 lines why it may appear.

Notes context:
${(notesContent == null || notesContent.trim().isEmpty) ? 'No notes provided.' : notesContent}
''';

    return _generateText(
      prompt,
      fallback: 'Could not predict exam questions right now.',
    );
  }

  Future<String> generateWeeklyWrappedSummary({
    required String studentName,
    required int topicsStudied,
    required double averageRating,
    required String bestSubject,
    required String weakestSubject,
    required int streak,
    required int sessionsCompleted,
    required int sessionsMissed,
  }) async {
    final prompt = '''
Write a 3-4 sentence motivational weekly summary.
Tone: encouraging coach.

Student: $studentName
Topics studied: $topicsStudied
Average rating: ${averageRating.toStringAsFixed(1)}
Best subject: $bestSubject
Weakest subject: $weakestSubject
Streak: $streak
Sessions completed: $sessionsCompleted
Sessions missed: $sessionsMissed

Mention wins first, then gaps, then practical next-week advice.
''';

    return _generateText(
      prompt,
      fallback: 'Could not generate weekly summary right now.',
    );
  }

  Future<String> getStudySuggestion({
    required String studentName,
    required List<String> weakTopics,
    required List<String> upcomingExams,
    required String primeStudyTime,
  }) async {
    final prompt = '''
Create a short 2-line actionable study suggestion.

Student: $studentName
Weak topics: ${weakTopics.isEmpty ? 'None listed' : weakTopics.join(', ')}
Upcoming exams: ${upcomingExams.isEmpty ? 'None listed' : upcomingExams.join(', ')}
Prime study time: $primeStudyTime

Keep it practical and specific for today.
''';

    return _generateText(
      prompt,
      fallback: 'Could not get study suggestion right now.',
    );
  }

  /// Returns a single response (non-streaming) for the AI chat.
  Future<String> chatWithTutor({
    required String message,
    required List<Map<String, dynamic>> conversationHistory,
    required String currentTopic,
    required String course,
    String? notesContext,
    StudyPersonalization? personalization,
  }) async {
    final prompt = _buildChatPrompt(
      message: message,
      conversationHistory: conversationHistory,
      currentTopic: currentTopic,
      course: course,
      notesContext: notesContext,
      personalization: personalization,
    );

    return _generateText(
      prompt,
      fallback: 'Tutor is currently unavailable. Please try again.',
    );
  }

  /// Streams the AI tutor response token-by-token via the Edge Function SSE endpoint.
  /// Emits text chunks as they arrive so the UI can render them incrementally.
  Stream<String> chatWithTutorStream({
    required String message,
    required List<Map<String, dynamic>> conversationHistory,
    required String currentTopic,
    required String course,
    String? notesContext,
    StudyPersonalization? personalization,
  }) async* {
    if (!_isEdgeFunctionConfigured) {
      yield 'AI Tutor is not configured — Supabase URL is missing.';
      return;
    }

    final prompt = _buildChatPrompt(
      message: message,
      conversationHistory: conversationHistory,
      currentTopic: currentTopic,
      course: course,
      notesContext: notesContext,
      personalization: personalization,
    );

    await _throttle();

    final session = Supabase.instance.client.auth.currentSession;
    final authToken =
        session?.accessToken ?? AppConstants.resolvedSupabaseAnonKey;

    final request = http.Request('POST', Uri.parse(_edgeFunctionUrl));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $authToken';
    request.headers['apikey'] = AppConstants.resolvedSupabaseAnonKey;
    request.body = jsonEncode({
      'method': 'streamChat',
      'params': {'prompt': prompt},
    });

    http.StreamedResponse response;
    try {
      response = await http.Client().send(request);
    } on Object catch (err) {
      yield 'Connection failed: $err';
      return;
    }

    if (response.statusCode != 200) {
      yield 'AI Tutor unavailable (HTTP ${response.statusCode}). Please try again.';
      return;
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring(6).trim();
      if (payload == '[DONE]') break;

      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        if (json.containsKey('error')) {
          yield 'Error: ${json['error']}';
          break;
        }
        final text = json['text'] as String?;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      } on Object catch (_) {
        // Malformed SSE chunk — skip silently
      }
    }
  }

  String _buildChatPrompt({
    required String message,
    required List<Map<String, dynamic>> conversationHistory,
    required String currentTopic,
    required String course,
    String? notesContext,
    StudyPersonalization? personalization,
  }) {
    final history = conversationHistory
        .map(
          (entry) =>
              '- ${entry['role'] ?? 'user'}: ${(entry['content'] ?? '').toString()}',
        )
        .join('\n');

    return '''
You are StudyTrack AI Tutor.
Stay focused on academic help only.
If user asks off-topic requests, politely redirect to study help.
${personalization?.toPromptSnippet() ?? ''}

Current topic: $currentTopic
Course: $course

Notes context:
${(notesContext == null || notesContext.trim().isEmpty) ? 'No notes context provided.' : notesContext}

Conversation history:
$history

New user message:
$message
''';
  }

  Future<String> _generateText(
    String prompt, {
    required String fallback,
  }) async {
    if (!_isEdgeFunctionConfigured) {
      return 'AI Tutor is not configured — Supabase URL is missing.';
    }

    final cacheKey = prompt.hashCode;
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_cacheTtl)) {
      return cached.value;
    }

    await _throttle();

    Exception? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await Supabase.instance.client.functions.invoke(
          'gemini-proxy',
          body: {
            'method': 'generateText',
            'params': {'prompt': prompt},
          },
        );

        final data = response.data as Map<String, dynamic>?;
        if (data == null) return fallback;

        if (data.containsKey('error')) {
          throw Exception(data['error'].toString());
        }

        final text = (data['text'] as String?)?.trim() ?? '';
        if (text.isEmpty) return fallback;

        if (_cache.length >= _maxCacheEntries) {
          _cache.remove(_cache.keys.first);
        }
        _cache[cacheKey] = _CacheEntry(text);
        return text;
      } on Object catch (error) {
        lastError = error is Exception ? error : Exception(error.toString());
        if (attempt < _maxRetries - 1) {
          await Future<void>.delayed(Duration(seconds: 1 << attempt));
        }
      }
    }

    debugPrint('GeminiService: all retries failed — $lastError');
    return '$fallback Error: $lastError';
  }

  Future<void> _throttle() async {
    final now = DateTime.now();
    if (_lastRequestAt != null) {
      final elapsed = now.difference(_lastRequestAt!);
      if (elapsed < _minRequestInterval) {
        await Future<void>.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();
  }

  Map<String, dynamic>? _decodeJson(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object catch (_) {
      return null;
    }
  }

  String _extractJson(String raw) {
    var output = raw.trim();
    if (output.startsWith('```')) {
      output = output.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    final firstBrace = output.indexOf('{');
    final lastBrace = output.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace == -1 || lastBrace <= firstBrace) {
      return '';
    }
    return output.substring(firstBrace, lastBrace + 1);
  }

  List<QuizQuestion> _fallbackQuiz(String message) =>
      List<QuizQuestion>.generate(
        5,
        (index) => QuizQuestion(
          question: 'Quiz unavailable (${index + 1}/5)',
          options: const ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: message,
        ),
      );
}
