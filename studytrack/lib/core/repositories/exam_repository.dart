import '../../models/exam_model.dart';
import '../utils/result.dart';

/// Abstract interface for exam operations
abstract class ExamRepository {
  /// Fetch all exams for current user
  Future<Result<List<ExamModel>>> getAllExams();

  /// Fetch upcoming exams for current user (exams on or after today)
  Future<Result<List<ExamModel>>> getUpcomingExams();

  /// Fetch single exam by ID
  Future<Result<ExamModel?>> getExamById(String examId);

  /// Create new exam
  Future<Result<ExamModel>> createExam({
    required String moduleId,
    required String title,
    required DateTime examDate,
    required String examType,
    String? examTime,
    String? venue,
  });

  /// Update existing exam
  Future<Result<ExamModel>> updateExam(ExamModel exam);

  /// Delete exam by ID
  Future<Result<void>> deleteExam(String examId);

  /// Get exams for a specific module
  Future<Result<List<ExamModel>>> getExamsByModuleId(String moduleId);

  /// Search exams by title
  Future<Result<List<ExamModel>>> searchExams(String query);

  /// Get exam count
  Future<Result<int>> getExamCount();

  /// Sync exams with backend
  Future<Result<void>> syncExams();
}
