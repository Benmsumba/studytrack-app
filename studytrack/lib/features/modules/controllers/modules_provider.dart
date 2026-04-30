import 'package:flutter/foundation.dart';

import '../../../core/repositories/module_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/module_model.dart';

class ModuleActionResult {
  const ModuleActionResult({
    required this.success,
    required this.statusCode,
    required this.message,
  });

  final bool success;
  final int statusCode;
  final String message;
}

class ModulesProvider extends ChangeNotifier {
  ModulesProvider({
    ModuleRepository? moduleRepository,
    SupabaseService? supabaseService,
  }) : _moduleRepository =
           moduleRepository ??
           (supabaseService == null ? getIt<ModuleRepository>() : null),
       _legacySupabaseService = supabaseService;

  final ModuleRepository? _moduleRepository;
  final SupabaseService? _legacySupabaseService;

  List<ModuleModel> _modules = const [];
  ModuleModel? _selectedModule;
  String? _selectedModuleId;
  bool _isLoading = false;
  String? _errorMessage;

  List<ModuleModel> get modules => _modules;
  ModuleModel? get selectedModule => _selectedModule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<ModuleActionResult> loadModules(String userId) async {
    if (userId.trim().isEmpty) {
      _errorMessage = 'User context is missing. Please sign in again.';
      notifyListeners();
      return const ModuleActionResult(
        success: false,
        statusCode: 401,
        message: 'User context is missing. Please sign in again.',
      );
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      if (_legacySupabaseService != null) {
        final modulesResult = await _legacySupabaseService.getModules(userId);
        _modules = (modulesResult ?? const []).toList(growable: false);
        if (_selectedModuleId != null && _modules.isNotEmpty) {
          _selectedModule = _modules.firstWhere(
            (module) => module.id == _selectedModuleId,
            orElse: () => _modules.first,
          );
        } else if (_selectedModuleId != null) {
          _selectedModule = null;
        }
        return const ModuleActionResult(
          success: true,
          statusCode: 200,
          message: 'Modules loaded successfully.',
        );
      }

      final result = await _moduleRepository!.getAllModules();

      if (result is Failure<List<ModuleModel>>) {
        _errorMessage = result.error.message;
        return ModuleActionResult(
          success: false,
          statusCode: 500,
          message: _errorMessage ?? 'Failed to load modules.',
        );
      }

      if (result is Success<List<ModuleModel>>) {
        _modules = result.data;
        if (_selectedModuleId != null && _modules.isNotEmpty) {
          _selectedModule = _modules.firstWhere(
            (module) => module.id == _selectedModuleId,
            orElse: () => _modules.first,
          );
        } else if (_selectedModuleId != null) {
          _selectedModule = null;
        }
      }

      return const ModuleActionResult(
        success: true,
        statusCode: 200,
        message: 'Modules loaded successfully.',
      );
    } catch (error) {
      _errorMessage = 'Failed to load modules: $error';
      return ModuleActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage!,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<ModuleActionResult> addModule({
    required String name,
    String? userId,
    String? color,
    String? code,
    String? description,
    String? instructorName,
    String? instructorEmail,
  }) async {
    final nameText = name.trim();
    if (nameText.isEmpty) {
      _errorMessage = 'Module name is required.';
      notifyListeners();
      return const ModuleActionResult(
        success: false,
        statusCode: 422,
        message: 'Module name is required.',
      );
    }

    if (_legacySupabaseService != null || userId != null || color != null) {
      final legacyService = _legacySupabaseService;
      if (legacyService == null || userId == null) {
        return const ModuleActionResult(
          success: false,
          statusCode: 422,
          message: 'User context is required.',
        );
      }

      _errorMessage = null;
      try {
        final created = await legacyService.addModule(
          userId,
          nameText,
          color ?? '#000000',
        );
        if (created == null) {
          _errorMessage = 'Failed to add module.';
          notifyListeners();
          return const ModuleActionResult(
            success: false,
            statusCode: 500,
            message: 'Failed to add module.',
          );
        }

        final createdModel = ModuleModel.fromJson(created);
        _modules = [..._modules, createdModel];
        notifyListeners();
        return const ModuleActionResult(
          success: true,
          statusCode: 201,
          message: 'Module added successfully.',
        );
      } catch (error) {
        _errorMessage = 'Failed to add module: $error';
        notifyListeners();
        return ModuleActionResult(
          success: false,
          statusCode: 500,
          message: _errorMessage!,
        );
      }
    }

    _errorMessage = null;
    final result = await _moduleRepository!.createModule(
      name: nameText,
      code: code?.trim() ?? '',
      description: description?.trim() ?? '',
      instructorName: instructorName?.trim(),
      instructorEmail: instructorEmail?.trim(),
    );

    if (result is Failure<ModuleModel>) {
      _errorMessage = result.error.message;
      notifyListeners();
      return ModuleActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage ?? 'Failed to add module.',
      );
    }

    if (result is Success<ModuleModel>) {
      final created = result.data;
      _modules = [..._modules, created];
      notifyListeners();
    }

    return const ModuleActionResult(
      success: true,
      statusCode: 201,
      message: 'Module added successfully.',
    );
  }

  Future<ModuleActionResult> updateModule({
    required String moduleId,
    required dynamic changes,
  }) async {
    if (moduleId.trim().isEmpty) {
      return const ModuleActionResult(
        success: false,
        statusCode: 422,
        message: 'Module ID is required.',
      );
    }

    if (_legacySupabaseService != null || changes is Map<String, dynamic>) {
      final legacyService = _legacySupabaseService;
      if (legacyService == null) {
        return const ModuleActionResult(
          success: false,
          statusCode: 422,
          message: 'Module service is unavailable.',
        );
      }

      _errorMessage = null;
      try {
        final legacyChanges = changes is Map<String, dynamic>
            ? changes
            : Map<String, dynamic>.from(changes as Map);
        final updated = await legacyService.updateModule(
          moduleId,
          legacyChanges,
        );
        if (updated == null) {
          _errorMessage = 'Failed to update module.';
          notifyListeners();
          return const ModuleActionResult(
            success: false,
            statusCode: 500,
            message: 'Failed to update module.',
          );
        }

        final updatedModel = ModuleModel.fromJson(updated);
        _modules = _modules
            .map((module) => module.id == moduleId ? updatedModel : module)
            .toList(growable: false);
        if (_selectedModule?.id == moduleId) {
          _selectedModule = updatedModel;
        }
        notifyListeners();
        return const ModuleActionResult(
          success: true,
          statusCode: 200,
          message: 'Module updated successfully.',
        );
      } catch (error) {
        _errorMessage = 'Failed to update module: $error';
        notifyListeners();
        return ModuleActionResult(
          success: false,
          statusCode: 500,
          message: _errorMessage!,
        );
      }
    }

    _errorMessage = null;
    final result = await _moduleRepository!.updateModule(
      changes as ModuleModel,
    );

    if (result is Failure<ModuleModel>) {
      _errorMessage = result.error.message;
      notifyListeners();
      return ModuleActionResult(
        success: false,
        statusCode: 500,
        message: _errorMessage ?? 'Failed to update module.',
      );
    }

    if (result is Success<ModuleModel>) {
      final updatedModel = result.data;
      _modules = _modules
          .map((module) => module.id == moduleId ? updatedModel : module)
          .toList(growable: false);

      if (_selectedModule?.id == moduleId) {
        _selectedModule = updatedModel;
      }
      notifyListeners();
    }

    return const ModuleActionResult(
      success: true,
      statusCode: 200,
      message: 'Module updated successfully.',
    );
  }

  Future<ModuleActionResult> deleteModule(String moduleId) async {
    if (moduleId.trim().isEmpty) {
      return const ModuleActionResult(
        success: false,
        statusCode: 422,
        message: 'Module ID is required.',
      );
    }

    _errorMessage = null;
    final previous = _modules;

    _modules = _modules
        .where((module) => module.id != moduleId)
        .toList(growable: false);
    if (_selectedModule?.id == moduleId) {
      _selectedModule = null;
    }
    notifyListeners();

    if (_legacySupabaseService != null) {
      try {
        final deleted = await _legacySupabaseService.deleteModule(moduleId);
        if (deleted == true) {
          return const ModuleActionResult(
            success: true,
            statusCode: 200,
            message: 'Module deleted successfully.',
          );
        }
      } catch (error) {
        _modules = previous;
        _errorMessage = 'Failed to delete module: $error';
        notifyListeners();
        return ModuleActionResult(
          success: false,
          statusCode: 500,
          message: _errorMessage!,
        );
      }

      _modules = previous;
      _errorMessage = 'Failed to delete module.';
      notifyListeners();
      return const ModuleActionResult(
        success: false,
        statusCode: 500,
        message: 'Failed to delete module.',
      );
    }

    final result = await _moduleRepository!.deleteModule(moduleId);

    if (result is Success<void>) {
      return const ModuleActionResult(
        success: true,
        statusCode: 200,
        message: 'Module deleted successfully.',
      );
    }

    // Rollback on failure
    _modules = previous;
    if (previous.any((m) => m.id == moduleId)) {
      _selectedModule = previous.firstWhere((m) => m.id == moduleId);
    }
    _errorMessage = (result as Failure<void>).error.message;
    notifyListeners();
    return ModuleActionResult(
      success: false,
      statusCode: 500,
      message: _errorMessage ?? 'Failed to delete module.',
    );
  }

  void selectModule(ModuleModel? module) {
    _selectedModule = module;
    if (module != null) {
      _selectedModuleId = module.id;
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
