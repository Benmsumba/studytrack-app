import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final SupabaseService _service = SupabaseService();
  bool _loading = true;
  bool _working = false;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final user = _service.getCurrentUser();
    if (user == null) return;

    setState(() => _loading = true);
    final groups = await _service.getMyGroups(user.id) ?? [];
    if (!mounted) return;
    setState(() {
      _groups = groups;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Group',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _working
                    ? null
                    : () async {
                        final user = _service.getCurrentUser();
                        final name = nameController.text.trim();
                        final description = descriptionController.text.trim();
                        if (user == null || name.isEmpty) return;

                        setState(() => _working = true);

                        final navigator = Navigator.of(context);
                        final scaffold = ScaffoldMessenger.of(context);

                        final created = await _service.createGroup(
                          name,
                          description,
                          user.id,
                        );
                        setState(() => _working = false);

                        if (!mounted) return;
                        navigator.pop();

                        if (created == null) {
                          scaffold.showSnackBar(
                            const SnackBar(
                              content: Text('Failed to create group.'),
                            ),
                          );
                          return;
                        }

                        final invite =
                            created['invite_code']?.toString() ?? '-';
                        if (!mounted) return;
                        showDialog<void>(
                          context: navigator.context,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: AppColors.cardDark,
                            title: const Text(
                              'Group Created',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Share this code with friends:',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                SelectableText(
                                  invite,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.accent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
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
                                  scaffold.showSnackBar(
                                    const SnackBar(
                                      content: Text('Invite code copied'),
                                    ),
                                  );
                                },
                                child: const Text('Copy'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        );

                        await _loadGroups();
                      },
                child: _working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join Group',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Enter invite code'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _working
                    ? null
                    : () async {
                        final user = _service.getCurrentUser();
                        final code = codeController.text.trim();
                        if (user == null || code.isEmpty) return;

                        setState(() => _working = true);

                        final navigator = Navigator.of(context);
                        final scaffold = ScaffoldMessenger.of(context);

                        final joined = await _service.joinGroup(code, user.id);
                        setState(() => _working = false);

                        if (!mounted) return;
                        navigator.pop();

                        if (joined == null) {
                          scaffold.showSnackBar(
                            const SnackBar(
                              content: Text('Invite code not found.'),
                            ),
                          );
                          return;
                        }

                        await _loadGroups();
                        if (!mounted) return;
                        scaffold.showSnackBar(
                          const SnackBar(
                            content: Text('Joined group successfully.'),
                          ),
                        );
                      },
                child: _working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join Group'),
              ),
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
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadGroups,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
              children: [
                if (_groups.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.groups_2_outlined,
                          size: 56,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No study groups yet',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a group with classmates or join one with an invite code.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _showCreateGroupSheet,
                                icon: const Icon(Icons.group_add),
                                label: const Text('Create Group'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showJoinGroupSheet,
                                icon: const Icon(Icons.login),
                                label: const Text('Join Group'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'My Study Groups',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._groups.map((membership) {
                    final group = Map<String, dynamic>.from(
                      (membership['study_groups'] as Map?) ?? const {},
                    );
                    final name = group['name']?.toString() ?? 'Study Group';
                    final description =
                        group['description']?.toString() ??
                        'No description yet';
                    final groupId = group['id']?.toString() ?? '';
                    final memberCount =
                        (membership['member_count'] as num?)?.toInt() ?? 1;
                    final lastActivity = membership['last_activity_at']
                        ?.toString();

                    return GestureDetector(
                      onTap: groupId.isEmpty
                          ? null
                          : () => context.push('/group/$groupId', extra: group),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                _initials(name),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 16,
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
                                    name,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$memberCount member${memberCount == 1 ? '' : 's'}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatLastActivity(lastActivity),
                                    style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
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
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surfaceDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.group_add),
                    title: const Text('Create Group'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showCreateGroupSheet();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Join Group'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showJoinGroupSheet();
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
