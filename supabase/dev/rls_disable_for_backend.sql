-- =============================================================================
-- !! WARNING — LOCAL / EMERGENCY DEBUGGING ONLY !!
-- =============================================================================
-- This script DISABLES Row Level Security on all tables.
-- NEVER run this against your production Supabase project.
-- If you need to fix permission errors in production, use quick_unblock.sql
-- which grants correct privileges WITHOUT touching RLS.
-- =============================================================================
-- StudyTrack RLS Disable for Service Role Backend
-- ALTERNATIVE: Simpler approach - disable RLS on all tables
-- The backend service uses service_role which should bypass all RLS

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

-- Verify RLS is disabled
select tablename, rowsecurity 
from pg_tables 
where schemaname = 'public' 
  and tablename in ('profiles','modules','topics','uploaded_notes','note_chunks','study_sessions','exams','study_groups','group_members','group_messages','badges','weekly_reports','class_timetable','topic_ratings_history')
order by tablename;
