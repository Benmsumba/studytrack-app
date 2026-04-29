-- StudyTrack RLS Service Key Bypass Policies
-- Run this to allow the service role to insert/update records
-- This is needed for the backend API to work with document uploads

-- Allow service_role (backend API) to bypass RLS
alter table public.profiles disable row level security;
alter table public.modules disable row level security;
alter table public.topics disable row level security;
alter table public.topic_ratings_history disable row level security;
alter table public.uploaded_notes disable row level security;
alter table public.note_chunks disable row level security;
alter table public.class_timetable disable row level security;
alter table public.study_sessions disable row level security;
alter table public.exams disable row level security;
alter table public.study_groups disable row level security;
alter table public.group_members disable row level security;
alter table public.group_messages disable row level security;
alter table public.badges disable row level security;
alter table public.weekly_reports disable row level security;

-- Re-enable RLS with proper policies that bypass for service_role
alter table public.profiles enable row level security;
alter table public.modules enable row level security;
alter table public.topics enable row level security;
alter table public.topic_ratings_history enable row level security;
alter table public.uploaded_notes enable row level security;
alter table public.note_chunks enable row level security;
alter table public.class_timetable enable row level security;
alter table public.study_sessions enable row level security;
alter table public.exams enable row level security;
alter table public.study_groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_messages enable row level security;
alter table public.badges enable row level security;
alter table public.weekly_reports enable row level security;

