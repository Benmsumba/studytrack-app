import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/repositories/topic_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';
import '../../../models/topic_rating_history_model.dart';
import '../../../models/uploaded_note_model.dart';
import '../../auth/controllers/auth_provider.dart';
import '../../voice_notes/widgets/voice_note_player_widget.dart';
import '../../voice_notes/widgets/voice_note_recorder_widget.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({required this.topicId, super.key});

  final String topicId;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  final TopicRepository _topicRepo = getIt<TopicRepository>();
  final ModuleRepository _moduleRepo = getIt<ModuleRepository>();
  final StorageService _storageService = StorageService();
  final SupabaseService _supabaseService = getIt<SupabaseService>();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingNotes = false;
  bool _isUploadingNote = false;
  bool _notesExpanded = true;
  String? _loadError;
  TopicModel? _topic;
  ModuleModel? _module;
  List<Map<String, dynamic>> _ratingHistory = const [];
  List<UploadedNoteModel> _uploadedNotes = const [];
  final Map<String, String> _voiceNoteTranscripts = {};
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final topicResult = await _topicRepo.getTopicById(widget.topicId);
    final topic = topicResult is Success<TopicModel?> ? topicResult.data : null;
    final topicFailed = topicResult is Failure<TopicModel?>;
    final module = topic == null
        ? null
        : await _moduleRepo
              .getModuleById(topic.moduleId)
              .then((r) => r is Success<ModuleModel?> ? r.data : null);

    final historyResult = await _topicRepo.getTopicRatingHistory(
      widget.topicId,
    );
    final history = historyResult is Success<List<TopicRatingHistoryModel>>
        ? historyResult.data
              .map((h) => {'rating': h.rating, 'ratedAt': h.ratedAt})
              .toList()
        : <Map<String, dynamic>>[];
    final historyFailed =
        historyResult is Failure<List<TopicRatingHistoryModel>>;
    final notes = await _supabaseService.getNotesByTopic(widget.topicId);
    final uploadedNotes = (notes ?? <Map<String, dynamic>>[])
        .map(UploadedNoteModel.fromJson)
        .toList(growable: false);

    if (!mounted) return;
    setState(() {
      _topic = topic;
      _module = module;
      _ratingHistory = history;
      _uploadedNotes = uploadedNotes;
      _voiceNoteTranscripts.clear();
      _selectedRating = topic?.currentRating ?? 0;
      _notesController.text = topic?.notes ?? '';
      _loadError = topicFailed || historyFailed
          ? 'We could not load this topic right now. Pull to retry.'
          : null;
      _isLoading = false;
    });
  }

  List<FlSpot> get _historySpots {
    if (_ratingHistory.isEmpty) {
      return const [FlSpot(0, 0)];
    }

    return _ratingHistory.asMap().entries.map((entry) {
      final item = entry.value;
      final rating = (item['rating'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), rating);
    }).toList();
  }

  Future<void> _saveNotes() async {
    if (_topic == null || _isSavingNotes) return;

    setState(() {
      _isSavingNotes = true;
    });

    await _topicRepo.updateTopicNotes(_topic!.id, _notesController.text);

    if (!mounted) return;
    setState(() {
      _isSavingNotes = false;
    });
  }

  Future<void> _uploadNote() async {
    final topic = _topic;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (topic == null || user == null || _isUploadingNote) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'pptx'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    if (kIsWeb || pickedFile.path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File upload from web is not enabled for this flow yet.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingNote = true;
    });

    final uploadResult = await _storageService.uploadNoteFile(
      file: File(pickedFile.path!),
      topicId: topic.id,
      userId: user.id,
      isSharedWithGroup: false,
    );

    if (!mounted) return;
    setState(() {
      _isUploadingNote = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uploadResult == null
              ? 'Upload failed. Please try again.'
              : 'File uploaded successfully.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await _load();
  }

  Future<void> _toggleShare(UploadedNoteModel note, bool value) async {
    final updated = await _supabaseService.updateUploadedNoteSharing(
      note.id,
      value,
    );
    if (!mounted) return;
    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update note sharing.')),
      );
      return;
    }

    await _load();
  }

  Future<void> _deleteUploadedNote(String noteId) async {
    final deleted = await _supabaseService.deleteUploadedNote(noteId);
    if (!mounted) return;
    if (deleted != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete uploaded note.')),
      );
      return;
    }

    await _load();
  }

  Future<void> _saveRating() async {
    if (_selectedRating < 1 || _topic == null) {
      return;
    }

    await _topicRepo.rateTopic(_topic!.id, _selectedRating);
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating saved.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPlannedFeature(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label will be wired in the next AI phase.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: _isLoading
          ? AppStateView.loadingList(itemCount: 4, itemHeight: 120)
          : _loadError != null
          ? AppStateView.error(
              title: 'Topic unavailable',
              message: _loadError!,
              onRetry: _load,
            )
          : topic == null
          ? AppStateView.empty(
              icon: Icons.topic_outlined,
              title: 'Topic not found',
              message: 'This topic may have been removed or renamed.',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  120,
                ),
                children: [
                  _buildHeader(topic),
                  const SizedBox(height: AppSpacing.md),
                  _buildActionsGrid(),
                  const SizedBox(height: AppSpacing.md),
                  _buildNotesSection(topic),
                  const SizedBox(height: AppSpacing.md),
                  _buildVoiceNotesSection(),
                  const SizedBox(height: AppSpacing.md),
                  _buildUploadsSection(),
                  const SizedBox(height: AppSpacing.md),
                  _buildRatingSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildVoiceNotesSection() {
    final voiceNotes = _uploadedNotes
        .where((note) {
          final type = note.fileType.toLowerCase();
          return type != 'pdf' && type != 'pptx';
        })
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Voice Notes', style: AppTextStyles.headingSmall),
              const Spacer(),
              const Icon(Icons.mic_rounded, color: AppColors.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          VoiceNoteRecorderWidget(
            topicId: widget.topicId,
            onSaved: (_) async {
              await _load();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          if (voiceNotes.isEmpty)
            Text(
              'No voice notes yet. Record a quick explanation or revision summary.',
              style: AppTextStyles.bodySmallSecondary,
            )
          else
            ...voiceNotes.map((note) {
              final transcript = _voiceNoteTranscripts[note.id] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VoiceNotePlayerWidget(
                  source: note.fileUrl,
                  title: note.fileName,
                  subtitle: transcript.isEmpty
                      ? 'Tap play to review the note'
                      : transcript,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHeader(TopicModel topic) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      gradient: AppColors.cardGradient,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(topic.name, style: AppTextStyles.headingLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          _module?.name ?? 'Module',
          style: AppTextStyles.bodySmallSecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: topic.ratingColor,
                borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
              ),
              child: Text(
                '${topic.currentRating ?? 0}/10',
                style: AppTextStyles.statValue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.masteryLevel, style: AppTextStyles.label),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Studied ${topic.studyCount} times',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 80,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 10,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _historySpots,
                  isCurved: true,
                  color: AppColors.accent,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accent.withValues(alpha: 0.15),
                  ),
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildActionsGrid() {
    final actions = [
      (
        '🤖',
        'Explain This',
        () => context.push('/topics/${widget.topicId}/ai-tutor'),
      ),
      ('📝', 'Test Me', () => context.push('/topics/${widget.topicId}/quiz')),
      ('🧠', 'Mnemonic', () => _showPlannedFeature('Mnemonic')),
      ('📋', 'Summarize Notes', () => _showPlannedFeature('Summarize Notes')),
      (
        '🔍',
        'Predict Questions',
        () => _showPlannedFeature('Predict Questions'),
      ),
      (
        '💬',
        'Topic Chat',
        () => context.push('/topics/${widget.topicId}/chat'),
      ),
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];
        return GestureDetector(
          onTap: item.$3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(item.$2, style: AppTextStyles.bodySmall)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesSection(TopicModel topic) => Container(
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        ListTile(
          title: Text('My Notes', style: AppTextStyles.label),
          trailing: Icon(
            _notesExpanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            color: Colors.white,
          ),
          onTap: () {
            setState(() {
              _notesExpanded = !_notesExpanded;
            });
          },
        ),
        if (_notesExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _notesController,
                  minLines: 5,
                  maxLines: 8,
                  style: AppTextStyles.bodySmall,
                  decoration: InputDecoration(
                    hintText: 'Add your personal notes...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.fieldRadius,
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  onEditingComplete: _saveNotes,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '${_notesController.text.length} chars',
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saveNotes,
                      child: _isSavingNotes
                          ? const Icon(Icons.hourglass_top_rounded, size: 14)
                          : Text(
                              'Save',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _buildUploadsSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Lecture Notes', style: AppTextStyles.headingSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: _uploadNote,
              icon: const Icon(
                Icons.upload_file_rounded,
                color: AppColors.accent,
              ),
              label: Text(
                'Upload',
                style: AppTextStyles.label.copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_uploadedNotes.isEmpty)
          Text(
            'No uploaded notes yet.',
            style: AppTextStyles.bodySmallSecondary,
          )
        else
          ..._uploadedNotes.map((note) {
            final typeColor = note.fileType == 'pdf'
                ? AppColors.danger
                : AppColors.accent;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteUploadedNote(note.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.pillRadius,
                          ),
                        ),
                        child: Text(
                          note.fileType.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(note.processingStatus, style: AppTextStyles.caption),
                      const Spacer(),
                      Row(
                        children: [
                          Text('Share', style: AppTextStyles.caption),
                          Switch(
                            value: note.isSharedWithGroup,
                            onChanged: (value) => _toggleShare(note, value),
                            activeThumbColor: AppColors.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );

  Widget _buildRatingSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How well do you understand this?',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: List.generate(10, (index) {
            final value = index + 1;
            final selected = value == _selectedRating;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRating = value;
                });
              },
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('$value', style: AppTextStyles.label),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: _saveRating,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            alignment: Alignment.center,
            child: Text('Save Rating', style: AppTextStyles.button),
          ),
        ),
      ],
    ),
  );
}
