import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/core/repositories/module_repository.dart';
import 'package:studytrack/core/utils/app_exception.dart';
import 'package:studytrack/core/utils/result.dart';
import 'package:studytrack/features/modules/controllers/modules_provider.dart';
import 'package:studytrack/models/module_model.dart';

// ---------------------------------------------------------------------------
// Manual mock
// ---------------------------------------------------------------------------

class _FakeModuleRepository implements ModuleRepository {
  List<ModuleModel>? allModulesResult;
  ModuleModel? getModuleByIdResult;
  ModuleModel? createModuleResult;
  ModuleModel? updateModuleResult;
  bool shouldThrow = false;
  String errorMessage = 'Operation failed';

  @override
  Future<Result<List<ModuleModel>>> getAllModules() async {
    if (shouldThrow) {
      return Failure(OfflineException(message: errorMessage));
    }
    return Success(allModulesResult ?? []);
  }

  @override
  Future<Result<ModuleModel?>> getModuleById(String moduleId) async {
    if (shouldThrow) {
      return Failure(OfflineException(message: errorMessage));
    }
    return Success(getModuleByIdResult);
  }

  @override
  Future<Result<ModuleModel>> createModule({
    required String name,
    required String code,
    required String description,
    String? color,
    String? instructorName,
    String? instructorEmail,
  }) async {
    if (shouldThrow) {
      return Failure(OfflineException(message: errorMessage));
    }
    if (createModuleResult == null) {
      return Failure(ValidationException(message: 'Module creation failed'));
    }
    return Success(createModuleResult!);
  }

  @override
  Future<Result<ModuleModel>> updateModule(ModuleModel module) async {
    if (shouldThrow) {
      return Failure(OfflineException(message: errorMessage));
    }
    if (updateModuleResult == null) {
      return Failure(ValidationException(message: 'Module update failed'));
    }
    return Success(updateModuleResult!);
  }

  @override
  Future<Result<void>> deleteModule(String moduleId) async {
    if (shouldThrow) {
      return Failure(OfflineException(message: errorMessage));
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> archiveModule(String moduleId) async => const Success(null);

  @override
  Future<Result<List<ModuleModel>>> getModulesBySemester(
    String semester,
  ) async => const Success([]);

  @override
  Future<Result<List<ModuleModel>>> searchModules(String query) async =>
      const Success([]);

  @override
  Future<Result<int>> getModuleCount() async => const Success(0);

  @override
  Future<Result<void>> syncModules() async => const Success(null);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ModuleModel _module({
  String id = 'mod-1',
  String userId = 'user-1',
  String name = 'Anatomy',
}) => ModuleModel(
  id: id,
  userId: userId,
  name: name,
  color: '#FF0000',
  semester: null,
  isActive: true,
  createdAt: DateTime.now(),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  late _FakeModuleRepository fake;
  late ModulesProvider provider;

  setUp(() {
    fake = _FakeModuleRepository();
    provider = ModulesProvider(moduleRepository: fake);
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
      fake.allModulesResult = [
        _module(),
        _module(id: 'mod-2', name: 'Physiology'),
      ];

      final result = await provider.loadModules();

      expect(result.success, isTrue);
      expect(provider.modules.length, 2);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('handles empty list response', () async {
      fake.allModulesResult = [];

      final result = await provider.loadModules();

      expect(result.success, isTrue);
      expect(provider.modules, isEmpty);
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when service fails', () async {
      fake.shouldThrow = true;
      fake.errorMessage = 'Network error';

      final result = await provider.loadModules();

      expect(result.success, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('updates selectedModule reference after reload', () async {
      fake.allModulesResult = [_module()];
      await provider.loadModules();
      final selectedModule = provider.modules.first;
      provider.selectModule(selectedModule);

      // Reload with updated name
      fake.allModulesResult = [_module(name: 'Anatomy Updated')];
      await provider.loadModules();

      expect(provider.selectedModule?.name, 'Anatomy Updated');
    });
  });

  group('ModulesProvider — addModule', () {
    test('appends new module to list on success', () async {
      fake.allModulesResult = [_module()];
      await provider.loadModules();

      fake.createModuleResult = _module(id: 'mod-2', name: 'Biochemistry');
      final result = await provider.addModule(
        name: 'Biochemistry',
        color: '#00FF00',
      );

      expect(result.success, isTrue);
      expect(provider.modules.length, 2);
      expect(provider.modules.last.name, 'Biochemistry');
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when service returns failure', () async {
      fake.createModuleResult = null;

      final result = await provider.addModule(name: 'X');

      expect(result.success, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('validates module name is not empty', () async {
      final result = await provider.addModule(name: '   ');

      expect(result.success, isFalse);
      expect(provider.errorMessage, contains('required'));
    });
  });

  group('ModulesProvider — updateModule', () {
    test('replaces module in list and updates selectedModule', () async {
      fake.allModulesResult = [_module()];
      await provider.loadModules();
      final selectedModule = provider.modules.first;
      provider.selectModule(selectedModule);

      final updatedModule = _module(name: 'Anatomy II');
      fake.updateModuleResult = updatedModule;

      final result = await provider.updateModule(updatedModule);

      expect(result.success, isTrue);
      expect(provider.modules.first.name, 'Anatomy II');
      expect(provider.selectedModule?.name, 'Anatomy II');
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when service returns failure', () async {
      fake.updateModuleResult = null;

      final result = await provider.updateModule(_module());

      expect(result.success, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('validates module ID is not empty', () async {
      final badModule = _module(id: '   ');

      final result = await provider.updateModule(badModule);

      expect(result.success, isFalse);
      expect(provider.errorMessage, contains('ID'));
    });
  });

  group('ModulesProvider — deleteModule', () {
    test('removes module from list and clears selectedModule', () async {
      fake.allModulesResult = [
        _module(),
        _module(id: 'mod-2', name: 'Physiology'),
      ];
      await provider.loadModules();
      final selectedModule = provider.modules.first;
      provider.selectModule(selectedModule);

      final result = await provider.deleteModule('mod-1');

      expect(result.success, isTrue);
      expect(provider.modules.length, 1);
      expect(provider.modules.first.id, 'mod-2');
      expect(provider.selectedModule, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when service fails', () async {
      fake.shouldThrow = true;

      final result = await provider.deleteModule('mod-1');

      expect(result.success, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('validates module ID is not empty', () async {
      final result = await provider.deleteModule('   ');

      expect(result.success, isFalse);
      expect(provider.errorMessage, contains('ID'));
    });
  });

  group('ModulesProvider — selectModule', () {
    test('updates selectedModule and notifies listeners', () async {
      fake.allModulesResult = [_module()];
      await provider.loadModules();

      var notified = false;
      provider.addListener(() => notified = true);

      provider.selectModule(provider.modules.first);

      expect(provider.selectedModule?.id, 'mod-1');
      expect(notified, isTrue);
    });

    test('can deselect by passing null', () async {
      fake.allModulesResult = [_module()];
      await provider.loadModules();
      final selectedModule = provider.modules.first;
      provider.selectModule(selectedModule);
      provider.selectModule(null);

      expect(provider.selectedModule, isNull);
    });
  });
}
