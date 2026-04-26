-- QUICK UNBLOCK (DEV) for StudyTrack
-- Use this when PostgREST returns: 42501 permission denied for schema public
-- Run in Supabase SQL Editor as a single script.

begin;

-- 1) Schema usage for API roles
grant usage on schema public to anon, authenticated, service_role;

-- 2) Service role must have full access
grant all privileges on all tables in schema public to service_role;
grant all privileges on all sequences in schema public to service_role;
grant all privileges on all functions in schema public to service_role;

-- 3) Authenticated client access (app reads/writes)
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- 4) Future objects keep working
alter default privileges in schema public grant all on tables to service_role;
alter default privileges in schema public grant all on sequences to service_role;
alter default privileges in schema public grant all on functions to service_role;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant usage, select on sequences to authenticated;

-- 5) DEV shortcut: disable RLS for every public table
-- (safe for local/dev testing; tighten later for production)
do $$
declare r record;
begin
  for r in
    select schemaname, tablename
    from pg_tables
    where schemaname = 'public'
  loop
    execute format('alter table %I.%I disable row level security', r.schemaname, r.tablename);
  end loop;
end $$;

commit;

-- Verification
select r.rolname,
       has_schema_privilege(r.rolname, 'public', 'USAGE') as schema_usage
from pg_roles r
where r.rolname in ('anon', 'authenticated', 'service_role')
order by r.rolname;

select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
order by tablename;
