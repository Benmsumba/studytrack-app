import 'package:flutter/foundation.dart';

import '../../../models/uploaded_note_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../uploaded_note_repository.dart';

class UploadedNoteRepositoryImpl implements UploadedNoteRepository {
  UploadedNoteRepositoryImpl(this._supabaseService);

  final SupabaseService _supabaseService;

  @override
  Future<Result<List<UploadedNoteModel>>> getNotesByTopic(
    String topicId,
  ) async {
    try {
      final rows = await _supabaseService.getNotesByTopic(topicId);
      final notes = (rows ?? <Map<String, dynamic>>[])
          .map(UploadedNoteModel.fromJson)
          .toList(growable: false);
      return Success(notes);
    } on Object catch (e, st) {
      debugPrint('getNotesByTopic repo error: $e');
      debugPrint('$st');
      return Failure(
        DataException(message: 'Failed to load notes: $e', stackTrace: st),
      );
    }
  }

  @override
  Future<Result<List<UploadedNoteModel>>> getSharedNotes({
    int limit = 40,
  }) async {
    try {
      final rows = await _supabaseService.getSharedUploadedNotes(limit: limit);
      final notes = (rows ?? <Map<String, dynamic>>[])
          .map(UploadedNoteModel.fromJson)
          .toList(growable: false);
      return Success(notes);
    } on Object catch (e, st) {
      debugPrint('getSharedNotes repo error: $e');
      debugPrint('$st');
      return Failure(
        DataException(
          message: 'Failed to load shared notes: $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<UploadedNoteModel?>> updateNoteSharing(
    String noteId, {
    required bool isShared,
  }) async {
    try {
      final response = await _supabaseService.updateUploadedNoteSharing(
        noteId,
        isShared,
      );
      if (response == null) {
        return Failure(DataException(message: 'update failed'));
      }
      return Success(UploadedNoteModel.fromJson(response));
    } on Object catch (e, st) {
      debugPrint('updateNoteSharing repo error: $e');
      debugPrint('$st');
      return Failure(
        DataException(message: 'Failed to update sharing: $e', stackTrace: st),
      );
    }
  }

  @override
  Future<Result<bool>> deleteUploadedNote(String noteId) async {
    try {
      final deleted = await _supabaseService.deleteUploadedNote(noteId);
      return Success(deleted == true);
    } on Object catch (e, st) {
      debugPrint('deleteUploadedNote repo error: $e');
      debugPrint('$st');
      return Failure(
        DataException(message: 'Failed to delete note: $e', stackTrace: st),
      );
    }
  }
}
