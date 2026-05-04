-- =============================================================================
-- DEV PERMISSIONS FIX  — StudyTrack
-- =============================================================================
-- PURPOSE : Fix PostgREST "42501 permission denied for schema public" errors
--           by granting the correct schema/table privileges to API roles.
--
-- SAFE TO RUN ON : local / staging / production — this script ENFORCES RLS,
--                  it does NOT disable it.
--
-- DO NOT USE     : rls_disable_for_backend.sql in production — that file
--                  removes all row-level security and exists for local
--                  emergency debugging ONLY.
-- =============================================================================

begin;

-- 1) Schema visibility for all API roles
grant usage on schema public to anon, authenticated, service_role;

-- 2) service_role gets full superuser-equivalent access on all objects
grant all privileges on all tables    in schema public to service_role;
grant all privileges on all sequences in schema public to service_role;
grant all privileges on all functions in schema public to service_role;

-- 3) authenticated role can read/write (RLS policies control which rows)
grant select, insert, update, delete on all tables    in schema public to authenticated;
grant usage, select                  on all sequences in schema public to authenticated;

-- 4) Keep future objects covered automatically
alter default privileges in schema public
  grant all on tables    to service_role;
alter default privileges in schema public
  grant all on sequences to service_role;
alter default privileges in schema public
  grant all on functions to service_role;
alter default privileges in schema public
  grant select, insert, update, delete on tables    to authenticated;
alter default privileges in schema public
  grant usage, select                  on sequences to authenticated;

-- 5) Explicitly ENABLE Row Level Security on every user-facing table.
--    service_role bypasses RLS at the Postgres level regardless, so this
--    only affects the anon / authenticated JWT roles used by the Flutter app.
alter table public.profiles              enable row level security;
alter table public.modules               enable row level security;
alter table public.topics                enable row level security;
alter table public.topic_ratings_history enable row level security;
alter table public.uploaded_notes        enable row level security;
alter table public.note_chunks           enable row level security;
alter table public.class_timetable       enable row level security;
alter table public.study_sessions        enable row level security;
alter table public.exams                 enable row level security;
alter table public.study_groups          enable row level security;
alter table public.group_members         enable row level security;
alter table public.group_messages        enable row level security;
alter table public.badges                enable row level security;
alter table public.weekly_reports        enable row level security;

commit;

-- Verification — expected: all rows show rowsecurity = true
select tablename,
       rowsecurity                        as rls_enabled,
       has_table_privilege('authenticated', schemaname || '.' || tablename, 'SELECT') as auth_can_select
from   pg_tables
where  schemaname = 'public'
order  by tablename;
