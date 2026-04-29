import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
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
    final user = _service.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final modules = await _service.getModules(user.id) ?? [];
    final topicsByModule = <String, List<TopicModel>>{};
    for (final module in modules) {
      topicsByModule[module.id] = await _service.getTopics(module.id) ?? [];
    }

    if (!mounted) return;
    setState(() {
      _modules = modules;
      _topicsByModule = topicsByModule;
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
      builder: (context) => _AddModuleBottomSheet(
        service: _service,
        module: module,
      ),
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
                  style: GoogleFonts.inter(color: Colors.white),
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
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddOrEditModuleSheet(module: module);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: AppColors.danger),
                title: Text(
                  'Delete',
                  style: GoogleFonts.inter(color: AppColors.danger),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _service.deleteModule(module.id);
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _loadModules,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                children: [
                  TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search modules',
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
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
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _showAddOrEditModuleSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Add Module',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filteredModules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 44),
                      child: Center(
                        child: Text(
                          'No modules yet. Add your first module.',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      itemCount: _filteredModules.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                          onLongPress: () => _showCardOptions(module),
                          onTap: () => context.push('/modules/${module.id}'),
                          child: _ModuleCard(
                            module: module,
                            stats: stats,
                          ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            subjectColor.withValues(alpha: 0.45),
            AppColors.cardDark,
          ],
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
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.totalTopics} topics',
            style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
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
  const _AddModuleBottomSheet({required this.service, this.module});

  final SupabaseService service;
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

    final user = widget.service.getCurrentUser();
    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    if (widget.module == null) {
      await widget.service.addModule(user.id, name, _hexColor(_selectedColor));
    } else {
      await widget.service.updateModule(widget.module!.id, {
        'name': name,
        'color': _hexColor(_selectedColor),
      });
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, viewInsets.bottom + 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.module == null ? 'Add Module' : 'Edit Module',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Module name',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
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
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.module == null ? 'Add Module' : 'Save Changes',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

}