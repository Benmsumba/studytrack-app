import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/models/exam_model.dart';

void main() {
  group('ExamModel computed fields', () {
    test('daysUntilExamFrom computes exact day differences', () {
      final exam = _exam(examDate: DateTime.parse('2026-05-10T09:00:00.000Z'));
      final reference = DateTime.parse('2026-05-01T22:00:00.000Z');

      expect(exam.daysUntilExamFrom(from: reference), 9);
    });

    test('isUrgentFrom follows 7-day threshold', () {
      final urgent = _exam(
        examDate: DateTime.parse('2026-05-06T09:00:00.000Z'),
      );
      final notUrgent = _exam(
        examDate: DateTime.parse('2026-05-09T09:00:00.000Z'),
      );
      final reference = DateTime.parse('2026-05-01T00:00:00.000Z');

      expect(urgent.isUrgentFrom(from: reference), isTrue);
      expect(notUrgent.isUrgentFrom(from: reference), isFalse);
    });
  });

  group('ExamModel serialization', () {
    test('fromJson and toJson preserve expected fields', () {
      final json = {
        'id': 'exam-1',
        'user_id': 'user-1',
        'module_id': 'module-1',
        'title': 'Final Exam',
        'exam_date': '2026-05-21T10:30:00.000Z',
        'exam_time': '10:30',
        'venue': 'Hall A',
        'exam_type': 'final',
        'created_at': '2026-04-20T10:00:00.000Z',
      };

      final exam = ExamModel.fromJson(json);
      final encoded = exam.toJson();

      expect(exam.id, 'exam-1');
      expect(exam.title, 'Final Exam');
      expect(exam.examDate, DateTime.parse('2026-05-21T10:30:00.000Z'));
      expect(exam.examType, 'final');

      expect(encoded['id'], 'exam-1');
      expect(encoded['exam_date'], '2026-05-21');
      expect(encoded['exam_time'], '10:30');
      expect(encoded['venue'], 'Hall A');
      expect(encoded['exam_type'], 'final');
    });

    test('copyWith overrides only provided values', () {
      final original = _exam(
        examDate: DateTime.parse('2026-05-21T10:30:00.000Z'),
      );
      final updated = original.copyWith(title: 'OSCE', venue: 'Lab B');

      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
      expect(updated.moduleId, original.moduleId);
      expect(updated.title, 'OSCE');
      expect(updated.examDate, original.examDate);
      expect(updated.venue, 'Lab B');
      expect(updated.examType, original.examType);
      expect(updated.createdAt, original.createdAt);
    });
  });
}

ExamModel _exam({required DateTime examDate}) => ExamModel(
  id: 'exam-1',
  userId: 'user-1',
  moduleId: 'module-1',
  title: 'Final Exam',
  examDate: examDate,
  examTime: '10:30',
  venue: 'Hall A',
  examType: 'final',
  createdAt: DateTime.parse('2026-04-20T10:00:00.000Z'),
);
