import 'package:flutter/foundation.dart';

import '../../../models/module_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/result.dart';
import '../module_repository.dart';

/// Implementation of ModuleRepository using SupabaseService
class ModuleRepositoryImpl implements ModuleRepository {
  final SupabaseService _supabaseService;

  ModuleRepositoryImpl(this._supabaseService);

  @override
  Future<Result<List<ModuleModel>>> getAllModules() async {
    try {
      final modules = await _supabaseService.getModules();
      return Success(modules);
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
      final module = await _supabaseService.getModule(moduleId);
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
      final module = await _supabaseService.createModule(
        name: name,
        code: code,
        description: description,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
      );
      return Success(module);
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
      final updated = await _supabaseService.updateModule(module);
      return Success(updated);
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
      await _supabaseService.archiveModule(moduleId);
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
  Future<Result<List<ModuleModel>>> getModulesBySemester(String semester) {
    // TODO: Implement in SupabaseService
    throw UnimplementedError();
  }

  @override
  Future<Result<List<ModuleModel>>> searchModules(String query) {
    // TODO: Implement in SupabaseService
    throw UnimplementedError();
  }

  @override
  Future<Result<int>> getModuleCount() {
    // TODO: Implement in SupabaseService
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> syncModules() async {
    try {
      // Sync handled by offline sync service
      return const Success(null);
    } catch (e, stack) {
      debugPrint('syncModules error: $e');
      return Failure(
        DataException(message: 'Failed to sync modules: $e', stackTrace: stack),
      );
    }
  }
}
