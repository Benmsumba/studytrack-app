import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';

class ModuleDetailScreen extends StatefulWidget {
  const ModuleDetailScreen({required this.moduleId, super.key});

  final String moduleId;

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  late final ModuleRepository _moduleRepository;
  late final TopicRepository _topicRepository;

  bool _isLoading = true;
  ModuleModel? _module;
  List<TopicModel> _topics = const [];
  _TopicFilter _filter = _TopicFilter.all;

  @override
  void initState() {
    super.initState();
    _moduleRepository = getIt<ModuleRepository>();
    _topicRepository = getIt<TopicRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    final moduleResult = await _moduleRepository.getModuleById(widget.moduleId);
    final topicsResult = await _topicRepository.getTopicsByModule(
      widget.moduleId,
    );

    ModuleModel? module;
    var topics = const <TopicModel>[];

    moduleResult.fold((_) {}, (value) => module = value);
    topicsResult.fold((_) {}, (value) => topics = value);

    if (!mounted) return;
    setState(() {
      _module = module;
      _topics = topics;
      _isLoading = false;
    });
  }

  Color _moduleColor() {
    final colorHex = _module?.color;
    if (colorHex == null || colorHex.isEmpty) {
      return _module?.subjectColor ?? AppColors.primary;
    }
    final sanitized = colorHex.replaceAll('#', '');
    if (sanitized.length != 6)
      return _module?.subjectColor ?? AppColors.primary;
    return Color(int.parse('FF$sanitized', radix: 16));
  }

  Future<void> _deleteTopic(String topicId) async {
    await _topicRepository.deleteTopic(topicId);
    await _load();
  }

  List<TopicModel> get _filteredTopics {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _topics.where((topic) {
      switch (_filter) {
        case _TopicFilter.all:
          return true;
        case _TopicFilter.studied:
          return topic.isStudied;
        case _TopicFilter.notStudied:
          return !topic.isStudied;
        case _TopicFilter.needsReview:
          if (topic.nextReviewAt == null) return false;
          final due = DateTime(
            topic.nextReviewAt!.year,
            topic.nextReviewAt!.month,
            topic.nextReviewAt!.day,
          );
          return !due.isAfter(today);
        case _TopicFilter.mastered:
          return (topic.currentRating ?? 0) >= 8;
      }
    }).toList();
  }

  Future<void> _showAddTopicSheet() async {
    final controller = TextEditingController();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, viewInsets.bottom + 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Topic',
                style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Topic name',
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
              GestureDetector(
                onTap: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  await _topicRepository.createTopic(
                    moduleId: widget.moduleId,
                    name: text,
                    description: '',
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Save Topic',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final moduleColor = _moduleColor();
    final studiedCount = _topics.where((t) => t.isStudied).length;
    final ratedTopics = _topics.where((t) => t.currentRating != null).toList();
    final averageRating = ratedTopics.isEmpty
        ? 0.0
        : ratedTopics.map((t) => t.currentRating!).reduce((a, b) => a + b) /
              ratedTopics.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTopicSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Topic',
          style: AppTextStyles.button.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _module == null
          ? Center(
              child: Text(
                'Module not found.',
                style: AppTextStyles.bodyMediumSecondary,
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          moduleColor.withValues(alpha: 0.6),
                          AppColors.cardDark,
                        ],
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _module!.name,
                          style: AppTextStyles.headingLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatChip(label: '${_topics.length} topics'),
                            const SizedBox(width: 8),
                            _StatChip(label: '$studiedCount studied'),
                            const SizedBox(width: 8),
                            _StatChip(
                              label:
                                  'Avg ${averageRating.toStringAsFixed(1)}/10',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _TopicFilter.values.map((filter) {
                      final selected = _filter == filter;
                      return ChoiceChip(
                        label: Text(filter.label),
                        selected: selected,
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.cardDark,
                        side: const BorderSide(color: AppColors.border),
                        onSelected: (_) => setState(() => _filter = filter),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  if (_filteredTopics.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'No topics in this filter.',
                          style: AppTextStyles.bodyMediumSecondary,
                        ),
                      ),
                    )
                  else
                    ..._filteredTopics.map((topic) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final isDue =
                          topic.nextReviewAt != null &&
                          !DateTime(
                            topic.nextReviewAt!.year,
                            topic.nextReviewAt!.month,
                            topic.nextReviewAt!.day,
                          ).isAfter(today);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Slidable(
                          key: ValueKey(topic.id),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) => _deleteTopic(topic.id),
                                backgroundColor: AppColors.danger,
                                icon: Icons.delete_rounded,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () => context.push('/topics/${topic.id}'),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          topic.name,
                                          style: AppTextStyles.headingSmall
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                        ),
                                      ),
                                      if (topic.isStudied)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.success,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _ratingBadgeColor(topic),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${topic.currentRating ?? 0}/10',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isDue)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: AppColors.warning,
                                            ),
                                          ),
                                          child: Text(
                                            'Due for review',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.warning,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Color _ratingBadgeColor(TopicModel topic) {
    final rating = topic.currentRating ?? 0;
    if (rating <= 4) return AppColors.danger;
    if (rating <= 6) return AppColors.warning;
    return AppColors.success;
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

enum _TopicFilter {
  all('All'),
  studied('Studied'),
  notStudied('Not Studied'),
  needsReview('Needs Review'),
  mastered('Mastered');

  const _TopicFilter(this.label);
  final String label;
}
