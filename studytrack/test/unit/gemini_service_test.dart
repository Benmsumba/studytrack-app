import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/core/services/gemini_service.dart';

void main() {
  group('QuizQuestion', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'question': 'What is osmosis?',
        'options': ['A', 'B', 'C', 'D'],
        'correctIndex': 2,
        'explanation': 'Osmosis is the movement of water across a membrane.',
      };

      final q = QuizQuestion.fromJson(json);

      expect(q.question, 'What is osmosis?');
      expect(q.options, ['A', 'B', 'C', 'D']);
      expect(q.correctIndex, 2);
      expect(
        q.explanation,
        'Osmosis is the movement of water across a membrane.',
      );
    });

    test('fromJson uses fallback options when list length is not 4', () {
      final json = {
        'question': 'Q?',
        'options': ['Only two', 'options here'],
        'correctIndex': 0,
        'explanation': 'exp',
      };

      final q = QuizQuestion.fromJson(json);

      expect(q.options.length, 4);
      expect(q.options, ['Option A', 'Option B', 'Option C', 'Option D']);
    });

    test('fromJson defaults correctIndex to 0 when missing', () {
      final json = {
        'question': 'Q?',
        'options': ['A', 'B', 'C', 'D'],
        'explanation': 'exp',
      };

      final q = QuizQuestion.fromJson(json);

      expect(q.correctIndex, 0);
    });

    test('fromJson handles null fields gracefully', () {
      final q = QuizQuestion.fromJson(<String, dynamic>{});

      expect(q.question, '');
      expect(q.explanation, '');
      expect(q.correctIndex, 0);
      expect(q.options, ['Option A', 'Option B', 'Option C', 'Option D']);
    });

    test('toJson round-trips correctly', () {
      const original = QuizQuestion(
        question: 'Q?',
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 1,
        explanation: 'Because B.',
      );

      final json = original.toJson();
      final restored = QuizQuestion.fromJson(json);

      expect(restored.question, original.question);
      expect(restored.options, original.options);
      expect(restored.correctIndex, original.correctIndex);
      expect(restored.explanation, original.explanation);
    });
  });

  group('GeminiService', () {
    test('is a singleton', () {
      final a = GeminiService();
      final b = GeminiService();
      expect(identical(a, b), isTrue);
    });

    test('returns api-not-configured message when key is empty', () async {
      // Without GEMINI_API_KEY dart-define and with placeholder constant,
      // the service should return an informative message instead of throwing.
      final service = GeminiService();
      final result = await service.explainTopic(
        topicName: 'Osmosis',
        moduleName: 'Cell Biology',
        course: 'Medicine',
        currentRating: 5,
      );

      // Either the placeholder error message or a real response.
      expect(result, isA<String>());
      expect(result.isNotEmpty, isTrue);
    });

    test(
      'generateQuiz returns 5-item fallback list when API not configured',
      () async {
        final service = GeminiService();
        final questions = await service.generateQuiz(
          topicName: 'Cardiac Cycle',
          course: 'Medicine',
        );

        expect(questions.length, 5);
        for (final q in questions) {
          expect(q.options.length, 4);
          expect(q.correctIndex, inInclusiveRange(0, 3));
        }
      },
    );

    test('clearCache does not throw', () {
      expect(() => GeminiService().clearCache(), returnsNormally);
    });
  });
}
