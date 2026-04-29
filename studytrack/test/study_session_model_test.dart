import 'package:flutter_test/flutter_test.dart';

import 'package:studytrack/models/study_session_model.dart';

void main() {
  group('StudySessionModel overdue logic', () {
    test('isOverdueAt is true for past non-completed sessions', () {
      final session = _session(
        scheduledDate: DateTime.parse('2026-04-20T12:00:00.000Z'),
        status: 'scheduled',
      );

      expect(
        session.isOverdueAt(now: DateTime.parse('2026-04-21T00:00:00.000Z')),
        isTrue,
      );
    });

    test('isOverdueAt is false for completed sessions', () {
      final session = _session(
        scheduledDate: DateTime.parse('2026-04-20T12:00:00.000Z'),
        status: 'completed',
      );

      expect(
        session.isOverdueAt(now: DateTime.parse('2026-04-21T00:00:00.000Z')),
        isFalse,
      );
    });

    test('isOverdueAt is false for same-day sessions', () {
      final session = _session(
        scheduledDate: DateTime.parse('2026-04-21T09:00:00.000Z'),
        status: 'scheduled',
      );

      expect(
        session.isOverdueAt(now: DateTime.parse('2026-04-21T23:59:00.000Z')),
        isFalse,
      );
    });
  });

  group('StudySessionModel serialization', () {
    test('fromJson and toJson preserve key fields', () {
      final json = {
        'id': 'session-1',
        'user_id': 'user-1',
        'topic_id': 'topic-1',
        'module_id': 'module-1',
        'title': 'Cardio revision',
        'scheduled_date': '2026-04-29T00:00:00.000Z',
        'start_time': '08:00',
        'end_time': '09:00',
        'duration_minutes': 60,
        'status': 'scheduled',
        'actual_duration_minutes': 50,
        'created_at': '2026-04-20T10:00:00.000Z',
      };

      final session = StudySessionModel.fromJson(json);
      final encoded = session.toJson();

      expect(session.id, 'session-1');
      expect(session.title, 'Cardio revision');
      expect(session.durationMinutes, 60);
      expect(session.actualDurationMinutes, 50);

      expect(encoded['id'], 'session-1');
      expect(encoded['scheduled_date'], '2026-04-29');
      expect(encoded['status'], 'scheduled');
      expect(encoded['duration_minutes'], 60);
      expect(encoded['actual_duration_minutes'], 50);
    });

    test('copyWith overrides selected fields only', () {
      final original = _session(
        scheduledDate: DateTime.parse('2026-04-29T00:00:00.000Z'),
        status: 'scheduled',
      );
      final updated = original.copyWith(
        title: 'Neuro revision',
        status: 'completed',
        actualDurationMinutes: 55,
      );

      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
      expect(updated.moduleId, original.moduleId);
      expect(updated.topicId, original.topicId);
      expect(updated.title, 'Neuro revision');
      expect(updated.status, 'completed');
      expect(updated.actualDurationMinutes, 55);
      expect(updated.scheduledDate, original.scheduledDate);
      expect(updated.createdAt, original.createdAt);
    });
  });
}

StudySessionModel _session({
  required DateTime scheduledDate,
  required String status,
}) => StudySessionModel(
  id: 'session-1',
  userId: 'user-1',
  topicId: 'topic-1',
  moduleId: 'module-1',
  title: 'Cardio revision',
  scheduledDate: scheduledDate,
  startTime: '08:00',
  endTime: '09:00',
  durationMinutes: 60,
  status: status,
  actualDurationMinutes: 50,
  createdAt: DateTime.parse('2026-04-20T10:00:00.000Z'),
);
