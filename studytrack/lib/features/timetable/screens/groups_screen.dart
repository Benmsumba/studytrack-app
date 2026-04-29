import 'package:flutter/material.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isWorking = false;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final user = _service.getCurrentUser();
    if (user == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    final groups = await _service.getMyGroups(user.id) ?? [];

    if (!mounted) return;
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  Future<void> _createGroup() async {
    final user = _service.getCurrentUser();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (user == null || name.isEmpty) return;

    setState(() => _isWorking = true);
    final result = await _service.createGroup(name, description, user.id);
    setState(() => _isWorking = false);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create group.')), 
      );
      return;
    }

    _nameController.clear();
    _descriptionController.clear();
    await _loadGroups();
  }

  Future<void> _joinGroup() async {
    final user = _service.getCurrentUser();
    final code = _inviteCodeController.text.trim();
    if (user == null || code.isEmpty) return;

    setState(() => _isWorking = true);
    final result = await _service.joinGroup(code, user.id);
    setState(() => _isWorking = false);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid invite code or join failed.')),
      );
      return;
    }

    _inviteCodeController.clear();
    await _loadGroups();
  }

  void _showCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Create Group', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Group name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isWorking ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isWorking ? null : _createGroup,
              child: const Text('Create'),
            ),
          ],
        ),
    );
  }

  void _showJoinDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Join Group', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _inviteCodeController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Invite code'),
          ),
          actions: [
            TextButton(
              onPressed: _isWorking ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isWorking ? null : _joinGroup,
              child: const Text('Join'),
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGroups,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showCreateDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Group'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showJoinDialog,
                          icon: const Icon(Icons.login),
                          label: const Text('Join by Code'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'My Study Groups',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_groups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No groups yet. Create one or join with an invite code.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ..._groups.map((membership) {
                      final group = (membership['study_groups'] ?? {}) as Map<String, dynamic>;
                      final groupId = group['id']?.toString() ?? '';
                      final inviteCode = group['invite_code']?.toString() ?? '-';
                      final title = group['name']?.toString() ?? 'Untitled Group';
                      final subtitle = group['description']?.toString() ?? 'No description';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          title: Text(
                            title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '$subtitle\nInvite: $inviteCode',
                            style: GoogleFonts.inter(color: AppColors.textSecondary),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: groupId.isEmpty
                              ? null
                              : () => context.push('/group/$groupId', extra: group),
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        label: const Text('New Group'),
        icon: const Icon(Icons.group_add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
}