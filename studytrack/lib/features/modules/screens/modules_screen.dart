import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';
import '../../auth/controllers/auth_provider.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final ModuleRepository _moduleRepo = getIt<ModuleRepository>();
  final TopicRepository _topicRepo = getIt<TopicRepository>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _loadError;
  String _query = '';
  List<ModuleModel> _modules = const [];
  Map<String, List<TopicModel>> _topicsByModule = const {};

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadModules() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final modulesResult = await _moduleRepo.getAllModules();
    final modules = switch (modulesResult) {
      Success<List<ModuleModel>>(data: final data) => data,
      Failure<List<ModuleModel>>() => <ModuleModel>[],
    };
    final modulesFailed = modulesResult is Failure<List<ModuleModel>>;

    final topicsByModule = <String, List<TopicModel>>{};
    var topicsFailed = false;
    for (final module in modules) {
      final topicsResult = await _topicRepo.getTopicsByModule(module.id);
      topicsByModule[module.id] = switch (topicsResult) {
        Success<List<TopicModel>>(data: final data) => data,
        Failure<List<TopicModel>>() => <TopicModel>[],
      };
      topicsFailed = topicsFailed || topicsResult is Failure<List<TopicModel>>;
    }

    if (!mounted) return;
    setState(() {
      _modules = modules;
      _topicsByModule = topicsByModule;
      _loadError = modulesFailed || topicsFailed
          ? 'We could not load your modules right now. Pull to retry.'
          : null;
      _isLoading = false;
    });
  }

  List<ModuleModel> get _filteredModules {
    if (_query.trim().isEmpty) {
      return _modules;
    }
    final q = _query.toLowerCase();
    return _modules.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _showAddOrEditModuleSheet({ModuleModel? module}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          _AddModuleBottomSheet(moduleRepo: _moduleRepo, module: module),
    );

    if (changed == true) {
      await _loadModules();
    }
  }

  Future<void> _showCardOptions(ModuleModel module) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white),
              title: Text(
                'Edit name',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showAddOrEditModuleSheet(module: module);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_rounded, color: Colors.white),
              title: Text(
                'Change color',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showAddOrEditModuleSheet(module: module);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_rounded,
                color: AppColors.danger,
              ),
              title: Text(
                'Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.danger,
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _moduleRepo.deleteModule(module.id);
                await _loadModules();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: _isLoading
        ? AppStateView.loadingGrid(itemCount: 4, childAspectRatio: 0.78)
        : RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceDark,
            onRefresh: _loadModules,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xs,
                AppSpacing.screenHorizontal,
                120,
              ),
              children: [
                TextField(
                  controller: _searchController,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search modules',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                GlowingButton(
                  label: 'Add Module',
                  onPressed: _showAddOrEditModuleSheet,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: AppStateView.error(
                      title: 'Modules unavailable',
                      message: _loadError!,
                      onRetry: _loadModules,
                    ),
                  )
                else if (_filteredModules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: AppStateView.empty(
                      icon: Icons.layers_outlined,
                      title: _query.trim().isEmpty
                          ? 'No modules yet'
                          : 'No matches found',
                      message: _query.trim().isEmpty
                          ? 'Add your first module to start tracking your coursework.'
                          : 'Try a different search term or clear the filter.',
                      actionLabel: _query.trim().isEmpty ? 'Add Module' : null,
                      onAction: _query.trim().isEmpty
                          ? _showAddOrEditModuleSheet
                          : null,
                    ),
                  )
                else
                  GridView.builder(
                    itemCount: _filteredModules.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (context, index) {
                      final module = _filteredModules[index];
                      final topics =
                          _topicsByModule[module.id] ?? const <TopicModel>[];
                      final stats = _ModuleStats.fromTopics(topics);

                      return GestureDetector(
                        onLongPress: () => _showCardOptions(module),
                        onTap: () => context.push('/modules/${module.id}'),
                        child: _ModuleCard(module: module, stats: stats),
                      );
                    },
                  ),
              ],
            ),
          ),
  );
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.stats});

  final ModuleModel module;
  final _ModuleStats stats;

  Color _parseColor() {
    final color = module.color;
    if (color == null || color.isEmpty) {
      return module.subjectColor;
    }
    final sanitized = color.replaceAll('#', '');
    if (sanitized.length != 6) {
      return module.subjectColor;
    }
    return Color(int.parse('FF$sanitized', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = _parseColor();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [subjectColor.withValues(alpha: 0.45), AppColors.cardDark],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.totalTopics} topics',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: stats.mastery,
            minHeight: 8,
            backgroundColor: AppColors.surfaceDark,
            color: AppColors.success,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 6),
          Text(
            '${(stats.mastery * 100).round()}% rated 7+',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  value: stats.studiedProgress,
                  backgroundColor: AppColors.surfaceDark,
                  color: AppColors.accent,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${stats.studiedTopics}/${stats.totalTopics} studied',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleStats {
  factory _ModuleStats.fromTopics(List<TopicModel> topics) {
    if (topics.isEmpty) {
      return const _ModuleStats(totalTopics: 0, studiedTopics: 0, mastery: 0);
    }

    final studied = topics.where((t) => t.isStudied).length;
    final mastered = topics.where((t) => (t.currentRating ?? 0) >= 7).length;

    return _ModuleStats(
      totalTopics: topics.length,
      studiedTopics: studied,
      mastery: mastered / topics.length,
    );
  }
  const _ModuleStats({
    required this.totalTopics,
    required this.studiedTopics,
    required this.mastery,
  });

  final int totalTopics;
  final int studiedTopics;
  final double mastery;

  double get studiedProgress {
    if (totalTopics == 0) return 0;
    return studiedTopics / totalTopics;
  }
}

class _AddModuleBottomSheet extends StatefulWidget {
  const _AddModuleBottomSheet({required this.moduleRepo, this.module});

  final ModuleRepository moduleRepo;
  final ModuleModel? module;

  @override
  State<_AddModuleBottomSheet> createState() => _AddModuleBottomSheetState();
}

class _AddModuleBottomSheetState extends State<_AddModuleBottomSheet> {
  late final TextEditingController _nameController;
  late Color _selectedColor;
  bool _isSaving = false;

  List<Color> get _palette => AppColors.subjectColors.values.toSet().toList();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.module?.name ?? '');
    _selectedColor = _resolveInitialColor();
  }

  Color _resolveInitialColor() {
    final hex = widget.module?.color;
    if (hex == null || hex.isEmpty) {
      return AppColors.primary;
    }
    final sanitized = hex.replaceAll('#', '');
    if (sanitized.length != 6) {
      return AppColors.primary;
    }
    return Color(int.parse('FF$sanitized', radix: 16));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _hexColor(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSaving) {
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    if (widget.module == null) {
      await widget.moduleRepo.createModule(
        name: name,
        code: name.toLowerCase().replaceAll(' ', '-'),
        description: '',
      );
    } else {
      final updated = widget.module!.copyWith(
        name: name,
        color: _hexColor(_selectedColor),
      );
      await widget.moduleRepo.updateModule(updated);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.module == null ? 'Add Module' : 'Edit Module',
            style: AppTextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Module name',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _palette.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final color = _palette[index];
                final selected = color.toARGB32() == _selectedColor.toARGB32();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 42 : 36,
                    height: selected ? 42 : 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlowingButton(
            label: widget.module == null ? 'Add Module' : 'Save Changes',
            onPressed: _isSaving ? null : _save,
            isLoading: _isSaving,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
