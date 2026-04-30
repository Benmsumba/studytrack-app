import '../../models/class_slot_model.dart';
import '../utils/result.dart';

/// Abstract interface for class timetable operations
abstract class ClassTimetableRepository {
  /// Fetch all class slots for a user
  Future<Result<List<ClassSlotModel>>> getClassTimetable(String userId);

  /// Add a new class slot
  Future<Result<ClassSlotModel>> addClassSlot(Map<String, dynamic> classData);

  /// Update an existing class slot
  Future<Result<ClassSlotModel>> updateClassSlot({
    required String classSlotId,
    required Map<String, dynamic> classData,
  });

  /// Delete a class slot
  Future<Result<bool>> deleteClassSlot(String classSlotId);

  /// Fetch class slots for a specific day
  Future<Result<List<ClassSlotModel>>> getClassSlotsByDay({
    required String userId,
    required int dayOfWeek,
  });

  /// Fetch class slots for a date range
  Future<Result<List<ClassSlotModel>>> getClassSlotsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
