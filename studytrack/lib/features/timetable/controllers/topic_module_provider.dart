import 'package:flutter/foundation.dart';

import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';

/// Provider for managing topics and modules for the schedule add/edit form
class TopicModuleProvider extends ChangeNotifier {
  TopicModuleProvider({
    ModuleRepository? moduleRepository,
    TopicRepository? topicRepository,
  }) : _moduleRepository = moduleRepository ?? getIt<ModuleRepository>(),
       _topicRepository = topicRepository ?? getIt<TopicRepository>();

  final ModuleRepository _moduleRepository;
  final TopicRepository _topicRepository;

  List<ModuleModel> _modules = const [];
  List<TopicModel> _topics = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ModuleModel> get modules => _modules;
  List<TopicModel> get topics => _topics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all modules and topics for the current user in two round-trips:
  /// one for modules, one batch query for all their topics.
  Future<void> loadModulesAndTopics() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final moduleResult = await _moduleRepository.getAllModules();

      moduleResult.fold((error) {
        _errorMessage = error.message;
        return;
      }, (modules) => _modules = modules);

      if (_errorMessage != null) return;

      final moduleIds = _modules.map((m) => m.id).toList();
      if (moduleIds.isEmpty) {
        _topics = const [];
        return;
      }

      final topicResult = await _topicRepository.getTopicsByModuleIds(
        moduleIds,
      );

      topicResult.fold(
        (error) => _errorMessage = error.message,
        (topics) => _topics = topics,
      );
    } catch (e) {
      debugPrint('loadModulesAndTopics error: $e');
      _errorMessage = 'Failed to load topics and modules: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Get topics for a specific module
  List<TopicModel> getTopicsForModule(String moduleId) =>
      _topics.where((t) => t.moduleId == moduleId).toList();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
