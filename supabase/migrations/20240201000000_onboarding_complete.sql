-- StudyTrack Phase 0-9 Schema Fixes & Additions
-- Run this after schema.sql and storage_setup.sql
-- Adds missing fields expected by the app and verification test

-- Add onboarding_complete column to profiles table
alter table if exists public.profiles
add column if not exists onboarding_complete boolean not null default false;

-- Verify all core tables exist
select
  'profiles' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
union all
select
  'modules' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'modules'
union all
select
  'topics' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'topics'
union all
select
  'uploaded_notes' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'uploaded_notes'
union all
select
  'note_chunks' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'note_chunks'
union all
select
  'study_sessions' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'study_sessions'
union all
select
  'exams' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'exams'
union all
select
  'study_groups' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'study_groups'
union all
select
  'group_members' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'group_members'
union all
select
  'group_messages' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'group_messages'
union all
select
  'badges' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'badges'
union all
select
  'weekly_reports' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'weekly_reports'
union all
select
  'class_timetable' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'class_timetable'
union all
select
  'topic_ratings_history' as table_name,
  count(*) as column_count
from information_schema.columns
where table_schema = 'public' and table_name = 'topic_ratings_history'
order by table_name;

-- Verify storage bucket exists
select id, name, public from storage.buckets where id = 'studytrack-notes';
