import '../../models/uploaded_note_model.dart';
import '../utils/result.dart';

/// Repository abstraction for uploaded/shared notes
abstract class UploadedNoteRepository {
  Future<Result<List<UploadedNoteModel>>> getNotesByTopic(String topicId);

  Future<Result<List<UploadedNoteModel>>> getSharedNotes({int limit = 40});

  Future<Result<UploadedNoteModel?>> updateNoteSharing(
    String noteId, {
    required bool isShared,
  });

  Future<Result<bool>> deleteUploadedNote(String noteId);
}
