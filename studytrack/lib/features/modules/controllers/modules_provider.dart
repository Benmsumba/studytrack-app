import 'package:flutter/foundation.dart';

import '../../../core/repositories/module_repository.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/module_model.dart';

/// UI command result — carries the outcome of a mutating operation.
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
  ModulesProvider({ModuleRepository? moduleRepository})
      : _repo = moduleRepository ?? getIt<ModuleRepository>();

  final ModuleRepository _repo;

  List<ModuleModel> _modules = const [];
  ModuleModel? _selectedModule;
  bool _isLoading = false;
  String? _errorMessage;

  List<ModuleModel> get modules => _modules;
  ModuleModel? get selectedModule => _selectedModule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Auth is resolved inside the repository — no userId required here.
  Future<ModuleActionResult> loadModules() async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _repo.getAllModules();

    return result.fold(
      (error) {
        _errorMessage = error.message;
        _setLoading(false);
        return ModuleActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (modules) {
        _modules = modules;
        // Rehydrate selected module if it's still present after reload.
        if (_selectedModule != null) {
          _selectedModule = _modules
              .where((m) => m.id == _selectedModule!.id)
              .firstOrNull;
        }
        _setLoading(false);
        return const ModuleActionResult(
          success: true,
          statusCode: 200,
          message: 'Modules loaded successfully.',
        );
      },
    );
  }

  Future<ModuleActionResult> addModule({
    required String name,
    String? color,
    String? code,
    String? description,
    String? instructorName,
    String? instructorEmail,
  }) async {
    final nameText = name.trim();
    if (nameText.isEmpty) {
      return _validationFailure('Module name is required.');
    }

    _errorMessage = null;

    final result = await _repo.createModule(
      name: nameText,
      color: color,
      code: code?.trim() ?? '',
      description: description?.trim() ?? '',
      instructorName: instructorName?.trim(),
      instructorEmail: instructorEmail?.trim(),
    );

    return result.fold(
      (error) {
        _errorMessage = error.message;
        notifyListeners();
        return ModuleActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (created) {
        _modules = [..._modules, created];
        notifyListeners();
        return const ModuleActionResult(
          success: true,
          statusCode: 201,
          message: 'Module added successfully.',
        );
      },
    );
  }

  /// Optimistic UI: applies the change immediately and rolls back on failure.
  Future<ModuleActionResult> updateModule(ModuleModel module) async {
    if (module.id.trim().isEmpty) {
      return _validationFailure('Module ID is required.');
    }

    // Snapshot for rollback.
    final previousModules = _modules;
    final previousSelected = _selectedModule;

    // Apply optimistically before the async call.
    _modules = _modules
        .map((m) => m.id == module.id ? module : m)
        .toList(growable: false);
    if (_selectedModule?.id == module.id) {
      _selectedModule = module;
    }
    notifyListeners();

    final result = await _repo.updateModule(module);

    return result.fold(
      (error) {
        // Rollback to pre-update state.
        _modules = previousModules;
        _selectedModule = previousSelected;
        _errorMessage = error.message;
        notifyListeners();
        return ModuleActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (updated) {
        // Reconcile with the authoritative server response.
        _modules = _modules
            .map((m) => m.id == updated.id ? updated : m)
            .toList(growable: false);
        if (_selectedModule?.id == updated.id) {
          _selectedModule = updated;
        }
        notifyListeners();
        return const ModuleActionResult(
          success: true,
          statusCode: 200,
          message: 'Module updated successfully.',
        );
      },
    );
  }

  /// Optimistic UI: removes immediately and rolls back on failure.
  Future<ModuleActionResult> deleteModule(String moduleId) async {
    if (moduleId.trim().isEmpty) {
      return _validationFailure('Module ID is required.');
    }

    // Snapshot for rollback.
    final previousModules = _modules;
    final previousSelected = _selectedModule;

    // Apply optimistically before the async call.
    _modules = _modules
        .where((m) => m.id != moduleId)
        .toList(growable: false);
    if (_selectedModule?.id == moduleId) {
      _selectedModule = null;
    }
    notifyListeners();

    final result = await _repo.deleteModule(moduleId);

    return result.fold(
      (error) {
        // Rollback to pre-delete state.
        _modules = previousModules;
        _selectedModule = previousSelected;
        _errorMessage = error.message;
        notifyListeners();
        return ModuleActionResult(
          success: false,
          statusCode: _statusCode(error),
          message: error.message,
        );
      },
      (_) => const ModuleActionResult(
        success: true,
        statusCode: 200,
        message: 'Module deleted successfully.',
      ),
    );
  }

  void selectModule(ModuleModel? module) {
    _selectedModule = module;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  ModuleActionResult _validationFailure(String message) {
    _errorMessage = message;
    notifyListeners();
    return ModuleActionResult(
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
