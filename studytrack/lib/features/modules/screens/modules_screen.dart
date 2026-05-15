import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/utils/haptics.dart';
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

  Widget _buildLoadingGrid() {
    return AppStateView.loadingGrid(itemCount: 4, childAspectRatio: 0.78);
  }

  Widget _buildGrid() {
    if (_loadError != null) {
      return Center(
        child: AppStateView.error(
          title: 'Modules unavailable',
          message: _loadError!,
          onRetry: _loadModules,
        ),
      );
    }

    if (_filteredModules.isEmpty) {
      return Center(
        child: AppStateView.empty(
          icon: Icons.layers_outlined,
          title: _query.trim().isEmpty ? 'No modules yet' : 'No matches found',
          message: _query.trim().isEmpty
              ? 'Add your first module to start tracking your coursework.'
              : 'Try a different search term or clear the filter.',
          actionLabel: _query.trim().isEmpty ? 'Add Module' : null,
          onAction:
              _query.trim().isEmpty ? _showAddOrEditModuleSheet : null,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: _filteredModules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final module = _filteredModules[index];
        final topics = _topicsByModule[module.id] ?? const <TopicModel>[];
        final stats = _ModuleStats.fromTopics(topics);

        return GestureDetector(
          onLongPress: () {
            Haptics.medium();
            _showCardOptions(module);
          },
          onTap: () {
            Haptics.light();
            context.push('/modules/${module.id}');
          },
          child: _ModuleCard(module: module, stats: stats),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/profile'),
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Modules List',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Glass search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search modules...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.07),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF4F46E5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Grid or empty/loading state
            Expanded(
              child: _isLoading
                  ? _buildLoadingGrid()
                  : RefreshIndicator(
                      color: AppColors.emeraldAccent,
                      onRefresh: _loadModules,
                      child: _buildGrid(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Haptics.light();
          _showAddOrEditModuleSheet();
        },
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
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

  IconData _moduleIcon() {
    final name = module.name.toLowerCase();
    if (name.contains('anatomy')) return Icons.biotech_rounded;
    if (name.contains('data') || name.contains('struct')) {
      return Icons.storage_rounded;
    }
    if (name.contains('physio')) return Icons.favorite_rounded;
    if (name.contains('bio') || name.contains('chem')) {
      return Icons.science_rounded;
    }
    if (name.contains('pharma')) return Icons.medication_rounded;
    if (name.contains('network') || name.contains('computer')) {
      return Icons.cloud_rounded;
    }
    if (name.contains('neuro')) return Icons.psychology_rounded;
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = _parseColor();
    final percent = (stats.studiedProgress * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xCC1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: subjectColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: subjectColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: subjectColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(_moduleIcon(), color: subjectColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      module.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Large circular arc ring centered
              Center(
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: _ModuleRingPainter(
                          progress: stats.studiedProgress,
                          color: subjectColor,
                        ),
                        size: const Size(90, 90),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
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
        20,
        16,
        20,
        viewInsets.bottom + 24,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.parchment,
                      ),
                    )
                  : Text(
                      (widget.module == null ? 'Add Module' : 'Save Changes')
                          .toUpperCase(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleRingPainter extends CustomPainter {
  const _ModuleRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const pi = 3.14159265359;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    if (progress <= 0) return;
    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ModuleRingPainter old) =>
      old.progress != progress || old.color != color;
}
