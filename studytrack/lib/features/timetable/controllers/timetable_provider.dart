import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/class_slot_model.dart';
import '../../../models/study_session_model.dart';

class TimetableProvider extends ChangeNotifier {
  TimetableProvider({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

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

  Future<void> loadTimetable(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final classRows = await _supabaseService.getClassTimetable(userId);
      final sessionRows = await _supabaseService.getStudySessions(
        userId,
        _selectedDate,
      );

      _classSlots = (classRows ?? const [])
          .map(ClassSlotModel.fromJson)
          .toList(growable: false);
      _studySessions = (sessionRows ?? const [])
          .map(StudySessionModel.fromJson)
          .toList(growable: false);
    } catch (error) {
      _errorMessage = 'Failed to load timetable: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addClassSlot(Map<String, dynamic> classData) async {
    _errorMessage = null;

    final created = await _supabaseService.addClassSlot(classData);
    if (created == null) {
      _errorMessage = 'Failed to add class slot.';
      notifyListeners();
      return;
    }

    _classSlots = [..._classSlots, ClassSlotModel.fromJson(created)]
      ..sort((a, b) {
        if (a.dayOfWeek == b.dayOfWeek) {
          return a.startTime.compareTo(b.startTime);
        }
        return a.dayOfWeek.compareTo(b.dayOfWeek);
      });
    notifyListeners();
  }

  Future<void> addStudySession(Map<String, dynamic> sessionData) async {
    _errorMessage = null;

    final created = await _supabaseService.addStudySession(sessionData);
    if (created == null) {
      _errorMessage = 'Failed to add study session.';
      notifyListeners();
      return;
    }

    final model = StudySessionModel.fromJson(created);
    final sameDate = _isSameDate(model.scheduledDate, _selectedDate);
    if (sameDate) {
      _studySessions = [..._studySessions, model]
        ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
      notifyListeners();
    }
  }

  Future<void> completeSession(String sessionId, {int? actualDuration}) async {
    final updated = await _supabaseService.updateSessionStatus(
      sessionId,
      'completed',
      actualDuration,
    );

    if (updated == null) {
      _errorMessage = 'Failed to complete session.';
      notifyListeners();
      return;
    }

    _replaceSession(StudySessionModel.fromJson(updated));
  }

  Future<void> missSession(String sessionId) async {
    final updated = await _supabaseService.updateSessionStatus(
      sessionId,
      'missed',
      null,
    );

    if (updated == null) {
      _errorMessage = 'Failed to mark session as missed.';
      notifyListeners();
      return;
    }

    _replaceSession(StudySessionModel.fromJson(updated));
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

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
