import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
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

  String _displayTitleForSelectedDay() {
    final today = DateTime.now().weekday;
    if (_selectedDay == today) return "Today's Schedule";
    return '${_dayLabels[_selectedDay - 1]} Schedule';
  }

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
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final submission = await showModalBottomSheet<_ScheduleSubmission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isLight ? AppColors.paperWhite : AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddScheduleBottomSheet(selectedDay: _selectedDay),
    );

    await _handleScheduleSubmission(submission);
  }

  Future<void> _showEditClassBottomSheet(ClassSlotModel slot) async {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final submission = await showModalBottomSheet<_ScheduleSubmission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isLight ? AppColors.paperWhite : AppColors.surfaceDark,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final fg = isLight ? AppColors.inkPrimary : AppColors.parchment;
    final mutedFg = isLight ? AppColors.inkMuted : AppColors.parchmentMuted;
    final surfaceBg = isLight ? AppColors.surfaceLight : AppColors.cardDark;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    return Scaffold(
      backgroundColor: isLight ? AppColors.paperWhite : AppColors.obsidian,
      body: Consumer<TimetableProvider>(
        builder: (context, provider, _) {
          final classesForDay = _classesForDay(provider);
          final studySessions = provider.studySessions;

          if (provider.isLoading) {
            return AppStateView.loadingList(itemCount: 4, itemHeight: 110);
          }

          return RefreshIndicator(
            color: AppColors.signal,
            backgroundColor: surfaceBg,
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xs,
                AppSpacing.screenHorizontal,
                120,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayTitleForSelectedDay(),
                        style: isLight
                            ? AppTextStyles.headingSmallLight
                            : AppTextStyles.headingSmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Haptics.light();
                        _showAddScheduleBottomSheet();
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('ADD'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dayLabels.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final selected = day == _selectedDay;
                      return GestureDetector(
                        onTap: () {
                          Haptics.selection();
                          setState(() => _selectedDay = day);
                          _loadData();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.cardRadius,
                            ),
                            color: selected ? AppColors.signalMuted : surfaceBg,
                            border: Border.all(
                              color:
                                  selected ? AppColors.signal : borderColor,
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _dayLabels[index].toUpperCase(),
                            style: AppTextStyles.overline.copyWith(
                              color: selected ? AppColors.signal : mutedFg,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSectionHeader(
                  'Classes',
                  classesForDay.length,
                  fg,
                  mutedFg,
                  surfaceBg,
                  borderColor,
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildExpansionCard(
                  title: 'Class Timetable',
                  fg: fg,
                  mutedFg: mutedFg,
                  surfaceBg: surfaceBg,
                  borderColor: borderColor,
                  children: classesForDay.isEmpty
                      ? [
                          _buildEmptyTile(
                            'No classes scheduled for this day.',
                            mutedFg,
                            surfaceBg,
                            borderColor,
                          ),
                        ]
                      : classesForDay.map(_buildClassCard).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSectionHeader(
                  'Study Sessions',
                  studySessions.length,
                  fg,
                  mutedFg,
                  surfaceBg,
                  borderColor,
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildExpansionCard(
                  title: 'Planned Sessions',
                  fg: fg,
                  mutedFg: mutedFg,
                  surfaceBg: surfaceBg,
                  borderColor: borderColor,
                  children: studySessions.isEmpty
                      ? [
                          _buildEmptyTile(
                            'Nothing scheduled. Tap ADD to create one.',
                            mutedFg,
                            surfaceBg,
                            borderColor,
                          ),
                        ]
                      : studySessions.map(_buildStudySessionCard).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpansionCard({
    required String title,
    required Color fg,
    required Color mutedFg,
    required Color surfaceBg,
    required Color borderColor,
    required List<Widget> children,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(title, style: AppTextStyles.label.copyWith(color: fg)),
          iconColor: fg,
          collapsedIconColor: mutedFg,
          children: children,
        ),
      );

  Widget _buildSectionHeader(
    String title,
    int count,
    Color fg,
    Color mutedFg,
    Color surfaceBg,
    Color borderColor,
  ) =>
      Row(
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.overline.copyWith(color: fg),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.bodySmall.copyWith(color: mutedFg),
            ),
          ),
        ],
      );

  Widget _buildEmptyTile(
    String message,
    Color mutedFg,
    Color surfaceBg,
    Color borderColor,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: mutedFg),
          ),
        ),
      );

  Widget _buildClassCard(ClassSlotModel slot) {
    final color = _safeColor(slot.color);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surfaceBg = isLight ? AppColors.surfaceLight : AppColors.surfaceDark;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;
    final fg = isLight ? AppColors.inkPrimary : AppColors.parchment;
    final mutedFg = isLight ? AppColors.inkMuted : AppColors.parchmentMuted;

    return Slidable(
      key: ValueKey(slot.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showEditClassBottomSheet(slot),
            backgroundColor: AppColors.signal,
            foregroundColor: AppColors.parchment,
            icon: Icons.edit_rounded,
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
            foregroundColor: AppColors.parchment,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(width: 4, height: 84, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.subjectName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: AppTextStyles.bodySmall.copyWith(color: mutedFg),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${slot.room ?? 'Room TBA'} • '
                      '${slot.lecturer ?? 'Lecturer TBA'}',
                      style: AppTextStyles.caption.copyWith(color: mutedFg),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surfaceBg = isLight ? AppColors.surfaceLight : AppColors.surfaceDark;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;
    final fg = isLight ? AppColors.inkPrimary : AppColors.parchment;
    final mutedFg = isLight ? AppColors.inkMuted : AppColors.parchmentMuted;

    return GestureDetector(
      onTap: () {
        Haptics.selection();
        final topicId = session.topicId;
        if (!mounted) return;
        if (topicId != null && topicId.isNotEmpty) {
          context.push('/topics/$topicId');
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${session.startTime ?? '--:--'} - '
                    '${session.endTime ?? '--:--'}',
                    style: AppTextStyles.bodySmall.copyWith(color: mutedFg),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeColor, width: 0.5),
              ),
              child: Text(
                status.toUpperCase(),
                style: AppTextStyles.overline.copyWith(color: badgeColor),
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
    Navigator.of(context)
        .pop(_ScheduleSubmission(isClass: false, payload: payload));
  }

  void _showSnack(String message) {
    SnackbarHelper.show(context, message, type: AppSnackbarType.warning);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;
    final mutedFg = isLight ? AppColors.inkMuted : AppColors.parchmentMuted;
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
                      widget.editClassData == null
                          ? 'SAVE'
                          : 'UPDATE CLASS',
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return DropdownButtonFormField<int>(
      initialValue: _classDay,
      dropdownColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;
    final surfaceBg = isLight ? AppColors.surfaceLight : AppColors.cardDark;
    final mutedFg = isLight ? AppColors.inkMuted : AppColors.parchmentMuted;

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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;
    final surfaceBg = isLight ? AppColors.surfaceLight : AppColors.cardDark;
    final mutedFg = isLight ? AppColors.inkMuted : AppColors.parchmentMuted;
    final activeFg = isLight ? AppColors.inkPrimary : AppColors.parchment;

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
      final isLight = Theme.of(context).brightness == Brightness.light;
      return DropdownButtonFormField<String>(
        initialValue: _selectedTopicId,
        dropdownColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        decoration:
            const InputDecoration(labelText: 'Linked topic (optional)'),
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
