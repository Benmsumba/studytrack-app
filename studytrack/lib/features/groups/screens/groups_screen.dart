import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/repositories/study_group_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/service_locator.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/study_group_model.dart';
import '../../auth/controllers/auth_provider.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final StudyGroupRepository _groupRepo = getIt<StudyGroupRepository>();
  bool _loading = true;
  bool _working = false;
  String? _loadError;
  List<StudyGroupModel> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = null;
      });
      return;
    }

    setState(() => _loading = true);
    final result = await _groupRepo.getAllGroups();
    final groups = result is Success<List<StudyGroupModel>>
        ? result.data
        : <StudyGroupModel>[];
    if (!mounted) return;
    setState(() {
      _groups = groups;
      _loadError = result is Failure<List<StudyGroupModel>>
          ? AppStrings.groupsLoadError
          : null;
      _loading = false;
    });
  }

  Future<void> _showCreateGroupSheet() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.createGroup, style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: nameController,
              style: AppTextStyles.bodySmall,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: descriptionController,
              style: AppTextStyles.bodySmall,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.groupDescriptionOptional,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlowingButton(
              label: 'Create',
              isLoading: _working,
              width: double.infinity,
              onPressed: _working
                  ? null
                  : () async {
                      HapticFeedback.lightImpact();
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final user = auth.currentUser;
                      final name = nameController.text.trim();
                      final description = descriptionController.text.trim();
                      if (user == null || name.isEmpty) return;

                      setState(() => _working = true);

                      final navigator = Navigator.of(context);

                      final createdResult = await _groupRepo.createGroup(
                        name: name,
                        description: description.isEmpty ? '' : description,
                      );

                      if (!mounted) return;
                      setState(() => _working = false);
                      navigator.pop();

                      if (createdResult is! Success<StudyGroupModel>) {
                        SnackbarHelper.show(
                          context,
                          AppStrings.failedCreateGroup,
                          type: AppSnackbarType.error,
                        );
                        return;
                      }

                      final invite = createdResult.data.inviteCode;
                      if (!mounted) return;
                      showDialog<void>(
                        context: navigator.context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: AppColors.cardDark,
                          title: Text(
                            AppStrings.groupCreated,
                            style: AppTextStyles.headingSmall,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.shareInviteCode,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SelectableText(
                                invite,
                                style: AppTextStyles.statValue.copyWith(
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: invite),
                                );
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();
                                if (!mounted) return;
                                SnackbarHelper.show(
                                  context,
                                  AppStrings.inviteCopied,
                                  type: AppSnackbarType.success,
                                );
                              },
                              child: const Text('Copy'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      );

                      await _loadGroups();
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showJoinGroupSheet() async {
    final codeController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join Group', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: codeController,
              style: AppTextStyles.bodySmall,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Enter invite code'),
            ),
            const SizedBox(height: AppSpacing.md),
            GlowingButton(
              label: 'Join Group',
              isLoading: _working,
              width: double.infinity,
              onPressed: _working
                  ? null
                  : () async {
                      HapticFeedback.lightImpact();
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final user = auth.currentUser;
                      final code = codeController.text.trim();
                      if (user == null || code.isEmpty) return;

                      setState(() => _working = true);

                      final navigator = Navigator.of(context);

                      final joinedResult = await _groupRepo.joinGroupByCode(
                        code,
                      );

                      if (!mounted) return;
                      setState(() => _working = false);
                      navigator.pop();

                      if (joinedResult is! Success<void>) {
                        SnackbarHelper.show(
                          context,
                          AppStrings.inviteNotFound,
                          type: AppSnackbarType.error,
                        );
                        return;
                      }

                      await _loadGroups();
                      if (!mounted) return;
                      SnackbarHelper.show(
                        context,
                        AppStrings.joinedGroupSuccess,
                        type: AppSnackbarType.success,
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _formatLastActivity(String? isoValue) {
    if (isoValue == null || isoValue.isEmpty) {
      return 'No activity yet';
    }

    final parsed = DateTime.tryParse(isoValue);
    if (parsed == null) {
      return 'Recently active';
    }

    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'Active just now';
    if (diff.inHours < 1) return 'Active ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Active ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    return 'Active on ${parsed.toLocal().toIso8601String().split('T').first}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDark,
    body: _loading
        ? AppStateView.loadingList(itemCount: 4, itemHeight: 110)
        : RefreshIndicator(
            onRefresh: _loadGroups,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl +
                    AppSpacing.xxl +
                    AppSpacing.md +
                    AppSpacing.xs,
              ),
              children: [
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: AppStateView.error(
                      title: AppStrings.groupsUnavailable,
                      message: _loadError!,
                      onRetry: _loadGroups,
                    ),
                  )
                else if (_groups.isEmpty) ...[
                  AppStateView.empty(
                    icon: Icons.groups_2_outlined,
                    title: AppStrings.noGroupsTitle,
                    message: AppStrings.noGroupsSubtitle,
                    actionLabel: 'Create or Join a Group',
                    onAction: () async {
                      HapticFeedback.lightImpact();
                      await showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: AppColors.surfaceDark,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.cardRadius),
                          ),
                        ),
                        builder: (context) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.group_add,
                                    color: AppColors.accent,
                                  ),
                                  title: const Text('Create Group'),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    await _showCreateGroupSheet();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.login,
                                    color: AppColors.accent,
                                  ),
                                  title: const Text('Join Group'),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    await _showJoinGroupSheet();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  Text('My Study Groups', style: AppTextStyles.headingSmall),
                  const SizedBox(height: AppSpacing.sm),
                  ..._groups.map((group) {
                    final g = group;
                    final name = g.name;
                    final description = g.description ?? 'No description yet';
                    final groupId = g.id;
                    const memberCount = 1; // placeholder
                    const String? lastActivity = null;

                    return GestureDetector(
                      onTap: groupId.isEmpty
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              context.push('/group/$groupId', extra: g);
                            },
                      child: GlassCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        backgroundColor: AppColors.cardDark,
                        borderRadius: AppSpacing.fieldRadius,
                        borderColors: const [
                          AppColors.border,
                          AppColors.border,
                        ],
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                _initials(name),
                                style: AppTextStyles.label,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: AppTextStyles.headingSmall),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '$memberCount member${memberCount == 1 ? '' : 's'}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    _formatLastActivity(lastActivity),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        HapticFeedback.lightImpact();
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surfaceDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.group_add,
                      color: AppColors.accent,
                    ),
                    title: Text(
                      'Create Group',
                      style: AppTextStyles.bodyMedium,
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _showCreateGroupSheet();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.login, color: AppColors.accent),
                    title: Text('Join Group', style: AppTextStyles.bodyMedium),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _showJoinGroupSheet();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Group'),
    ),
  );
}
