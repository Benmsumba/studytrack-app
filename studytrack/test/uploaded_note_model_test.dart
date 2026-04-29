import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/models/uploaded_note_model.dart';

void main() {
  group('UploadedNoteModel', () {
    test('fromJson creates UploadedNoteModel with all fields', () {
      final createdAt = DateTime(2026, 4, 18, 13, 45, 0);
      final json = {
        'id': 'note-1',
        'topic_id': 'topic-123',
        'user_id': 'user-456',
        'file_name': 'Chapter5_Notes.pdf',
        'file_url': 'https://storage.example.com/notes/ch5.pdf',
        'file_type': 'pdf',
        'is_shared_with_group': true,
        'processing_status': 'completed',
        'created_at': createdAt.toIso8601String(),
      };

      final note = UploadedNoteModel.fromJson(json);

      expect(note.id, 'note-1');
      expect(note.topicId, 'topic-123');
      expect(note.userId, 'user-456');
      expect(note.fileName, 'Chapter5_Notes.pdf');
      expect(note.fileUrl, 'https://storage.example.com/notes/ch5.pdf');
      expect(note.fileType, 'pdf');
      expect(note.isSharedWithGroup, true);
      expect(note.processingStatus, 'completed');
      expect(note.createdAt, createdAt);
    });

    test('fromJson defaults isSharedWithGroup to false when missing', () {
      final createdAt = DateTime(2026, 4, 18, 13, 45, 0);
      final json = {
        'id': 'note-2',
        'topic_id': 'topic-789',
        'user_id': 'user-999',
        'file_name': 'MyNotes.docx',
        'file_url': 'https://storage.example.com/notes/mynotes.docx',
        'file_type': 'docx',
        'processing_status': 'pending',
        'created_at': createdAt.toIso8601String(),
      };

      final note = UploadedNoteModel.fromJson(json);

      expect(note.isSharedWithGroup, false);
    });

    test('toJson converts UploadedNoteModel to JSON correctly', () {
      final createdAt = DateTime(2026, 4, 18, 13, 45, 0);
      final note = UploadedNoteModel(
        id: 'note-3',
        topicId: 'topic-111',
        userId: 'user-222',
        fileName: 'Study_Guide.pdf',
        fileUrl: 'https://storage.example.com/guide.pdf',
        fileType: 'pdf',
        isSharedWithGroup: true,
        processingStatus: 'completed',
        createdAt: createdAt,
      );

      final json = note.toJson();

      expect(json['id'], 'note-3');
      expect(json['topic_id'], 'topic-111');
      expect(json['user_id'], 'user-222');
      expect(json['file_name'], 'Study_Guide.pdf');
      expect(json['file_url'], 'https://storage.example.com/guide.pdf');
      expect(json['file_type'], 'pdf');
      expect(json['is_shared_with_group'], true);
      expect(json['processing_status'], 'completed');
    });

    test('copyWith updates specified fields only', () {
      final createdAt = DateTime(2026, 4, 18);
      final original = UploadedNoteModel(
        id: 'note-1',
        topicId: 'topic-1',
        userId: 'user-1',
        fileName: 'old_name.pdf',
        fileUrl: 'https://example.com/old.pdf',
        fileType: 'pdf',
        isSharedWithGroup: false,
        processingStatus: 'pending',
        createdAt: createdAt,
      );

      final updated = original.copyWith(
        isSharedWithGroup: true,
        processingStatus: 'completed',
      );

      expect(updated.id, 'note-1');
      expect(updated.fileName, 'old_name.pdf');
      expect(updated.isSharedWithGroup, true);
      expect(updated.processingStatus, 'completed');
    });
  });
}
