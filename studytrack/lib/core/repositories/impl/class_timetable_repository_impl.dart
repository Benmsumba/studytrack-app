import 'package:flutter/foundation.dart';

import '../../../models/class_slot_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../class_timetable_repository.dart';

/// Implementation of ClassTimetableRepository using SupabaseService
class ClassTimetableRepositoryImpl implements ClassTimetableRepository {
  ClassTimetableRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  @override
  Future<Result<List<ClassSlotModel>>> getClassTimetable(String userId) async {
    try {
      final rows = await _supabaseService.getClassTimetable(userId);
      if (rows == null) {
        return const Success([]);
      }
      final classSlots = rows
          .map(ClassSlotModel.fromJson)
          .toList();
      return Success(classSlots);
    } catch (e, stack) {
      debugPrint('getClassTimetable error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch class timetable: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<ClassSlotModel>> addClassSlot(
    Map<String, dynamic> classData,
  ) async {
    try {
      final created = await _supabaseService.addClassSlot(classData);
      if (created == null) {
        return Failure(DataException(message: 'Failed to add class slot.'));
      }
      final classSlot = ClassSlotModel.fromJson(created);
      return Success(classSlot);
    } catch (e, stack) {
      debugPrint('addClassSlot error: $e');
      return Failure(
        DataException(
          message: 'Failed to add class slot: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<ClassSlotModel>> updateClassSlot({
    required String classSlotId,
    required Map<String, dynamic> classData,
  }) async {
    try {
      final updated = await _supabaseService.updateClassSlot(
        classSlotId,
        classData,
      );
      if (updated == null) {
        return Failure(DataException(message: 'Failed to update class slot.'));
      }
      final classSlot = ClassSlotModel.fromJson(updated);
      return Success(classSlot);
    } catch (e, stack) {
      debugPrint('updateClassSlot error: $e');
      return Failure(
        DataException(
          message: 'Failed to update class slot: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> deleteClassSlot(String classSlotId) async {
    try {
      final deleted = await _supabaseService.deleteClassSlot(classSlotId);
      if (deleted == true) {
        return const Success(true);
      }
      return Failure(DataException(message: 'Failed to delete class slot.'));
    } catch (e, stack) {
      debugPrint('deleteClassSlot error: $e');
      return Failure(
        DataException(
          message: 'Failed to delete class slot: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<ClassSlotModel>>> getClassSlotsByDay({
    required String userId,
    required int dayOfWeek,
  }) async {
    try {
      final rows = await _supabaseService.getClassTimetable(userId);
      if (rows == null) {
        return const Success([]);
      }
      final classSlots = rows
          .map(ClassSlotModel.fromJson)
          .where((slot) => slot.dayOfWeek == dayOfWeek)
          .toList();
      return Success(classSlots);
    } catch (e, stack) {
      debugPrint('getClassSlotsByDay error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch class slots for day: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<ClassSlotModel>>> getClassSlotsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final rows = await _supabaseService.getClassTimetable(userId);
      if (rows == null) {
        return const Success([]);
      }
      final classSlots = rows
          .map(ClassSlotModel.fromJson)
          .toList();
      return Success(classSlots);
    } catch (e, stack) {
      debugPrint('getClassSlotsByDateRange error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch class slots for date range: $e',
          stackTrace: stack,
        ),
      );
    }
  }
}
