import 'package:flutter/foundation.dart';

import '../../../core/repositories/class_timetable_repository.dart';
import '../../../core/repositories/study_session_repository.dart';
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
  }) : _classTimetableRepository =
           classTimetableRepository ?? getIt<ClassTimetableRepository>(),
       _studySessionRepository =
           studySessionRepository ?? getIt<StudySessionRepository>();
  final ClassTimetableRepository _classTimetableRepository;
  final StudySessionRepository _studySessionRepository;

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

  Future<TimetableActionResult> loadTimetable(String userId) async {
    if (userId.trim().isEmpty) {
      _errorMessage = 'User context is missing. Please sign in again.';
      notifyListeners();
      return const TimetableActionResult(
        success: false,
        statusCode: 401,
        message: 'User context is missing. Please sign in again.',
      );
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final classResult = await _classTimetableRepository.getClassTimetable(
        userId,
      );

      if (classResult is Failure<List<ClassSlotModel>>) {
        _errorMessage = classResult.error.message;
        return TimetableActionResult(
          success: false,
          statusCode: 500,
          message: _errorMessage ?? 'Failed to load class timetable.',
        );
      }

      if (classResult is Success<List<ClassSlotModel>>) {
        _classSlots = classResult.data;
      }

      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final sessionResult = await _studySessionRepository
          .getSessionsByDateRange(startDate: startOfDay, endDate: endOfDay);

      if (sessionResult is Failure<List<StudySessionModel>>) {
        _errorMessage = sessionResult.error.message;
        _studySessions = const [];
        return TimetableActionResult(
          success: false,
          statusCode: 500,
          message: _errorMessage ?? 'Failed to load study sessions.',
        );
      }

      if (sessionResult is Success<List<StudySessionModel>>) {
        _studySessions = sessionResult.data
          ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
      }

      return const TimetableActionResult(
        success: true,
        statusCode: 200,
        message: 'Timetable loaded successfully.',
      );
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
      _errorMessage = 'Subject name is required.';
      notifyListeners();
      return const TimetableActionResult(
        success: false,
        statusCode: 422,
        message: 'Subject name is required.',
      );
    }

    _errorMessage = null;

    final result = await _classTimetableRepository.addClassSlot(classData);

    if (result is Failure<ClassSlotModel>) {
      _errorMessage = result.error.message;
      notifyListeners();
      return TimetableActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage ?? 'Failed to add class slot.',
      );
    }

    if (result is Success<ClassSlotModel>) {
      final created = result.data;
      _classSlots = [..._classSlots, created]
        ..sort((a, b) {
          if (a.dayOfWeek == b.dayOfWeek) {
            return a.startTime.compareTo(b.startTime);
          }
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        });
      notifyListeners();
    }

    return const TimetableActionResult(
      success: true,
      statusCode: 201,
      message: 'Class slot added successfully.',
    );
  }

  Future<TimetableActionResult> updateClassSlot({
    required String classSlotId,
    required Map<String, dynamic> classData,
  }) async {
    if (classSlotId.trim().isEmpty) {
      return const TimetableActionResult(
        success: false,
        statusCode: 422,
        message: 'Class slot id is required.',
      );
    }

    final result = await _classTimetableRepository.updateClassSlot(
      classSlotId: classSlotId,
      classData: classData,
    );

    if (result is Failure<ClassSlotModel>) {
      _errorMessage = result.error.message;
      notifyListeners();
      return TimetableActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage ?? 'Failed to update class slot.',
      );
    }

    if (result is Success<ClassSlotModel>) {
      final updatedModel = result.data;
      _classSlots =
          _classSlots
              .map((slot) => slot.id == classSlotId ? updatedModel : slot)
              .toList(growable: false)
            ..sort((a, b) {
              if (a.dayOfWeek == b.dayOfWeek) {
                return a.startTime.compareTo(b.startTime);
              }
              return a.dayOfWeek.compareTo(b.dayOfWeek);
            });
      notifyListeners();
    }

    return const TimetableActionResult(
      success: true,
      statusCode: 200,
      message: 'Class slot updated successfully.',
    );
  }

  Future<TimetableActionResult> deleteClassSlot(String classSlotId) async {
    if (classSlotId.trim().isEmpty) {
      return const TimetableActionResult(
        success: false,
        statusCode: 422,
        message: 'Class slot id is required.',
      );
    }

    final previous = _classSlots;
    _classSlots = _classSlots
        .where((slot) => slot.id != classSlotId)
        .toList(growable: false);
    notifyListeners();

    final result = await _classTimetableRepository.deleteClassSlot(classSlotId);

    if (result is Success<bool>) {
      final deleted = result.data;
      if (deleted == true) {
        return const TimetableActionResult(
          success: true,
          statusCode: 200,
          message: 'Class slot deleted successfully.',
        );
      }
    }

    _classSlots = previous;
    if (result is Failure<bool>) {
      _errorMessage = result.error.message;
    } else {
      _errorMessage = 'Failed to delete class slot.';
    }
    notifyListeners();
    return TimetableActionResult(
      success: false,
      statusCode: 500,
      message: _errorMessage ?? 'Failed to delete class slot.',
    );
  }

  Future<TimetableActionResult> addStudySession(
    Map<String, dynamic> sessionData,
  ) async {
    final title = sessionData['title']?.toString().trim() ?? '';
    if (title.isEmpty) {
      _errorMessage = 'Session title is required.';
      notifyListeners();
      return const TimetableActionResult(
        success: false,
        statusCode: 422,
        message: 'Session title is required.',
      );
    }

    _errorMessage = null;
    // Map the payload to the repository method parameters where possible.
    final topicId = sessionData['topic_id']?.toString();
    final duration = (sessionData['duration_minutes'] is int)
        ? sessionData['duration_minutes'] as int
        : int.tryParse(sessionData['duration_minutes']?.toString() ?? '') ?? 0;
    final focusArea = sessionData['title']?.toString() ?? '';
    final notes = sessionData['notes']?.toString();

    try {
      final result = await _studySessionRepository.createSession(
        topicId: topicId ?? '',
        duration: duration,
        focusArea: focusArea,
        notes: notes,
      );

      if (result is Failure<StudySessionModel>) {
        _errorMessage = result.error.message;
        notifyListeners();
        return TimetableActionResult(
          success: false,
          statusCode: 500,
          message: _errorMessage ?? 'Failed to add study session.',
        );
      }

      final model = (result as Success<StudySessionModel>).data;
      final sameDate = _isSameDate(model.scheduledDate, _selectedDate);
      if (sameDate) {
        _studySessions = [..._studySessions, model]
          ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
        notifyListeners();
      }
      return const TimetableActionResult(
        success: true,
        statusCode: 201,
        message: 'Study session added successfully.',
      );
    } on Exception catch (e) {
      _errorMessage = 'Failed to add study session: $e';
      notifyListeners();
      return TimetableActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage ?? 'Failed to add study session.',
      );
    }
  }

  Future<TimetableActionResult> completeSession(
    String sessionId, {
    int? actualDuration,
  }) async {
    final index = _studySessions.indexWhere(
      (session) => session.id == sessionId,
    );
    if (index == -1) {
      return const TimetableActionResult(
        success: false,
        statusCode: 404,
        message: 'Study session not found.',
      );
    }

    final previous = _studySessions[index];
    final optimistic = previous.copyWith(
      status: 'completed',
      actualDurationMinutes: actualDuration,
    );

    _replaceSession(optimistic);
    _errorMessage = null;

    final result = await _studySessionRepository.updateSessionStatus(
      sessionId: sessionId,
      status: 'completed',
      actualDurationMinutes: actualDuration,
    );

    if (result is Success<void>) {
      return const TimetableActionResult(
        success: true,
        statusCode: 200,
        message: 'Session marked as completed.',
      );
    }

    _replaceSession(previous);
    _errorMessage = (result as Failure<void>).error.message;
    notifyListeners();
    return TimetableActionResult(
      success: false,
      statusCode: 500,
      message: _errorMessage ?? 'Failed to complete session.',
    );
  }

  Future<TimetableActionResult> missSession(String sessionId) async {
    final index = _studySessions.indexWhere(
      (session) => session.id == sessionId,
    );
    if (index == -1) {
      return const TimetableActionResult(
        success: false,
        statusCode: 404,
        message: 'Study session not found.',
      );
    }

    final previous = _studySessions[index];
    final optimistic = previous.copyWith(
      status: 'missed',
      actualDurationMinutes: null,
    );

    _replaceSession(optimistic);
    _errorMessage = null;

    final result = await _studySessionRepository.updateSessionStatus(
      sessionId: sessionId,
      status: 'missed',
    );

    if (result is Success<void>) {
      return const TimetableActionResult(
        success: true,
        statusCode: 200,
        message: 'Session marked as missed.',
      );
    }

    _replaceSession(previous);
    _errorMessage = (result as Failure<void>).error.message;
    notifyListeners();
    return TimetableActionResult(
      success: false,
      statusCode: 500,
      message: _errorMessage ?? 'Failed to mark session as missed.',
    );
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
