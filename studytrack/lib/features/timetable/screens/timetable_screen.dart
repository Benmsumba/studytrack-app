import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../models/class_slot_model.dart';
import '../../../models/study_session_model.dart';
import '../controllers/timetable_provider.dart';
import '../controllers/topic_module_provider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final AuthRepository _authRepository = getIt<AuthRepository>();

  final List<String> _dayLabels = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  late int _selectedDay;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCurrentUserIdAndData();
    });
  }

  Future<void> _loadCurrentUserIdAndData() async {
    final result = await _authRepository.getCurrentUser();
    final userId = switch (result) {
      Success(data: final user) => user?.id,
      Failure(error: final _) => null,
    };

    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
    });

    await _loadData();
  }

  Future<void> _loadData() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final provider = context.read<TimetableProvider>();
    provider.setSelectedDate(_dateForSelectedDay());
    final result = await provider.loadTimetable(userId);
    if (!mounted || result.success) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  DateTime _dateForSelectedDay() {
    final now = DateTime.now();
    final offset = _selectedDay - now.weekday;
    return DateTime(now.year, now.month, now.day).add(Duration(days: offset));
  }

  List<ClassSlotModel> _classesForDay(TimetableProvider provider) => provider
      .classSlots
      .where((item) => item.dayOfWeek == _selectedDay)
      .toList();

  String _displayTitleForSelectedDay() {
    final today = DateTime.now().weekday;
    if (_selectedDay == today) {
      return "Today's Schedule";
    }
    return '${_dayLabels[_selectedDay - 1]} Schedule';
  }

  Color _safeColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return AppColors.accent;
    }

    final sanitized = colorHex.replaceAll('#', '');
    if (sanitized.length != 6) {
      return AppColors.accent;
    }

    return Color(int.parse('FF$sanitized', radix: 16));
  }

  Future<void> _deleteClassSlot(String id) async {
    final result = await context.read<TimetableProvider>().deleteClassSlot(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _showAddScheduleBottomSheet() async {
    final submission = await showModalBottomSheet<_ScheduleSubmission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddScheduleBottomSheet(selectedDay: _selectedDay),
    );

    await _handleScheduleSubmission(submission);
  }

  Future<void> _showEditClassBottomSheet(ClassSlotModel slot) async {
    final submission = await showModalBottomSheet<_ScheduleSubmission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddScheduleBottomSheet(
        selectedDay: _selectedDay,
        editClassData: slot.toJson(),
      ),
    );

    await _handleScheduleSubmission(submission);
  }

  Future<void> _handleScheduleSubmission(
    _ScheduleSubmission? submission,
  ) async {
    if (submission == null) {
      return;
    }

    final provider = context.read<TimetableProvider>();

    final TimetableActionResult result;
    if (submission.isClass && submission.editClassId != null) {
      result = await provider.updateClassSlot(
        classSlotId: submission.editClassId!,
        classData: submission.payload,
      );
    } else {
      result = submission.isClass
          ? await provider.addClassSlot(submission.payload)
          : await provider.addStudySession(submission.payload);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: Consumer<TimetableProvider>(
      builder: (context, provider, _) {
        final classesForDay = _classesForDay(provider);
        final studySessions = provider.studySessions;

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceDark,
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Text(
                _displayTitleForSelectedDay(),
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dayLabels.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final selected = day == _selectedDay;
                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _selectedDay = day;
                        });
                        await _loadData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: selected ? AppColors.primaryGradient : null,
                          color: selected ? null : AppColors.cardDark,
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _dayLabels[index],
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionHeader('🎓 Classes', classesForDay.length),
              const SizedBox(height: 10),
              Card(
                color: AppColors.cardDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    'Class Timetable',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  iconColor: AppColors.textPrimary,
                  collapsedIconColor: AppColors.textSecondary,
                  children: classesForDay.isEmpty
                      ? [_buildEmptyTile('No classes scheduled for this day.')]
                      : classesForDay.map(_buildClassCard).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('📖 Study Sessions', studySessions.length),
              const SizedBox(height: 10),
              Card(
                color: AppColors.cardDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    'Planned Sessions',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  iconColor: AppColors.textPrimary,
                  collapsedIconColor: AppColors.textSecondary,
                  children: studySessions.isEmpty
                      ? [
                          _buildEmptyTile(
                            'Nothing scheduled. Add a class or study session.',
                          ),
                        ]
                      : studySessions.map(_buildStudySessionCard).toList(),
                ),
              ),
            ],
          ),
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddScheduleBottomSheet,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );

  Widget _buildSectionHeader(String title, int count) => Row(
    children: [
      Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '$count',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _buildEmptyTile(String message) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Text(
        message,
        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
      ),
    ),
  );

  Widget _buildClassCard(ClassSlotModel slot) {
    final color = _safeColor(slot.color);
    return Slidable(
      key: ValueKey(slot.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showEditClassBottomSheet(slot),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _deleteClassSlot(slot.id),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 84,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.subjectName,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slot.room ?? 'Room TBA'} • ${slot.lecturer ?? 'Lecturer TBA'}',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudySessionCard(StudySessionModel session) {
    final status = session.status.toLowerCase();
    final badgeColor = switch (status) {
      'completed' => AppColors.success,
      'missed' => AppColors.danger,
      _ => AppColors.warning,
    };

    return GestureDetector(
      onTap: () {
        final topicId = session.topicId;
        if (topicId != null && topicId.isNotEmpty) {
          context.push('/topics/$topicId');
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.startTime ?? '--:--'} - ${session.endTime ?? '--:--'}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeColor),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSubmission {
  const _ScheduleSubmission({
    required this.isClass,
    required this.payload,
    this.editClassId,
  });

  final bool isClass;
  final Map<String, dynamic> payload;
  final String? editClassId;
}

class _AddScheduleBottomSheet extends StatefulWidget {
  const _AddScheduleBottomSheet({
    required this.selectedDay,
    this.editClassData,
  });

  final int selectedDay;
  final Map<String, dynamic>? editClassData;

  @override
  State<_AddScheduleBottomSheet> createState() =>
      _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<_AddScheduleBottomSheet>
    with SingleTickerProviderStateMixin {
  final AuthRepository _authRepository = getIt<AuthRepository>();
  late final TabController _tabController;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _lecturerController = TextEditingController();

  final TextEditingController _sessionTitleController = TextEditingController();

  TimeOfDay? _classStart;
  TimeOfDay? _classEnd;
  TimeOfDay? _sessionStart;
  TimeOfDay? _sessionEnd;
  DateTime _sessionDate = DateTime.now();
  int _classDay = DateTime.now().weekday;

  String? _selectedTopicId;
  String? _selectedModuleId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _classDay = widget.selectedDay;

    final edit = widget.editClassData;
    if (edit != null) {
      _tabController.index = 0;
      _subjectController.text = edit['subject_name']?.toString() ?? '';
      _roomController.text = edit['room']?.toString() ?? '';
      _lecturerController.text = edit['lecturer']?.toString() ?? '';
      _classDay = (edit['day_of_week'] as int?) ?? widget.selectedDay;
      _classStart = _parseTimeString(edit['start_time']?.toString());
      _classEnd = _parseTimeString(edit['end_time']?.toString());
    }

    // Load topics and modules via provider
    final provider = context.read<TopicModuleProvider>();
    unawaited(provider.loadModulesAndTopics());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _roomController.dispose();
    _lecturerController.dispose();
    _sessionTitleController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTimeString(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _to24h(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _pickTime({required bool isClass, required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selected == null || !mounted) return;
    setState(() {
      if (isClass && isStart) _classStart = selected;
      if (isClass && !isStart) _classEnd = selected;
      if (!isClass && isStart) _sessionStart = selected;
      if (!isClass && !isStart) _sessionEnd = selected;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _sessionDate = picked;
    });
  }

  Future<void> _saveClass() async {
    if (_subjectController.text.trim().isEmpty ||
        _classStart == null ||
        _classEnd == null) {
      _showSnack('Please enter subject and class times.');
      return;
    }

    final result = await _authRepository.getCurrentUser();
    final userId = switch (result) {
      Success(data: final user) => user?.id,
      Failure(error: final _) => null,
    };

    if (userId == null || userId.isEmpty) {
      _showSnack('Please sign in again.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = {
      'user_id': userId,
      'subject_name': _subjectController.text.trim(),
      'day_of_week': _classDay,
      'start_time': _to24h(_classStart!),
      'end_time': _to24h(_classEnd!),
      'room': _roomController.text.trim().isEmpty
          ? null
          : _roomController.text.trim(),
      'lecturer': _lecturerController.text.trim().isEmpty
          ? null
          : _lecturerController.text.trim(),
      'color': '#06B6D4',
    };

    final editId = widget.editClassData?['id']?.toString();
    if (!mounted) return;
    Navigator.of(context).pop(
      _ScheduleSubmission(isClass: true, payload: payload, editClassId: editId),
    );
  }

  Future<void> _saveStudySession() async {
    if (_sessionTitleController.text.trim().isEmpty ||
        _sessionStart == null ||
        _sessionEnd == null) {
      _showSnack('Please enter session title and session time.');
      return;
    }

    final result = await _authRepository.getCurrentUser();
    final userId = switch (result) {
      Success(data: final user) => user?.id,
      Failure(error: final _) => null,
    };

    if (userId == null || userId.isEmpty) {
      _showSnack('Please sign in again.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final startMinutes = _sessionStart!.hour * 60 + _sessionStart!.minute;
    final endMinutes = _sessionEnd!.hour * 60 + _sessionEnd!.minute;
    final duration = (endMinutes - startMinutes).clamp(0, 600);

    final payload = {
      'user_id': userId,
      'topic_id': _selectedTopicId,
      'module_id': _selectedModuleId,
      'title': _sessionTitleController.text.trim(),
      'scheduled_date': _sessionDate.toIso8601String().split('T').first,
      'start_time': _to24h(_sessionStart!),
      'end_time': _to24h(_sessionEnd!),
      'duration_minutes': duration,
      'status': 'planned',
    };

    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(_ScheduleSubmission(isClass: false, payload: payload));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Add Class'),
              Tab(text: 'Add Study Session'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [_buildAddClassTab(), _buildAddStudyTab()],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_tabController.index == 0) {
                        _saveClass();
                      } else {
                        _saveStudySession();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.editClassData == null ? 'Save' : 'Update Class',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddClassTab() => ListView(
    children: [
      _buildInput(_subjectController, 'Subject name'),
      const SizedBox(height: 10),
      _buildDayDropdown(),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _buildTimePicker(
              label: 'Start time',
              value: _classStart,
              onTap: () => _pickTime(isClass: true, isStart: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTimePicker(
              label: 'End time',
              value: _classEnd,
              onTap: () => _pickTime(isClass: true, isStart: false),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _buildInput(_roomController, 'Room (optional)'),
      const SizedBox(height: 10),
      _buildInput(_lecturerController, 'Lecturer (optional)'),
    ],
  );

  Widget _buildAddStudyTab() => ListView(
    children: [
      _buildInput(_sessionTitleController, 'Session title'),
      const SizedBox(height: 10),
      _buildDatePicker(),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _buildTimePicker(
              label: 'Start time',
              value: _sessionStart,
              onTap: () => _pickTime(isClass: false, isStart: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTimePicker(
              label: 'End time',
              value: _sessionEnd,
              onTap: () => _pickTime(isClass: false, isStart: false),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _buildTopicDropdown(),
    ],
  );

  Widget _buildInput(TextEditingController controller, String hint) =>
      TextField(
        controller: controller,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      );

  Widget _buildDayDropdown() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return DropdownButtonFormField<int>(
      initialValue: _classDay,
      dropdownColor: AppColors.surfaceDark,
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Day',
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: List.generate(
        7,
        (index) =>
            DropdownMenuItem(value: index + 1, child: Text(labels[index])),
      ),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _classDay = value;
        });
      },
    );
  }

  Widget _buildDatePicker() => InkWell(
    onTap: _pickDate,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '${_sessionDate.year}-${_sessionDate.month.toString().padLeft(2, '0')}-${_sessionDate.day.toString().padLeft(2, '0')}',
            style: GoogleFonts.inter(color: AppColors.textPrimary),
          ),
        ],
      ),
    ),
  );

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value == null ? label : value.format(context),
              style: GoogleFonts.inter(
                color: value == null
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTopicDropdown() => Consumer<TopicModuleProvider>(
    builder: (context, provider, _) => DropdownButtonFormField<String>(
      initialValue: _selectedTopicId,
      dropdownColor: AppColors.surfaceDark,
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Linked topic (optional)',
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: provider.topics
          .map(
            (topic) => DropdownMenuItem<String>(
              value: topic.id,
              child: Text(topic.name),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedTopicId = value;
          _selectedModuleId = provider.topics
              .where((topic) => topic.id == value)
              .map((topic) => topic.moduleId)
              .firstOrNull;
        });
      },
    ),
  );
}
