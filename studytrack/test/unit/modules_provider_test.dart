import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/core/services/supabase_service.dart';
import 'package:studytrack/features/modules/controllers/modules_provider.dart';
import 'package:studytrack/models/module_model.dart';

// ---------------------------------------------------------------------------
// Manual mock
// ---------------------------------------------------------------------------

class _FakeSupabaseService extends SupabaseService {
  _FakeSupabaseService() : super.forTesting();

  List<ModuleModel>? modulesResult;
  Map<String, dynamic>? addResult;
  Map<String, dynamic>? updateResult;
  bool? deleteResult;
  bool shouldThrow = false;

  @override
  Future<List<ModuleModel>?> getModules(String userId) async {
    if (shouldThrow) {
      throw Exception('network error');
    }
    return modulesResult;
  }

  @override
  Future<Map<String, dynamic>?> addModule(
    String userId,
    String name,
    String color,
  ) async {
    if (shouldThrow) {
      throw Exception('network error');
    }
    return addResult;
  }

  @override
  Future<Map<String, dynamic>?> updateModule(
    String moduleId,
    Map<String, dynamic> data,
  ) async {
    if (shouldThrow) {
      throw Exception('network error');
    }
    return updateResult;
  }

  @override
  Future<bool?> deleteModule(String moduleId) async {
    if (shouldThrow) {
      throw Exception('network error');
    }
    return deleteResult;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _moduleJson({
  String id = 'mod-1',
  String userId = 'user-1',
  String name = 'Anatomy',
}) => {
  'id': id,
  'user_id': userId,
  'name': name,
  'color': '#FF0000',
  'semester': null,
  'is_active': true,
  'created_at': DateTime.now().toIso8601String(),
};

ModuleModel _module({
  String id = 'mod-1',
  String userId = 'user-1',
  String name = 'Anatomy',
}) => ModuleModel.fromJson(_moduleJson(id: id, userId: userId, name: name));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  late _FakeSupabaseService fake;
  late ModulesProvider provider;

  setUp(() {
    fake = _FakeSupabaseService();
    provider = ModulesProvider(supabaseService: fake);
  });

  group('ModulesProvider — initial state', () {
    test('starts empty with no loading or error', () {
      expect(provider.modules, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.selectedModule, isNull);
    });
  });

  group('ModulesProvider — loadModules', () {
    test('populates modules on success', () async {
      fake.modulesResult = [
        _module(),
        _module(id: 'mod-2', name: 'Physiology'),
      ];

      await provider.loadModules('user-1');

      expect(provider.modules.length, 2);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('handles null response as empty list', () async {
      fake.modulesResult = [];

      await provider.loadModules('user-1');

      expect(provider.modules, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when service throws', () async {
      fake.shouldThrow = true;

      await provider.loadModules('user-1');

      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Failed to load'));
      expect(provider.isLoading, isFalse);
    });

    test('updates selectedModule reference after reload', () async {
      final mod = _module();
      fake.modulesResult = [mod];
      await provider.loadModules('user-1');
      final selectedModule = provider.modules.first;
      provider
        ..selectModule(selectedModule)
        ..selectModule(null);

      // Reload with updated name
      fake.modulesResult = [_module(name: 'Anatomy Updated')];
      await provider.loadModules('user-1');

      expect(provider.selectedModule?.name, 'Anatomy Updated');
    });
  });

  group('ModulesProvider — addModule', () {
    test('appends new module to list on success', () async {
      fake.modulesResult = [_module()];
      await provider.loadModules('user-1');

      fake.addResult = _moduleJson(id: 'mod-2', name: 'Biochemistry');
      await provider.addModule(
        userId: 'user-1',
        name: 'Biochemistry',
        color: '#00FF00',
      );

      expect(provider.modules.length, 2);
      expect(provider.modules.last.name, 'Biochemistry');
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when service returns null', () async {
      fake.addResult = null;

      await provider.addModule(userId: 'user-1', name: 'X', color: '#000');

      expect(provider.errorMessage, 'Failed to add module.');
    });
  });

  group('ModulesProvider — updateModule', () {
    test('replaces module in list and updates selectedModule', () async {
      fake.modulesResult = [_module()];
      await provider.loadModules('user-1');
      final selectedModule = provider.modules.first;
      provider.selectModule(selectedModule);

      final updatedJson = _moduleJson(name: 'Anatomy II');
      fake.updateResult = updatedJson;

      await provider.updateModule(
        moduleId: 'mod-1',
        changes: {'name': 'Anatomy II'},
      );

      expect(provider.modules.first.name, 'Anatomy II');
      expect(provider.selectedModule?.name, 'Anatomy II');
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when service returns null', () async {
      fake.updateResult = null;

      await provider.updateModule(moduleId: 'mod-1', changes: {});

      expect(provider.errorMessage, 'Failed to update module.');
    });
  });

  group('ModulesProvider — deleteModule', () {
    test('removes module from list and clears selectedModule', () async {
      fake.modulesResult = [
        _module(),
        _module(id: 'mod-2', name: 'Physiology'),
      ];
      await provider.loadModules('user-1');
      final selectedModule = provider.modules.first;
      provider.selectModule(selectedModule);

      fake.deleteResult = true;
      await provider.deleteModule('mod-1');

      expect(provider.modules.length, 1);
      expect(provider.modules.first.id, 'mod-2');
      expect(provider.selectedModule, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when service returns null/false', () async {
      fake.deleteResult = null;

      await provider.deleteModule('mod-1');

      expect(provider.errorMessage, 'Failed to delete module.');
    });
  });

  group('ModulesProvider — selectModule', () {
    test('updates selectedModule and notifies listeners', () async {
      fake.modulesResult = [_module()];
      await provider.loadModules('user-1');

      var notified = false;
      provider.addListener(() => notified = true);

      provider.selectModule(provider.modules.first);

      expect(provider.selectedModule?.id, 'mod-1');
      expect(notified, isTrue);
    });

    test('can deselect by passing null', () async {
      fake.modulesResult = [_module()];
      await provider.loadModules('user-1');
      final selectedModule = provider.modules.first;
      provider
        ..selectModule(selectedModule)
        ..selectModule(null);

      expect(provider.selectedModule, isNull);
    });
  });
}
