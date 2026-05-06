import 'package:flutter/foundation.dart';

import '../../../core/repositories/class_timetable_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/class_slot_model.dart';
import '../../../models/study_session_model.dart';

class TimetableActionResult {
  const TimetableActionResult({
    required this.success,
    required this.statusCode,
    required this.message,
  });

  final bool success;
  final int statusCode;
  final String message;
}

class TimetableProvider extends ChangeNotifier {
  TimetableProvider({
    ClassTimetableRepository? classTimetableRepository,
    StudySessionRepository? studySessionRepository,
    SupabaseService? supabaseService,
  }) : _classTimetableRepository =
           classTimetableRepository ?? getIt<ClassTimetableRepository>(),
       _studySessionRepository =
           studySessionRepository ?? getIt<StudySessionRepository>(),
       // Raw service kept only for addStudySession until StudySessionRepository
       // gains a scheduleSession method that supports the full timetable payload.
       _supabaseService = supabaseService ?? getIt<SupabaseService>();

  final ClassTimetableRepository _classTimetableRepository;
  final StudySessionRepository _studySessionRepository;
  final SupabaseService _supabaseService;

  List<ClassSlotModel> _classSlots = const [];
  List<StudySessionModel> _studySessions = const [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  List<ClassSlotModel> get classSlots => _classSlots;
  List<StudySessionModel> get studySessions => _studySessions;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Auth is resolved inside the repository — no userId required here.
  Future<TimetableActionResult> loadTimetable() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final classResult = await _classTimetableRepository.getClassTimetable('');

      final outcome = classResult.fold(
        (error) {
          _errorMessage = error.message;
          return TimetableActionResult(
            success: false,
            statusCode: _statusCode(error),
            message: error.message,
          );
        },
        (slots) {
          _classSlots = slots;
          return const TimetableActionResult(
            success: true,
            statusCode: 200,
            message: 'Timetable loaded successfully.',
          );
        },
      );

      _studySessions = const [];
      return outcome;
    } catch (error) {
      _errorMessage = 'Failed to load timetable: $error';
      return TimetableActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage!,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<TimetableActionResult> addClassSlot(
    Map<String, dynamic> classData,
  ) async {
    final subject = classData['subject_name']?.toString().trim() ?? '';
    if (subject.isEmpty) {
      return _validationFailure('Subject name is required.');
    }

    _errorMessage = null;

    final result = await _classTimetableRepository.addClassSlot(classData);

    return result.fold(
      (error) {
        _errorMessage = error.message;
        notifyListeners();
        return TimetableActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (created) {
        _classSlots = [..._classSlots, created]
          ..sort((a, b) => a.dayOfWeek == b.dayOfWeek
              ? a.startTime.compareTo(b.startTime)
              : a.dayOfWeek.compareTo(b.dayOfWeek));
        notifyListeners();
        return const TimetableActionResult(
          success: true,
          statusCode: 201,
          message: 'Class slot added successfully.',
        );
      },
    );
  }

  Future<TimetableActionResult> updateClassSlot({
    required String classSlotId,
    required Map<String, dynamic> classData,
  }) async {
    if (classSlotId.trim().isEmpty) {
      return _validationFailure('Class slot id is required.');
    }

    final result = await _classTimetableRepository.updateClassSlot(
      classSlotId: classSlotId,
      classData: classData,
    );

    return result.fold(
      (error) {
        _errorMessage = error.message;
        notifyListeners();
        return TimetableActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (updatedModel) {
        _classSlots = _classSlots
            .map((slot) => slot.id == classSlotId ? updatedModel : slot)
            .toList(growable: false)
          ..sort((a, b) => a.dayOfWeek == b.dayOfWeek
              ? a.startTime.compareTo(b.startTime)
              : a.dayOfWeek.compareTo(b.dayOfWeek));
        notifyListeners();
        return const TimetableActionResult(
          success: true,
          statusCode: 200,
          message: 'Class slot updated successfully.',
        );
      },
    );
  }

  /// Optimistic UI: removes immediately and rolls back on failure.
  Future<TimetableActionResult> deleteClassSlot(String classSlotId) async {
    if (classSlotId.trim().isEmpty) {
      return _validationFailure('Class slot id is required.');
    }

    final previous = _classSlots;
    _classSlots = _classSlots
        .where((slot) => slot.id != classSlotId)
        .toList(growable: false);
    notifyListeners();

    final result = await _classTimetableRepository.deleteClassSlot(classSlotId);

    return result.fold(
      (error) {
        _classSlots = previous;
        _errorMessage = error.message;
        notifyListeners();
        return TimetableActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (deleted) {
        if (deleted != true) {
          _classSlots = previous;
          _errorMessage = 'Failed to delete class slot.';
          notifyListeners();
          return const TimetableActionResult(
            success: false,
            statusCode: 500,
            message: 'Failed to delete class slot.',
          );
        }
        return const TimetableActionResult(
          success: true,
          statusCode: 200,
          message: 'Class slot deleted successfully.',
        );
      },
    );
  }

  Future<TimetableActionResult> addStudySession(
    Map<String, dynamic> sessionData,
  ) async {
    final title = sessionData['title']?.toString().trim() ?? '';
    if (title.isEmpty) {
      return _validationFailure('Session title is required.');
    }

    _errorMessage = null;

    final created = await _supabaseService.addStudySession(sessionData);
    if (created == null) {
      _errorMessage = 'Failed to add study session.';
      notifyListeners();
      return const TimetableActionResult(
        success: false,
        statusCode: 500,
        message: 'Failed to add study session.',
      );
    }

    final model = StudySessionModel.fromJson(created);
    if (_isSameDate(model.scheduledDate, _selectedDate)) {
      _studySessions = [..._studySessions, model]
        ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
      notifyListeners();
    }
    return const TimetableActionResult(
      success: true,
      statusCode: 201,
      message: 'Study session added successfully.',
    );
  }

  /// Optimistic UI: marks complete immediately, rolls back on failure.
  Future<TimetableActionResult> completeSession(
    String sessionId, {
    int? actualDuration,
  }) async {
    final index =
        _studySessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) {
      return const TimetableActionResult(
        success: false,
        statusCode: 404,
        message: 'Study session not found.',
      );
    }

    final previous = _studySessions[index];
    _replaceSession(
      previous.copyWith(
        status: 'completed',
        actualDurationMinutes: actualDuration,
      ),
    );
    _errorMessage = null;

    final result = await _studySessionRepository.updateSessionStatus(
      sessionId: sessionId,
      status: 'completed',
      actualDurationMinutes: actualDuration,
    );

    return result.fold(
      (error) {
        _replaceSession(previous);
        _errorMessage = error.message;
        notifyListeners();
        return TimetableActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (_) => const TimetableActionResult(
        success: true,
        statusCode: 200,
        message: 'Session marked as completed.',
      ),
    );
  }

  /// Optimistic UI: marks missed immediately, rolls back on failure.
  Future<TimetableActionResult> missSession(String sessionId) async {
    final index =
        _studySessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) {
      return const TimetableActionResult(
        success: false,
        statusCode: 404,
        message: 'Study session not found.',
      );
    }

    final previous = _studySessions[index];
    _replaceSession(
      previous.copyWith(status: 'missed', actualDurationMinutes: null),
    );
    _errorMessage = null;

    final result = await _studySessionRepository.updateSessionStatus(
      sessionId: sessionId,
      status: 'missed',
    );

    return result.fold(
      (error) {
        _replaceSession(previous);
        _errorMessage = error.message;
        notifyListeners();
        return TimetableActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (_) => const TimetableActionResult(
        success: true,
        statusCode: 200,
        message: 'Session marked as missed.',
      ),
    );
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _replaceSession(StudySessionModel updated) {
    _studySessions = _studySessions
        .map((session) => session.id == updated.id ? updated : session)
        .toList(growable: false);
    notifyListeners();
  }

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  TimetableActionResult _validationFailure(String message) {
    _errorMessage = message;
    notifyListeners();
    return TimetableActionResult(
      success: false,
      statusCode: 422,
      message: message,
    );
  }

  int _statusCode(AppException error) => switch (error) {
    ValidationException() => 422,
    AuthException() => 401,
    OfflineException() => 503,
    _ => 500,
  };

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
