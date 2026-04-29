import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/models/class_slot_model.dart';

void main() {
  group('ClassSlotModel', () {
    test('fromJson creates ClassSlotModel with all fields', () {
      final createdAt = DateTime(2026, 4, 1, 10, 0, 0);
      final json = {
        'id': 'slot-1',
        'user_id': 'user-123',
        'subject_name': 'Physics 101',
        'day_of_week': 1, // Monday
        'start_time': '09:00',
        'end_time': '10:30',
        'room': 'LAB-201',
        'lecturer': 'Dr. Smith',
        'color': '#FF5733',
        'created_at': createdAt.toIso8601String(),
      };

      final slot = ClassSlotModel.fromJson(json);

      expect(slot.id, 'slot-1');
      expect(slot.userId, 'user-123');
      expect(slot.subjectName, 'Physics 101');
      expect(slot.dayOfWeek, 1);
      expect(slot.startTime, '09:00');
      expect(slot.endTime, '10:30');
      expect(slot.room, 'LAB-201');
      expect(slot.lecturer, 'Dr. Smith');
      expect(slot.color, '#FF5733');
    });

    test('fromJson handles null optional fields', () {
      final createdAt = DateTime(2026, 4, 1, 10, 0, 0);
      final json = {
        'id': 'slot-2',
        'user_id': 'user-456',
        'subject_name': 'Chemistry',
        'day_of_week': 2,
        'start_time': '11:00',
        'end_time': '12:30',
        'room': null,
        'lecturer': null,
        'color': null,
        'created_at': createdAt.toIso8601String(),
      };

      final slot = ClassSlotModel.fromJson(json);

      expect(slot.room, isNull);
      expect(slot.lecturer, isNull);
      expect(slot.color, isNull);
    });

    test('toJson converts ClassSlotModel to JSON correctly', () {
      final createdAt = DateTime(2026, 4, 1, 10, 0, 0);
      final slot = ClassSlotModel(
        id: 'slot-3',
        userId: 'user-789',
        subjectName: 'Biology',
        dayOfWeek: 3,
        startTime: '14:00',
        endTime: '15:30',
        room: 'BIO-105',
        lecturer: 'Prof. Johnson',
        color: '#00AA00',
        createdAt: createdAt,
      );

      final json = slot.toJson();

      expect(json['id'], 'slot-3');
      expect(json['day_of_week'], 3);
      expect(json['start_time'], '14:00');
      expect(json['room'], 'BIO-105');
      expect(json['lecturer'], 'Prof. Johnson');
    });

    test('copyWith updates specified fields only', () {
      final createdAt = DateTime(2026, 4, 1);
      final original = ClassSlotModel(
        id: 'slot-1',
        userId: 'user-1',
        subjectName: 'Math',
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '10:00',
        room: 'ROOM-101',
        lecturer: 'Dr. X',
        color: '#0000FF',
        createdAt: createdAt,
      );

      final updated = original.copyWith(
        startTime: '10:00',
        endTime: '11:00',
        lecturer: 'Dr. Y',
      );

      expect(updated.id, 'slot-1');
      expect(updated.subjectName, 'Math');
      expect(updated.startTime, '10:00');
      expect(updated.endTime, '11:00');
      expect(updated.lecturer, 'Dr. Y');
      expect(updated.room, 'ROOM-101');
    });
  });
}
