import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/module_model.dart';

class ModulesProvider extends ChangeNotifier {
  ModulesProvider({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService();

  final SupabaseService _supabaseService;

  List<ModuleModel> _modules = const [];
  ModuleModel? _selectedModule;
  bool _isLoading = false;
  String? _errorMessage;

  List<ModuleModel> get modules => _modules;
  ModuleModel? get selectedModule => _selectedModule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadModules(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _supabaseService.getModules(userId);
      _modules = response ?? const [];
      if (_selectedModule != null) {
        _selectedModule = _modules.firstWhere(
          (module) => module.id == _selectedModule!.id,
          orElse: () => _modules.isNotEmpty ? _modules.first : _selectedModule!,
        );
      }
    } catch (error) {
      _errorMessage = 'Failed to load modules: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addModule({
    required String userId,
    required String name,
    required String color,
  }) async {
    _errorMessage = null;

    final created = await _supabaseService.addModule(userId, name, color);
    if (created == null) {
      _errorMessage = 'Failed to add module.';
      notifyListeners();
      return;
    }

    _modules = [..._modules, ModuleModel.fromJson(created)];
    notifyListeners();
  }

  Future<void> updateModule({
    required String moduleId,
    required Map<String, dynamic> changes,
  }) async {
    _errorMessage = null;

    final updated = await _supabaseService.updateModule(moduleId, changes);
    if (updated == null) {
      _errorMessage = 'Failed to update module.';
      notifyListeners();
      return;
    }

    final updatedModel = ModuleModel.fromJson(updated);
    _modules = _modules
        .map((module) => module.id == moduleId ? updatedModel : module)
        .toList(growable: false);

    if (_selectedModule?.id == moduleId) {
      _selectedModule = updatedModel;
    }

    notifyListeners();
  }

  Future<void> deleteModule(String moduleId) async {
    _errorMessage = null;

    final success = await _supabaseService.deleteModule(moduleId);
    if (success != true) {
      _errorMessage = 'Failed to delete module.';
      notifyListeners();
      return;
    }

    _modules = _modules
        .where((module) => module.id != moduleId)
        .toList(growable: false);
    if (_selectedModule?.id == moduleId) {
      _selectedModule = null;
    }
    notifyListeners();
  }

  void selectModule(ModuleModel? module) {
    _selectedModule = module;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