-- profiles: Allow auth users to access own profile + service_role bypass
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
using (
  auth.role() = 'service_role'
  or id = auth.uid()
);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
with check (auth.role() = 'service_role' or id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
using (auth.role() = 'service_role' or id = auth.uid())
with check (auth.role() = 'service_role' or id = auth.uid());

drop policy if exists profiles_delete_own on public.profiles;
create policy profiles_delete_own
on public.profiles
for delete
using (auth.role() = 'service_role' or id = auth.uid());

-- modules: Service role bypass
drop policy if exists modules_select_own on public.modules;
create policy modules_select_own
on public.modules
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists modules_insert_own on public.modules;
create policy modules_insert_own
on public.modules
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists modules_update_own on public.modules;
create policy modules_update_own
on public.modules
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists modules_delete_own on public.modules;
create policy modules_delete_own
on public.modules
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

-- topics: Service role bypass
drop policy if exists topics_select_own on public.topics;
create policy topics_select_own
on public.topics
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists topics_insert_own on public.topics;
create policy topics_insert_own
on public.topics
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists topics_update_own on public.topics;
create policy topics_update_own
on public.topics
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists topics_delete_own on public.topics;
create policy topics_delete_own
on public.topics
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

-- uploaded_notes: Service role bypass
drop policy if exists uploaded_notes_select_own on public.uploaded_notes;
create policy uploaded_notes_select_own
on public.uploaded_notes
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists uploaded_notes_insert_own on public.uploaded_notes;
create policy uploaded_notes_insert_own
on public.uploaded_notes
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists uploaded_notes_update_own on public.uploaded_notes;
create policy uploaded_notes_update_own
on public.uploaded_notes
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists uploaded_notes_delete_own on public.uploaded_notes;
create policy uploaded_notes_delete_own
on public.uploaded_notes
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

-- note_chunks: Service role bypass
drop policy if exists note_chunks_select_own on public.note_chunks;
create policy note_chunks_select_own
on public.note_chunks
for select
using (
  auth.role() = 'service_role'
  or exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
);

drop policy if exists note_chunks_insert_own on public.note_chunks;
create policy note_chunks_insert_own
on public.note_chunks
for insert
with check (
  auth.role() = 'service_role'
  or exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
);

drop policy if exists note_chunks_update_own on public.note_chunks;
create policy note_chunks_update_own
on public.note_chunks
for update
using (
  auth.role() = 'service_role'
  or exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
)
with check (
  auth.role() = 'service_role'
  or exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
);

drop policy if exists note_chunks_delete_own on public.note_chunks;
create policy note_chunks_delete_own
on public.note_chunks
for delete
using (
  auth.role() = 'service_role'
  or exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
);

-- study_sessions, exams, etc: Service role bypass
drop policy if exists study_sessions_select_own on public.study_sessions;
create policy study_sessions_select_own
on public.study_sessions
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists study_sessions_insert_own on public.study_sessions;
create policy study_sessions_insert_own
on public.study_sessions
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists study_sessions_update_own on public.study_sessions;
create policy study_sessions_update_own
on public.study_sessions
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists study_sessions_delete_own on public.study_sessions;
create policy study_sessions_delete_own
on public.study_sessions
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists exams_select_own on public.exams;
create policy exams_select_own
on public.exams
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists exams_insert_own on public.exams;
create policy exams_insert_own
on public.exams
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists exams_update_own on public.exams;
create policy exams_update_own
on public.exams
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists exams_delete_own on public.exams;
create policy exams_delete_own
on public.exams
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

-- Other tables with similar patterns - service role bypass
drop policy if exists class_timetable_select_own on public.class_timetable;
create policy class_timetable_select_own
on public.class_timetable
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists class_timetable_insert_own on public.class_timetable;
create policy class_timetable_insert_own
on public.class_timetable
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists class_timetable_update_own on public.class_timetable;
create policy class_timetable_update_own
on public.class_timetable
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists class_timetable_delete_own on public.class_timetable;
create policy class_timetable_delete_own
on public.class_timetable
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists study_groups_select_own on public.study_groups;
create policy study_groups_select_own
on public.study_groups
for select
using (auth.role() = 'service_role' or created_by = auth.uid());

drop policy if exists study_groups_insert_own on public.study_groups;
create policy study_groups_insert_own
on public.study_groups
for insert
with check (auth.role() = 'service_role' or created_by = auth.uid());

drop policy if exists study_groups_update_own on public.study_groups;
create policy study_groups_update_own
on public.study_groups
for update
using (auth.role() = 'service_role' or created_by = auth.uid())
with check (auth.role() = 'service_role' or created_by = auth.uid());

drop policy if exists study_groups_delete_own on public.study_groups;
create policy study_groups_delete_own
on public.study_groups
for delete
using (auth.role() = 'service_role' or created_by = auth.uid());

drop policy if exists group_members_select_own on public.group_members;
create policy group_members_select_own
on public.group_members
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists group_members_insert_own on public.group_members;
create policy group_members_insert_own
on public.group_members
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists group_members_update_own on public.group_members;
create policy group_members_update_own
on public.group_members
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists group_members_delete_own on public.group_members;
create policy group_members_delete_own
on public.group_members
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists group_messages_select_own on public.group_messages;
create policy group_messages_select_own
on public.group_messages
for select
using (auth.role() = 'service_role' or sender_id = auth.uid());

drop policy if exists group_messages_insert_own on public.group_messages;
create policy group_messages_insert_own
on public.group_messages
for insert
with check (auth.role() = 'service_role' or sender_id = auth.uid());

drop policy if exists group_messages_update_own on public.group_messages;
create policy group_messages_update_own
on public.group_messages
for update
using (auth.role() = 'service_role' or sender_id = auth.uid())
with check (auth.role() = 'service_role' or sender_id = auth.uid());

drop policy if exists group_messages_delete_own on public.group_messages;
create policy group_messages_delete_own
on public.group_messages
for delete
using (auth.role() = 'service_role' or sender_id = auth.uid());

drop policy if exists badges_select_own on public.badges;
create policy badges_select_own
on public.badges
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists badges_insert_own on public.badges;
create policy badges_insert_own
on public.badges
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists badges_update_own on public.badges;
create policy badges_update_own
on public.badges
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists badges_delete_own on public.badges;
create policy badges_delete_own
on public.badges
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists weekly_reports_select_own on public.weekly_reports;
create policy weekly_reports_select_own
on public.weekly_reports
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists weekly_reports_insert_own on public.weekly_reports;
create policy weekly_reports_insert_own
on public.weekly_reports
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists weekly_reports_update_own on public.weekly_reports;
create policy weekly_reports_update_own
on public.weekly_reports
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists weekly_reports_delete_own on public.weekly_reports;
create policy weekly_reports_delete_own
on public.weekly_reports
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists topic_ratings_history_select_own on public.topic_ratings_history;
create policy topic_ratings_history_select_own
on public.topic_ratings_history
for select
using (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists topic_ratings_history_insert_own on public.topic_ratings_history;
create policy topic_ratings_history_insert_own
on public.topic_ratings_history
for insert
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists topic_ratings_history_update_own on public.topic_ratings_history;
create policy topic_ratings_history_update_own
on public.topic_ratings_history
for update
using (auth.role() = 'service_role' or user_id = auth.uid())
with check (auth.role() = 'service_role' or user_id = auth.uid());

drop policy if exists topic_ratings_history_delete_own on public.topic_ratings_history;
create policy topic_ratings_history_delete_own
on public.topic_ratings_history
for delete
using (auth.role() = 'service_role' or user_id = auth.uid());

-- Verify the policies work
select 'All RLS policies updated for service role bypass' as status;
