import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../constants/app_constants.dart';

class QuizQuestion {
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

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

class GeminiService {
  GeminiService._internal();

  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() => _instance;

  late final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _resolvedApiKey,
  );

  String get _resolvedApiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return AppConstants.geminiApiKey;
  }

  Future<String> explainTopic({
    required String topicName,
    required String moduleName,
    required String course,
    required int currentRating,
    String? notesContent,
  }) async {
    final prompt = '''
You are an expert academic tutor for health sciences students.

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

    return _generateText(prompt, fallback: 'Could not generate explanation right now.');
  }

  Future<List<QuizQuestion>> generateQuiz({
    required String topicName,
    required String course,
    String? notesContent,
  }) async {
    final prompt = '''
Generate 5 multiple-choice questions for the topic "$topicName" (course: $course).

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
    } catch (error) {
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

    return _generateText(prompt, fallback: 'Could not generate mnemonic right now.');
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

    return _generateText(prompt, fallback: 'Could not summarize notes right now.');
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

    return _generateText(prompt, fallback: 'Could not predict exam questions right now.');
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

    return _generateText(prompt, fallback: 'Could not generate weekly summary right now.');
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

    return _generateText(prompt, fallback: 'Could not get study suggestion right now.');
  }

  Future<String> chatWithTutor({
    required String message,
    required List<Map> conversationHistory,
    required String currentTopic,
    required String course,
    String? notesContext,
  }) async {
    final history = conversationHistory
        .map((entry) =>
            '- ${entry['role'] ?? 'user'}: ${(entry['content'] ?? '').toString()}')
        .join('\n');

    final prompt = '''
You are StudyTrack AI Tutor.
Stay focused on academic help only.
If user asks off-topic requests, politely redirect to study help.

Current topic: $currentTopic
Course: $course

Notes context:
${(notesContext == null || notesContext.trim().isEmpty) ? 'No notes context provided.' : notesContext}

Conversation history:
$history

New user message:
$message
''';

    return _generateText(prompt, fallback: 'Tutor is currently unavailable. Please try again.');
  }

  Future<String> _generateText(
    String prompt, {
    required String fallback,
  }) async {
    if (_resolvedApiKey.isEmpty || _resolvedApiKey == 'YOUR_GEMINI_API_KEY') {
      return 'Gemini API key is not configured.';
    }

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        return fallback;
      }
      return text;
    } catch (error) {
      return '$fallback Error: $error';
    }
  }

  Map<String, dynamic>? _decodeJson(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _extractJson(String raw) {
    var output = raw.trim();
    if (output.startsWith('```')) {
      output = output
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
    }

    final firstBrace = output.indexOf('{');
    final lastBrace = output.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace == -1 || lastBrace <= firstBrace) {
      return '';
    }
    return output.substring(firstBrace, lastBrace + 1);
  }

  List<QuizQuestion> _fallbackQuiz(String message) {
    return List<QuizQuestion>.generate(5, (index) {
      return QuizQuestion(
        question: 'Quiz unavailable (${index + 1}/5)',
        options: const ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        explanation: message,
      );
    });
  }
}
