import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  bool _loading = true;
  bool _isAdmin = false;
  String? _currentUserId;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _sharedNotes = [];
  List<Map<String, dynamic>> _sessions = [];
  Map<String, String> _topicNames = {};

  final Set<String> _rsvpYes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final currentUser = _service.getCurrentUser();
    _currentUserId = currentUser?.id;

    final members = await _service.getGroupMembers(widget.groupId) ?? [];
    _isAdmin = members.any(
      (member) =>
          member['user_id']?.toString() == _currentUserId &&
          member['role']?.toString() == 'admin',
    );

    // Schema limitation: uploaded_notes has no direct group_id.
    // We show globally shared notes as a practical fallback.
    var sharedNotes = <Map<String, dynamic>>[];
    try {
      final notes = await _service.client
          .from('uploaded_notes')
          .select()
          .eq('is_shared_with_group', true)
          .order('created_at', ascending: false)
          .limit(40);
      sharedNotes = (notes as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (error) {
      debugPrint('group shared notes load error: $error');
    }

    final topicNames = <String, String>{};
    final topicIds = sharedNotes
        .map((note) => note['topic_id']?.toString() ?? '')
        .where((topicId) => topicId.isNotEmpty)
        .toSet();
    for (final topicId in topicIds) {
      final topic = await _service.getTopicById(topicId);
      if (topic != null) {
        topicNames[topicId] = topic.name;
      }
    }

    var sessions = <Map<String, dynamic>>[];
    final user = _service.getCurrentUser();
    if (user != null) {
      try {
        final today = DateTime.now();
        final fromToday = await _service.client
            .from('study_sessions')
            .select()
            .eq('user_id', user.id)
            .gte('scheduled_date', today.toIso8601String().split('T').first)
            .order('scheduled_date')
            .limit(20);
        sessions = (fromToday as List<dynamic>).cast<Map<String, dynamic>>();
      } catch (error) {
        debugPrint('group sessions load error: $error');
      }
    }

    if (!mounted) return;
    setState(() {
      _members = members;
      _sharedNotes = sharedNotes;
      _sessions = sessions;
      _topicNames = topicNames;
      _loading = false;
    });
  }

  Future<void> _removeMember(String userId) async {
    final ok = await _service.removeGroupMember(widget.groupId, userId);
    if (!mounted) return;
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed from group.')),
      );
      await _load();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not remove member (check RLS permissions).'),
      ),
    );
  }

  Future<void> _saveNoteLocally(Map<String, dynamic> note) async {
    final url = note['file_url']?.toString() ?? '';
    if (url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      final bytes = await response.fold<List<int>>(<int>[], (buffer, data) {
        buffer.addAll(data);
        return buffer;
      });

      final documentsDir = await getApplicationDocumentsDirectory();
      final fileName = note['file_name']?.toString() ?? 'shared_note';
      final file = File('${documentsDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved locally: ${file.path}')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save note locally.')),
      );
    }
  }

  Future<void> _leaveGroup() async {
    final user = _service.getCurrentUser();
    if (user == null) return;

    final ok = await _service.leaveGroup(widget.groupId, user.id);
    if (!mounted) return;

    if (ok == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You left the group.')));
      context.pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not leave group.')));
    }
  }

  String _groupName() => widget.group?['name']?.toString() ?? 'Study Group';

  @override
  Widget build(BuildContext context) {
    final description =
        widget.group?['description']?.toString() ?? 'No description';
    final inviteCode = widget.group?['invite_code']?.toString() ?? '-';
    final memberCount = _members.length;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: Text(_groupName()),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Members'),
              Tab(text: 'Shared Notes'),
              Tab(text: 'Sessions'),
              Tab(text: 'Chat'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Leave group',
              onPressed: _leaveGroup,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
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
                          '${_groupName()} • $memberCount member${memberCount == 1 ? '' : 's'}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invite: $inviteCode',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _membersTab(),
                        _notesTab(),
                        _sessionsTab(),
                        _chatTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _membersTab() {
    if (_members.isEmpty) {
      return Center(
        child: Text(
          'No members yet.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final role = member['role']?.toString() ?? 'member';
        final userId = member['user_id']?.toString() ?? 'unknown';
        final name = member['name']?.toString() ?? userId;
        final course = member['course']?.toString() ?? 'N/A';
        final yearLevel = (member['year_level'] as num?)?.toInt();
        final joinedAt = member['joined_at']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(name.substring(0, 1).toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$course${yearLevel == null ? '' : ' • Year $yearLevel'}',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      joinedAt.isEmpty
                          ? 'Member'
                          : 'Joined ${joinedAt.split('T').first}',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: role == 'admin'
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: role == 'admin'
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isAdmin && userId != _currentUserId) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove member',
                  onPressed: () => _removeMember(userId),
                  icon: const Icon(
                    Icons.person_remove_alt_1_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _notesTab() {
    final notesByTopic = <String, List<Map<String, dynamic>>>{};
    for (final note in _sharedNotes) {
      final topicId = note['topic_id']?.toString() ?? '';
      final topicName = _topicNames[topicId] ?? 'General';
      notesByTopic.putIfAbsent(topicName, () => []).add(note);
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            'Shared notes are shown from globally shared uploads. Group-specific note linking can be added in a later schema upgrade.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: _sharedNotes.isEmpty
              ? Center(
                  child: Text(
                    'No shared notes yet.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                  children: notesByTopic.entries.map((entry) {
                    final topicName = entry.key;
                    final notes = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                          topicName,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${notes.length} note${notes.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        children: notes.map((note) {
                          final fileName =
                              note['file_name']?.toString() ?? 'Untitled';
                          final fileType =
                              note['file_type']?.toString().toUpperCase() ??
                              '-';
                          final status =
                              note['processing_status']?.toString() ?? '-';
                          return ListTile(
                            leading: const Icon(
                              Icons.description_outlined,
                              color: Colors.white70,
                            ),
                            title: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '$fileType • $status',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (choice) async {
                                if (choice == 'open') {
                                  final url =
                                      note['file_url']?.toString() ?? '';
                                  if (url.isNotEmpty) {
                                    await SharePlus.instance.share(
                                      ShareParams(text: url),
                                    );
                                  }
                                } else if (choice == 'save') {
                                  await _saveNoteLocally(note);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'open',
                                  child: Text('Open Note'),
                                ),
                                PopupMenuItem(
                                  value: 'save',
                                  child: Text('Save Locally'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _sessionsTab() {
    if (_sessions.isEmpty) {
      return Center(
        child: Text(
          'No upcoming sessions.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final id = session['id']?.toString() ?? '';
        final title = session['title']?.toString() ?? 'Study Session';
        final date = session['scheduled_date']?.toString() ?? '-';
        final start = session['start_time']?.toString() ?? '--:--';
        final status = session['status']?.toString() ?? 'planned';
        final rsvp = _rsvpYes.contains(id);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$date • $start • ${status.toUpperCase()}',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: () {
                      setState(() {
                        if (rsvp) {
                          _rsvpYes.remove(id);
                        } else {
                          _rsvpYes.add(id);
                        }
                      });
                    },
                    child: Text(rsvp ? 'RSVP: Going ✓' : 'RSVP'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chatTab() => Center(
    child: FilledButton.icon(
      onPressed: () =>
          context.push('/group/${widget.groupId}/chat', extra: widget.group),
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text('Open Group Chat'),
    ),
  );
}
