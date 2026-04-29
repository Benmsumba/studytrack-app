import 'package:flutter/foundation.dart';

import '../../../models/module_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../module_repository.dart';

class ModuleRepositoryImpl implements ModuleRepository {
  ModuleRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  String? get _userId => _supabaseService.getCurrentUser()?.id;

  @override
  Future<Result<List<ModuleModel>>> getAllModules() async {
    try {
      final uid = _userId;
      if (uid == null) {
        return const Success(<ModuleModel>[]);
      }
      final modules = await _supabaseService.getModules(uid);
      return Success(modules ?? <ModuleModel>[]);
    } catch (e, stack) {
      debugPrint('getAllModules error: $e');
      return Failure(
        DataException(
          message: 'Failed to fetch modules: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<ModuleModel?>> getModuleById(String moduleId) async {
    try {
      final module = await _supabaseService.getModuleById(moduleId);
      return Success(module);
    } catch (e, stack) {
      debugPrint('getModuleById error: $e');
      return Failure(
        DataException(message: 'Failed to fetch module: $e', stackTrace: stack),
      );
    }
  }

  @override
  Future<Result<ModuleModel>> createModule({
    required String name,
    required String code,
    required String description,
    String? instructorName,
    String? instructorEmail,
  }) async {
    try {
      final uid = _userId;
      if (uid == null) {
        return Failure(DataException(message: 'User not authenticated'));
      }
      final raw = await _supabaseService.addModule(uid, name, '');
      if (raw == null) {
        return Failure(DataException(message: 'Failed to create module'));
      }
      return Success(ModuleModel.fromJson(raw));
    } catch (e, stack) {
      debugPrint('createModule error: $e');
      return Failure(
        DataException(
          message: 'Failed to create module: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<ModuleModel>> updateModule(ModuleModel module) async {
    try {
      final data = module.toJson()
        ..remove('id')
        ..remove('created_at');
      final raw = await _supabaseService.updateModule(module.id, data);
      if (raw == null) {
        return Failure(DataException(message: 'Failed to update module'));
      }
      return Success(ModuleModel.fromJson(raw));
    } catch (e, stack) {
      debugPrint('updateModule error: $e');
      return Failure(
        DataException(
          message: 'Failed to update module: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteModule(String moduleId) async {
    try {
      await _supabaseService.deleteModule(moduleId);
      return const Success(null);
    } catch (e, stack) {
      debugPrint('deleteModule error: $e');
      return Failure(
        DataException(
          message: 'Failed to delete module: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> archiveModule(String moduleId) async {
    try {
      await _supabaseService.updateModule(moduleId, {'is_active': false});
      return const Success(null);
    } catch (e, stack) {
      debugPrint('archiveModule error: $e');
      return Failure(
        DataException(
          message: 'Failed to archive module: $e',
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<ModuleModel>>> getModulesBySemester(
    String semester,
  ) async {
    final result = await getAllModules();
    return result.map(
      (modules) => modules
          .where((m) => m.semester?.toLowerCase() == semester.toLowerCase())
          .toList(),
    );
  }

  @override
  Future<Result<List<ModuleModel>>> searchModules(String query) async {
    final result = await getAllModules();
    final lower = query.toLowerCase();
    return result.map(
      (modules) =>
          modules.where((m) => m.name.toLowerCase().contains(lower)).toList(),
    );
  }

  @override
  Future<Result<int>> getModuleCount() async {
    final result = await getAllModules();
    return result.map((modules) => modules.length);
  }

  @override
  Future<Result<void>> syncModules() async {
    try {
      return const Success(null);
    } catch (e, stack) {
      debugPrint('syncModules error: $e');
      return Failure(
        DataException(message: 'Failed to sync modules: $e', stackTrace: stack),
      );
    }
  }
}
