import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/core/repositories/impl/uploaded_note_repository_impl.dart';
import 'package:studytrack/core/services/supabase_service.dart';
import 'package:studytrack/core/utils/result.dart';

/// Fake implementation of SupabaseService for testing
class FakeSupabaseService implements SupabaseService {
  List<Map<String, dynamic>>? mockNotesMaps;
  List<Map<String, dynamic>>? mockSharedNotesMaps;
  Map<String, dynamic>? updateNoteShareResponse;
  bool? deleteNoteResult;
  Exception? thrownException;

  @override
  Future<List<Map<String, dynamic>>?> getNotesByTopic(String topicId) async {
    if (thrownException != null) throw thrownException!;
    return mockNotesMaps;
  }

  @override
  Future<List<Map<String, dynamic>>?> getSharedUploadedNotes({
    int limit = 40,
  }) async {
    if (thrownException != null) throw thrownException!;
    return mockSharedNotesMaps;
  }

  @override
  Future<Map<String, dynamic>?> updateUploadedNoteSharing(
    String noteId,
    bool isShared,
  ) async {
    if (thrownException != null) throw thrownException!;
    return updateNoteShareResponse;
  }

  @override
  Future<bool?> deleteUploadedNote(String noteId) async {
    if (thrownException != null) throw thrownException!;
    return deleteNoteResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late UploadedNoteRepositoryImpl repository;
  late FakeSupabaseService fakeSupabaseService;

  setUp(() {
    fakeSupabaseService = FakeSupabaseService();
    repository = UploadedNoteRepositoryImpl(fakeSupabaseService);
  });

  group('UploadedNoteRepository', () {
    test(
      'getNotesByTopic returns Success with notes when data exists',
      () async {
        // Arrange
        const topicId = 'topic-123';
        fakeSupabaseService.mockNotesMaps = [
          {
            'id': 'note-1',
            'topic_id': topicId,
            'user_id': 'user-1',
            'file_name': 'note1.pdf',
            'file_url': 'https://example.com/note1.pdf',
            'file_type': 'pdf',
            'is_shared_with_group': false,
            'processing_status': 'completed',
            'created_at': '2026-05-01T00:00:00.000Z',
          },
          {
            'id': 'note-2',
            'topic_id': topicId,
            'user_id': 'user-2',
            'file_name': 'note2.pdf',
            'file_url': 'https://example.com/note2.pdf',
            'file_type': 'pdf',
            'is_shared_with_group': true,
            'processing_status': 'completed',
            'created_at': '2026-05-02T00:00:00.000Z',
          },
        ];

        // Act
        final result = await repository.getNotesByTopic(topicId);

        // Assert
        expect(result, isA<Success<dynamic>>());
        final successResult = result as Success<dynamic>;
        expect(successResult.data, hasLength(2));
        expect(successResult.data[0].id, equals('note-1'));
        expect(successResult.data[1].id, equals('note-2'));
        expect(successResult.data[0].isSharedWithGroup, isFalse);
        expect(successResult.data[1].isSharedWithGroup, isTrue);
      },
    );

    test(
      'getNotesByTopic returns Success with empty list when no notes exist',
      () async {
        // Arrange
        const topicId = 'topic-456';
        fakeSupabaseService.mockNotesMaps = null;

        // Act
        final result = await repository.getNotesByTopic(topicId);

        // Assert
        expect(result, isA<Success<dynamic>>());
        expect((result as Success<dynamic>).data, isEmpty);
      },
    );

    test('getNotesByTopic returns Failure when exception occurs', () async {
      // Arrange
      const topicId = 'topic-789';
      fakeSupabaseService.thrownException = Exception('Database error');

      // Act
      final result = await repository.getNotesByTopic(topicId);

      // Assert
      expect(result, isA<Failure<dynamic>>());
    });

    test('getSharedNotes returns list of shared notes', () async {
      // Arrange
      fakeSupabaseService.mockSharedNotesMaps = [
        {
          'id': 'note-shared-1',
          'topic_id': 'topic-1',
          'user_id': 'user-1',
          'file_name': 'shared.pdf',
          'file_url': 'https://example.com/shared.pdf',
          'file_type': 'pdf',
          'is_shared_with_group': true,
          'processing_status': 'completed',
          'created_at': '2026-05-01T00:00:00.000Z',
        },
      ];

      // Act
      final result = await repository.getSharedNotes();

      // Assert
      expect(result, isA<Success<dynamic>>());
      final successResult = result as Success<dynamic>;
      expect(successResult.data, hasLength(1));
      expect(successResult.data[0].isSharedWithGroup, isTrue);
    });

    test('updateNoteSharing successfully updates sharing status', () async {
      // Arrange
      const noteId = 'note-123';
      fakeSupabaseService.updateNoteShareResponse = {
        'id': noteId,
        'topic_id': 'topic-1',
        'user_id': 'user-1',
        'file_name': 'shared.pdf',
        'file_url': 'https://example.com/shared.pdf',
        'file_type': 'pdf',
        'is_shared_with_group': true,
        'processing_status': 'completed',
        'created_at': '2026-05-01T00:00:00.000Z',
      };

      // Act
      final result = await repository.updateNoteSharing(noteId, isShared: true);

      // Assert
      expect(result, isA<Success<dynamic>>());
      final successResult = result as Success<dynamic>;
      expect(successResult.data, isNotNull);
      expect(successResult.data!.id, equals(noteId));
      expect(successResult.data!.isSharedWithGroup, isTrue);
    });

    test('deleteUploadedNote successfully deletes note', () async {
      // Arrange
      const noteId = 'note-delete-me';
      fakeSupabaseService.deleteNoteResult = true;

      // Act
      final result = await repository.deleteUploadedNote(noteId);

      // Assert
      expect(result, isA<Success<dynamic>>());
      expect((result as Success<dynamic>).data, isTrue);
    });

    test('deleteUploadedNote returns Failure on exception', () async {
      // Arrange
      const noteId = 'note-error';
      fakeSupabaseService.thrownException = Exception('Delete failed');

      // Act
      final result = await repository.deleteUploadedNote(noteId);

      // Assert
      expect(result, isA<Failure<dynamic>>());
    });
  });
}
