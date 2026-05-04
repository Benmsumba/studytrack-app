import 'package:flutter/foundation.dart';

import '../../../models/exam_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../exam_repository.dart';

/// Implementation of ExamRepository using SupabaseService
class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  String? get _userId => _supabaseService.getCurrentUser()?.id;

  @override
  Future<Result<List<ExamModel>>> getAllExams() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(<ExamModel>[]);
      }
      final exams = await _supabaseService.getExams(uid);
      final models = (exams ?? []).map(ExamModel.fromJson).toList();
      return Success(models);
    } on Object catch (e, stack) {
      debugPrint('getAllExams error: $e');
      return Failure(
        DataException(message: 'Failed to fetch exams: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<List<ExamModel>>> getUpcomingExams() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(<ExamModel>[]);
      }
      final exams = await _supabaseService.getUpcomingExams(uid);
      final models = (exams ?? []).map(ExamModel.fromJson).toList();
      return Success(models);
    } on Object catch (e, stack) {
      debugPrint('getUpcomingExams error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch upcoming exams: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<ExamModel?>> getExamById(String examId) async {
    try {
      final exams = await _supabaseService.getExams(_userId ?? '');
      final examData = exams?.firstWhere(
        (e) => e['id'] == examId,
        orElse: () => {},
      );
      if (examData == null || examData.isEmpty) {
        return const Success(null);
      }
      return Success(ExamModel.fromJson(examData));
    } on Object catch (e, stack) {
      debugPrint('getExamById error: $e');
      return Failure(
        DataException(message: 'Failed to fetch exam: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<ExamModel>> createExam({
    required String moduleId,
    required String title,
    required DateTime examDate,
    required String examType,
    String? examTime,
    String? venue,
  }) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(DataException(message: 'User not authenticated'));
      }

      final payload = {
        'user_id': uid,
        'module_id': moduleId,
        'title': title,
        'exam_date': examDate.toIso8601String().split('T').first,
        'exam_time': examTime,
        'venue': venue,
        'exam_type': examType,
      };

      final result = await _supabaseService.addExam(payload);
      if (result == null) {
        return Failure(DataException(message: 'Failed to create exam'));
      }

      return Success(ExamModel.fromJson(result));
    } on Object catch (e, stack) {
      debugPrint('createExam error: $e');
      return Failure(
        DataException(message: 'Failed to create exam: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<ExamModel>> updateExam(ExamModel exam) async {
    try {
      final payload = {
        'title': exam.title,
        'exam_date': exam.examDate.toIso8601String().split('T').first,
        'exam_time': exam.examTime,
        'venue': exam.venue,
        'exam_type': exam.examType,
      };

      final result = await _supabaseService.updateExam(exam.id, payload);
      if (result == null) {
        return Failure(DataException(message: 'Failed to update exam'));
      }

      return Success(ExamModel.fromJson(result));
    } on Object catch (e, stack) {
      debugPrint('updateExam error: $e');
      return Failure(
        DataException(message: 'Failed to update exam: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<void>> deleteExam(String examId) async {
    try {
      final success = await _supabaseService.deleteExam(examId);
      if (success != true) {
        return Failure(DataException(message: 'Failed to delete exam'));
      }
      return const Success(null);
    } on Object catch (e, stack) {
      debugPrint('deleteExam error: $e');
      return Failure(
        DataException(message: 'Failed to delete exam: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<List<ExamModel>>> getExamsByModuleId(String moduleId) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(<ExamModel>[]);
      }
      final exams = await _supabaseService.getExams(uid);
      final filtered =
          exams
              ?.where((e) => e['module_id'] == moduleId)
              .map(ExamModel.fromJson)
              .toList() ??
          [];
      return Success(filtered);
    } on Object catch (e, stack) {
      debugPrint('getExamsByModuleId error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch exams for module: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<ExamModel>>> searchExams(String query) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(<ExamModel>[]);
      }
      final exams = await _supabaseService.getExams(uid);
      final filtered =
          exams
              ?.where(
                (e) =>
                    (e['title'] as String?)?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false,
              )
              .map(ExamModel.fromJson)
              .toList() ??
          [];
      return Success(filtered);
    } on Object catch (e, stack) {
      debugPrint('searchExams error: $e');
      return Failure(
        DataException(message: 'Failed to search exams: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<int>> getExamCount() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(0);
      }
      final exams = await _supabaseService.getExams(uid);
      return Success(exams?.length ?? 0);
    } on Object catch (e, stack) {
      debugPrint('getExamCount error: $e');
      return Failure(
        DataException(
          message: 'Failed to get exam count: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> syncExams() async {
    try {
      // Since SupabaseService already handles caching and offline syncing,
      // we just trigger a fresh fetch
      final uid = _userId;
      if (uid == null) {
        return const Success(null);
      }
      await _supabaseService.getExams(uid);
      return const Success(null);
    } on Object catch (e, stack) {
      debugPrint('syncExams error: $e');
      return Failure(
        DataException(message: 'Failed to sync exams: $e', stackTrace: stack),
      );
    }
  }
}
