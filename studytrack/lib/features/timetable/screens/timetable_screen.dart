import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../models/class_slot_model.dart';
import '../../../models/study_session_model.dart';
import '../controllers/timetable_provider.dart';
import '../controllers/topic_module_provider.dart';

const int _startHour = 8;
const int _endHour = 17;
const double _hourHeight = 64.0;
const double _timeAxisWidth = 48.0;

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
    if (userId == null || userId.isEmpty) return;

    final provider = context.read<TimetableProvider>();
    final selectedDate = _dateForSelectedDay();
    provider.setSelectedDate(selectedDate);
    final result = await provider.loadTimetable();
    if (!mounted || result.success) return;
    SnackbarHelper.show(context, result.message, type: AppSnackbarType.error);
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

  Color _safeColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return AppColors.signal;
    final sanitized = colorHex.replaceAll('#', '');
    if (sanitized.length != 6) return AppColors.signal;
    return Color(int.parse('FF$sanitized', radix: 16));
  }

  Future<void> _deleteClassSlot(String id) async {
    final result = await context.read<TimetableProvider>().deleteClassSlot(id);
    if (!mounted) return;
    SnackbarHelper.show(
      context,
      result.message,
      type: result.success ? AppSnackbarType.success : AppSnackbarType.error,
    );
  }

  Future<void> _showAddScheduleBottomSheet() async {
    final submission = await showModalBottomSheet<_ScheduleSubmission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
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
      backgroundColor: const Color(0xFF1A1A2E),
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
    if (submission == null) return;

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
    SnackbarHelper.show(
      context,
      result.message,
      type: result.success ? AppSnackbarType.success : AppSnackbarType.error,
    );
  }

  Widget _buildDayTabs() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: List.generate(7, (i) {
          final dayIndex = i + 1;
          final selected = _selectedDay == dayIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                Haptics.selection();
                setState(() => _selectedDay = dayIndex);
                _loadData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: selected
                    ? BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Text(
                  days[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _slotColor(ClassSlotModel slot) {
    if (slot.color != null && slot.color!.isNotEmpty) {
      try {
        final hex = slot.color!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    final name = slot.subjectName.toLowerCase();
    if (name.contains('study') || name.contains('session')) {
      return const Color(0xFF10B981);
    }
    if (name.contains('cs') || name.contains('prep') || name.contains('lab')) {
      return const Color(0xFF7C3AED);
    }
    return const Color(0xFF3B82F6);
  }

  Widget _buildEventBlock(ClassSlotModel slot) {
    final startParts = slot.startTime.split(':');
    final endParts = slot.endTime.split(':');
    final startHour =
        int.parse(startParts[0]) +
        int.parse(startParts.length > 1 ? startParts[1] : '0') / 60.0;
    final endHour =
        int.parse(endParts[0]) +
        int.parse(endParts.length > 1 ? endParts[1] : '0') / 60.0;
    final top = (startHour - _startHour) * _hourHeight;
    final height = (endHour - startHour) * _hourHeight;
    if (top < 0 || height <= 0) return const SizedBox.shrink();

    final blockColor = _slotColor(slot);
    final displayStart =
        '${startParts[0]}:${startParts.length > 1 ? startParts[1] : '00'}';
    final displayEnd =
        '${endParts[0]}:${endParts.length > 1 ? endParts[1] : '00'}';

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height - 4,
      child: GestureDetector(
        onTap: () => _showEditClassBottomSheet(slot),
        onLongPress: () => _confirmDeleteSlot(slot),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: blockColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: blockColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.subjectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (height > 60) ...[
                const SizedBox(height: 2),
                Text(
                  '($displayStart-$displayEnd)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
                if (slot.room != null)
                  Text(
                    '- ${slot.room}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSlot(ClassSlotModel slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Class',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${slot.subjectName}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteClassSlot(slot.id);
    }
  }

  Widget _buildTimeGrid() {
    return Consumer<TimetableProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
          );
        }

        final slots = provider.classSlots
            .where((s) => s.dayOfWeek == _selectedDay)
            .toList();
        final totalHeight = (_endHour - _startHour) * _hourHeight;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: totalHeight + 32,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time axis
                SizedBox(
                  width: _timeAxisWidth,
                  height: totalHeight,
                  child: Column(
                    children: List.generate(_endHour - _startHour, (i) {
                      final hour = _startHour + i;
                      return SizedBox(
                        height: _hourHeight,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Events column
                Expanded(
                  child: Stack(
                    children: [
                      // Grid lines
                      Column(
                        children: List.generate(
                          _endHour - _startHour,
                          (i) => Container(
                            height: _hourHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Event blocks
                      if (slots.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: Text(
                              'No classes scheduled for ${_dayLabels[_selectedDay - 1]}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ...slots.map((slot) => _buildEventBlock(slot)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: const [
                      Text(
                        'StudyTrack',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Weekly Timetable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Day tab row
                _buildDayTabs(),
                const SizedBox(height: 8),
                // Time grid
                Expanded(child: _buildTimeGrid()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Haptics.light();
          _showAddScheduleBottomSheet();
        },
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
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
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
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

    setState(() => _isSaving = true);

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
      'color': '#977E41',
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

    setState(() => _isSaving = true);

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
    SnackbarHelper.show(context, message, type: AppSnackbarType.warning);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.borderDark;
    final mutedFg = AppColors.parchmentMuted;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomInset + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.signal,
            labelColor: AppColors.signal,
            unselectedLabelColor: mutedFg,
            tabs: const [
              Tab(text: 'Add Class'),
              Tab(text: 'Add Study Session'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [_buildAddClassTab(), _buildAddStudyTab()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      Haptics.light();
                      if (_tabController.index == 0) {
                        _saveClass();
                      } else {
                        _saveStudySession();
                      }
                    },
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
                      widget.editClassData == null ? 'SAVE' : 'UPDATE CLASS',
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
      const SizedBox(height: AppSpacing.xs),
      _buildDayDropdown(),
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: [
          Expanded(
            child: _buildTimePicker(
              label: 'Start time',
              value: _classStart,
              onTap: () => _pickTime(isClass: true, isStart: true),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _buildTimePicker(
              label: 'End time',
              value: _classEnd,
              onTap: () => _pickTime(isClass: true, isStart: false),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      _buildInput(_roomController, 'Room (optional)'),
      const SizedBox(height: AppSpacing.xs),
      _buildInput(_lecturerController, 'Lecturer (optional)'),
    ],
  );

  Widget _buildAddStudyTab() => ListView(
    children: [
      _buildInput(_sessionTitleController, 'Session title'),
      const SizedBox(height: AppSpacing.xs),
      _buildDatePicker(),
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: [
          Expanded(
            child: _buildTimePicker(
              label: 'Start time',
              value: _sessionStart,
              onTap: () => _pickTime(isClass: false, isStart: true),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _buildTimePicker(
              label: 'End time',
              value: _sessionEnd,
              onTap: () => _pickTime(isClass: false, isStart: false),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      _buildTopicDropdown(),
    ],
  );

  Widget _buildInput(TextEditingController controller, String hint) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hint),
      );

  Widget _buildDayDropdown() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return DropdownButtonFormField<int>(
      initialValue: _classDay,
      dropdownColor: AppColors.surfaceDark,
      decoration: const InputDecoration(labelText: 'Day'),
      items: List.generate(
        7,
        (index) =>
            DropdownMenuItem(value: index + 1, child: Text(labels[index])),
      ),
      onChanged: (value) {
        if (value == null) return;
        Haptics.selection();
        setState(() => _classDay = value);
      },
    );
  }

  Widget _buildDatePicker() {
    final borderColor = AppColors.borderDark;
    final surfaceBg = AppColors.cardDark;
    final mutedFg = AppColors.parchmentMuted;

    return InkWell(
      onTap: () {
        Haptics.selection();
        _pickDate();
      },
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: mutedFg, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${_sessionDate.year}-'
              '${_sessionDate.month.toString().padLeft(2, '0')}-'
              '${_sessionDate.day.toString().padLeft(2, '0')}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    final borderColor = AppColors.borderDark;
    final surfaceBg = AppColors.cardDark;
    final mutedFg = AppColors.parchmentMuted;
    final activeFg = AppColors.parchment;

    return InkWell(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, color: mutedFg, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                value == null ? label : value.format(context),
                style: AppTextStyles.bodySmall.copyWith(
                  color: value == null ? mutedFg : activeFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicDropdown() => Consumer<TopicModuleProvider>(
    builder: (context, provider, _) {
      return DropdownButtonFormField<String>(
        initialValue: _selectedTopicId,
        dropdownColor: AppColors.surfaceDark,
        decoration: const InputDecoration(labelText: 'Linked topic (optional)'),
        items: provider.topics
            .map(
              (topic) => DropdownMenuItem<String>(
                value: topic.id,
                child: Text(topic.name),
              ),
            )
            .toList(),
        onChanged: (value) {
          Haptics.selection();
          setState(() {
            _selectedTopicId = value;
            _selectedModuleId = provider.topics
                .where((topic) => topic.id == value)
                .map((topic) => topic.moduleId)
                .firstOrNull;
          });
        },
      );
    },
  );
}
