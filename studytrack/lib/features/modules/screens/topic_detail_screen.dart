import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/module_model.dart';
import '../../../models/topic_model.dart';
import '../../../models/uploaded_note_model.dart';
import '../../voice_notes/widgets/voice_note_player_widget.dart';
import '../../voice_notes/widgets/voice_note_recorder_widget.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({required this.topicId, super.key});

  final String topicId;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  final SupabaseService _service = SupabaseService();
  final StorageService _storageService = StorageService();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingNotes = false;
  bool _isUploadingNote = false;
  bool _notesExpanded = true;
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
    });

    final topic = await _service.getTopicById(widget.topicId);
    final module = topic == null
        ? null
        : await _service.getModuleById(topic.moduleId);

    final history =
        await _service.getTopicRatingHistory(widget.topicId, limit: 5) ??
        <Map<String, dynamic>>[];
    final notes = await _service.getNotesByTopic(widget.topicId) ?? [];
    final voiceNotes = notes
        .where((note) {
          final type = (note['file_type'] as String?)?.toLowerCase() ?? '';
          return type != 'pdf' && type != 'pptx';
        })
        .toList(growable: false);

    final transcripts = <String, String>{};
    for (final note in voiceNotes) {
      final noteId = note['id']?.toString() ?? '';
      if (noteId.isEmpty) continue;
      final chunks = await _service.getNoteChunks(noteId) ?? [];
      transcripts[noteId] = chunks
          .map((chunk) => chunk['content']?.toString() ?? '')
          .where((chunk) => chunk.trim().isNotEmpty)
          .join(' ')
          .trim();
    }

    if (!mounted) return;
    setState(() {
      _topic = topic;
      _module = module;
      _ratingHistory = history;
      _uploadedNotes = notes.map(UploadedNoteModel.fromJson).toList();
      _voiceNoteTranscripts
        ..clear()
        ..addAll(transcripts);
      _selectedRating = topic?.currentRating ?? 0;
      _notesController.text = topic?.notes ?? '';
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

    await _service.updateTopicNotes(_topic!.id, _notesController.text);

    if (!mounted) return;
    setState(() {
      _isSavingNotes = false;
    });
  }

  Future<void> _uploadNote() async {
    final topic = _topic;
    final user = _service.getCurrentUser();
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
    await _service.updateUploadedNoteSharing(note.id, value);
    await _load();
  }

  Future<void> _deleteUploadedNote(String noteId) async {
    await _service.deleteUploadedNote(noteId);
    await _load();
  }

  Future<void> _saveRating() async {
    if (_selectedRating < 1 || _topic == null) {
      return;
    }

    await _service.updateTopicRating(_topic!.id, _selectedRating);
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
          ? const Center(child: CircularProgressIndicator())
          : topic == null
          ? Center(
              child: Text(
                'Topic not found.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                children: [
                  _buildHeader(topic),
                  const SizedBox(height: 14),
                  _buildActionsGrid(),
                  const SizedBox(height: 14),
                  _buildNotesSection(topic),
                  const SizedBox(height: 14),
                  _buildVoiceNotesSection(),
                  const SizedBox(height: 14),
                  _buildUploadsSection(),
                  const SizedBox(height: 14),
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
              Text(
                'Voice Notes',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.mic_rounded, color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 12),
          VoiceNoteRecorderWidget(
            topicId: widget.topicId,
            onSaved: (_) async {
              await _load();
            },
          ),
          const SizedBox(height: 12),
          if (voiceNotes.isEmpty)
            Text(
              'No voice notes yet. Record a quick explanation or revision summary.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topic.name,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _module?.name ?? 'Module',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: topic.ratingColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${topic.currentRating ?? 0}/10',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.masteryLevel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Studied ${topic.studyCount} times',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.$2,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
            title: Text(
              'My Notes',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  TextField(
                    controller: _notesController,
                    minLines: 5,
                    maxLines: 8,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add your personal notes...',
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                    onEditingComplete: _saveNotes,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${_notesController.text.length} chars',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _saveNotes,
                        child: _isSavingNotes
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save',
                                style: GoogleFonts.inter(
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
              Text(
                'Lecture Notes',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _uploadNote,
                icon: const Icon(
                  Icons.upload_file_rounded,
                  color: AppColors.accent,
                ),
                label: Text(
                  'Upload',
                  style: GoogleFonts.inter(color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_uploadedNotes.isEmpty)
            Text(
              'No uploaded notes yet.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            )
          else
            ..._uploadedNotes.map((note) {
              final typeColor = note.fileType == 'pdf'
                  ? AppColors.danger
                  : AppColors.accent;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
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
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            note.fileType.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: typeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          note.processingStatus,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Share',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How well do you understand this?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                  child: Text(
                    '$value',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _saveRating,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                'Save Rating',
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
