import '../../models/module_model.dart';
import '../utils/result.dart';

/// Abstract interface for module operations
abstract class ModuleRepository {
  /// Fetch all modules for current user
  Future<Result<List<ModuleModel>>> getAllModules();

  /// Fetch single module by ID
  Future<Result<ModuleModel?>> getModuleById(String moduleId);

  /// Create new module
  Future<Result<ModuleModel>> createModule({
    required String name,
    required String code,
    required String description,
    String? color,
    String? instructorName,
    String? instructorEmail,
  });

  /// Update existing module
  Future<Result<ModuleModel>> updateModule(ModuleModel module);

  /// Delete module by ID
  Future<Result<void>> deleteModule(String moduleId);

  /// Archive module (soft delete)
  Future<Result<void>> archiveModule(String moduleId);

  /// Get modules for a specific semester
  Future<Result<List<ModuleModel>>> getModulesBySemester(String semester);

  /// Search modules by name
  Future<Result<List<ModuleModel>>> searchModules(String query);

  /// Get module count
  Future<Result<int>> getModuleCount();

  /// Sync modules with backend
  Future<Result<void>> syncModules();
}
