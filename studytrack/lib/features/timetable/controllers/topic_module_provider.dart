import 'package:flutter/foundation.dart';

import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/utils/result.dart';
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

  /// Load all modules and topics for the current user
  Future<void> loadModulesAndTopics() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Fetch all modules
      final moduleResult = await _moduleRepository.getAllModules();

      if (moduleResult is! Success<List<ModuleModel>>) {
        _errorMessage = 'Failed to load modules';
        notifyListeners();
        return;
      }

      _modules = moduleResult.data;

      // Fetch all topics for each module
      final allTopics = <TopicModel>[];
      for (final module in _modules) {
        final topicResult = await _topicRepository.getTopicsByModule(module.id);

        if (topicResult is Success<List<TopicModel>>) {
          final topics = topicResult.data;
          allTopics.addAll(topics);
        }
      }

      _topics = allTopics;
    } catch (e) {
      debugPrint('loadModulesAndTopics error: $e');
      _errorMessage = 'Failed to load topics and modules: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Get topics for a specific module
  List<TopicModel> getTopicsForModule(String moduleId) => _topics.where((t) => t.moduleId == moduleId).toList();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
