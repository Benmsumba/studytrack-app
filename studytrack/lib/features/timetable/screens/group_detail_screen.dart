import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({required this.groupId, super.key, this.group});

  final String groupId;
  final Map<String, dynamic>? group;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await _service.getGroupMembers(widget.groupId) ?? [];
    if (!mounted) return;
    setState(() {
      _members = members;
      _isLoading = false;
    });
  }

  Future<void> _leaveGroup() async {
    final user = _service.getCurrentUser();
    if (user == null) return;

    final ok = await _service.leaveGroup(widget.groupId, user.id);
    if (!mounted) return;

    if (ok == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Left group successfully.')));
      context.pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not leave group.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = widget.group?['name']?.toString() ?? 'Study Group';
    final groupDescription =
        widget.group?['description']?.toString() ?? 'No description';
    final inviteCode = widget.group?['invite_code']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(groupName),
        backgroundColor: AppColors.backgroundDark,
        actions: [
          IconButton(
            tooltip: 'Group chat',
            onPressed: () => context.push(
              '/group/${widget.groupId}/chat',
              extra: widget.group,
            ),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        groupDescription,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Invite code: $inviteCode',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Members',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (_members.isEmpty)
                  Text(
                    'No members yet.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  )
                else
                  ..._members.map((member) {
                    final role = member['role']?.toString() ?? 'member';
                    final memberUserId = member['user_id']?.toString() ?? '-';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              memberUserId.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              memberUserId,
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                          Text(
                            role.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: role == 'admin'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _leaveGroup,
                  icon: const Icon(Icons.logout),
                  label: const Text('Leave Group'),
                ),
              ],
            ),
    );
  }
}
