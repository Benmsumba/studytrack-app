import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/app_state_view.dart';
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
  String? _loadError;
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
      _loadError = null;
    });

    final moduleResult = await _moduleRepository.getModuleById(widget.moduleId);
    final topicsResult = await _topicRepository.getTopicsByModule(
      widget.moduleId,
    );

    ModuleModel? module;
    var topics = const <TopicModel>[];
    final moduleFailed = moduleResult is Failure<ModuleModel?>;
    final topicsFailed = topicsResult is Failure<List<TopicModel>>;

    moduleResult.fold((_) {}, (value) => module = value);
    topicsResult.fold((_) {}, (value) => topics = value);

    if (!mounted) return;
    setState(() {
      _module = module;
      _topics = topics;
      _loadError = moduleFailed || topicsFailed
          ? 'We could not load this module right now. Pull to retry.'
          : null;
      _isLoading = false;
    });
  }

  Color _moduleColor() {
    final colorHex = _module?.color;
    if (colorHex == null || colorHex.isEmpty) {
      return _module?.subjectColor ?? AppColors.primary;
    }
    final sanitized = colorHex.replaceAll('#', '');
    if (sanitized.length != 6) {
      return _module?.subjectColor ?? AppColors.primary;
    }
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
      backgroundColor: const Color(0xFF1A1A2E),
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
                  color: AppColors.parchment,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.parchment,
                ),
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
                    color: AppColors.signal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'SAVE TOPIC',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.parchment,
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

  Future<void> _showRateTopicSheet(TopicModel topic) async {
    int tempRating = topic.currentRating ?? 5;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final viewInsets = MediaQuery.of(context).viewInsets;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, viewInsets.bottom + 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate: ${topic.name}',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '$tempRating/10',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Slider(
                    value: tempRating.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: const Color(0xFF4F46E5),
                    inactiveColor: Colors.white24,
                    label: tempRating.toString(),
                    onChanged: (value) {
                      setSheet(() {
                        tempRating = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await _topicRepository.rateTopic(topic.id, tempRating);
                      if (!context.mounted) return;
                      Navigator.of(context).pop(true);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SAVE RATING',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0FF),
      body: Column(
        children: [
          // Indigo header
          Container(
            color: const Color(0xFF4F46E5),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Module Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_module != null)
                        Text(
                          _module!.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Filter chips
          if (!_isLoading && _loadError == null && _module != null)
            Container(
              color: const Color(0xFFF0F0FF),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _TopicFilter.values.map((filter) {
                    final selected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF4F46E5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF4F46E5)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            filter.label,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF6B6880),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          // Topic list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F46E5),
                    ),
                  )
                : _loadError != null
                ? Center(
                    child: AppStateView.error(
                      title: 'Module unavailable',
                      message: _loadError!,
                      onRetry: _load,
                    ),
                  )
                : _module == null
                ? Center(
                    child: AppStateView.empty(
                      icon: Icons.layers_outlined,
                      title: 'Module not found',
                      message:
                          'This module may have been removed or renamed.',
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF4F46E5),
                    onRefresh: _load,
                    child: _filteredTopics.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              const SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'No topics in this filter.',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: _filteredTopics.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final topic = _filteredTopics[index];
                              return Slidable(
                                key: ValueKey(topic.id),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) =>
                                          _deleteTopic(topic.id),
                                      backgroundColor: AppColors.danger,
                                      icon: Icons.delete_rounded,
                                      label: 'Delete',
                                    ),
                                  ],
                                ),
                                child: _TopicRow(
                                  topic: topic,
                                  onTap: () =>
                                      context.push('/topics/${topic.id}'),
                                  onToggle: () =>
                                      _showRateTopicSheet(topic),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTopicSheet,
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.onTap,
    required this.onToggle,
  });

  final TopicModel topic;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final rating = topic.currentRating ?? 0;
    final isStudied = topic.isStudied;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isStudied
                      ? const Color(0xFF4F46E5)
                      : Colors.transparent,
                  border: Border.all(
                    color: isStudied
                        ? const Color(0xFF4F46E5)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isStudied
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Topic name
            Expanded(
              child: Text(
                topic.name,
                style: const TextStyle(
                  color: Color(0xFF1A1730),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Star rating (2 rows of 5) + label
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStarRow(rating, 1, 5),
                const SizedBox(height: 2),
                _buildStarRow(rating, 6, 10),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              '$rating/10',
              style: const TextStyle(
                color: Color(0xFF6B6880),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRow(int rating, int from, int to) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(to - from + 1, (i) {
        final starIndex = from + i;
        final filled = starIndex <= rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFFBBF24),
          size: 14,
        );
      }),
    );
  }
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
