-- StudyTrack Supabase schema
-- PostgreSQL + Supabase Auth + RLS

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- Utility functions
-- -----------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.generate_study_group_invite_code()
returns text
language plpgsql
as $$
declare
  candidate text;
begin
  loop
    candidate := upper(substring(encode(gen_random_bytes(6), 'hex') from 1 for 8));
    exit when not exists (
      select 1
      from public.study_groups sg
      where sg.invite_code = candidate
    );
  end loop;

  return candidate;
end;
$$;

create or replace function public.set_study_group_invite_code()
returns trigger
language plpgsql
as $$
begin
  if new.invite_code is null or btrim(new.invite_code) = '' then
    new.invite_code := public.generate_study_group_invite_code();
  else
    new.invite_code := upper(new.invite_code);
  end if;

  return new;
end;
$$;

create or replace function public.calculate_next_review_at(
  p_rating integer,
  p_from timestamptz default now()
)
returns timestamptz
language plpgsql
immutable
as $$
declare
  interval_days integer;
begin
  interval_days := case
    when p_rating <= 2 then 1
    when p_rating = 3 then 2
    when p_rating = 4 then 3
    when p_rating = 5 then 5
    when p_rating = 6 then 7
    when p_rating = 7 then 10
    when p_rating = 8 then 14
    when p_rating = 9 then 21
    else 30
  end;

  return p_from + make_interval(days => interval_days);
end;
$$;

create or replace function public.set_topic_next_review_at()
returns trigger
language plpgsql
as $$
declare
  base_time timestamptz;
begin
  if new.current_rating is null then
    return new;
  end if;

  base_time := coalesce(new.last_studied_at, now());
  new.next_review_at := public.calculate_next_review_at(new.current_rating, base_time);

  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Tables
-- -----------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  course text,
  year_level integer,
  prime_study_time text,
  study_hours_per_day integer,
  study_preference text,
  avatar_url text,
  streak_count integer not null default 0,
  last_study_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_prime_study_time_check
    check (prime_study_time in ('morning', 'afternoon', 'evening', 'night') or prime_study_time is null),
  constraint profiles_study_preference_check
    check (study_preference in ('alone', 'group') or study_preference is null),
  constraint profiles_year_level_check
    check (year_level is null or year_level > 0),
  constraint profiles_study_hours_per_day_check
    check (study_hours_per_day is null or study_hours_per_day between 0 and 24)
);

create table if not exists public.modules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  color text,
  semester text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint modules_color_hex_check
    check (color is null or color ~ '^#([A-Fa-f0-9]{6})$')
);

create table if not exists public.topics (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  is_studied boolean not null default false,
  current_rating integer,
  study_count integer not null default 0,
  last_studied_at timestamptz,
  next_review_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  constraint topics_current_rating_check
    check (current_rating is null or current_rating between 1 and 10),
  constraint topics_study_count_check
    check (study_count >= 0)
);

create table if not exists public.topic_ratings_history (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null,
  rated_at timestamptz not null default now(),
  constraint topic_ratings_history_rating_check
    check (rating between 1 and 10)
);

create table if not exists public.uploaded_notes (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  file_name text not null,
  file_url text not null,
  file_type text not null,
  is_shared_with_group boolean not null default false,
  processing_status text not null default 'pending',
  created_at timestamptz not null default now(),
  constraint uploaded_notes_file_type_check
    check (file_type in ('pdf', 'pptx')),
  constraint uploaded_notes_processing_status_check
    check (processing_status in ('pending', 'processing', 'ready', 'failed'))
);

create table if not exists public.note_chunks (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.uploaded_notes(id) on delete cascade,
  chunk_index integer not null,
  content text not null,
  created_at timestamptz not null default now(),
  constraint note_chunks_chunk_index_check
    check (chunk_index >= 0),
  constraint note_chunks_unique_per_note unique (note_id, chunk_index)
);

create table if not exists public.class_timetable (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject_name text not null,
  day_of_week integer not null,
  start_time time not null,
  end_time time not null,
  room text,
  lecturer text,
  color text,
  created_at timestamptz not null default now(),
  constraint class_timetable_day_of_week_check
    check (day_of_week between 1 and 7),
  constraint class_timetable_time_check
    check (end_time > start_time),
  constraint class_timetable_color_hex_check
    check (color is null or color ~ '^#([A-Fa-f0-9]{6})$')
);

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  topic_id uuid references public.topics(id) on delete set null,
  module_id uuid references public.modules(id) on delete set null,
  title text not null,
  scheduled_date date not null,
  start_time time,
  end_time time,
  duration_minutes integer,
  status text not null default 'planned',
  actual_duration_minutes integer,
  created_at timestamptz not null default now(),
  constraint study_sessions_status_check
    check (status in ('planned', 'completed', 'missed', 'rescheduled')),
  constraint study_sessions_duration_minutes_check
    check (duration_minutes is null or duration_minutes >= 0),
  constraint study_sessions_actual_duration_minutes_check
    check (actual_duration_minutes is null or actual_duration_minutes >= 0),
  constraint study_sessions_time_check
    check (
      start_time is null
      or end_time is null
      or end_time > start_time
    )
);

create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  module_id uuid not null references public.modules(id) on delete cascade,
  title text not null,
  exam_date date not null,
  exam_time time,
  venue text,
  exam_type text not null,
  created_at timestamptz not null default now(),
  constraint exams_exam_type_check
    check (exam_type in ('written', 'practical', 'oral', 'continuous'))
);

create table if not exists public.study_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  created_by uuid not null references public.profiles(id) on delete cascade,
  invite_code text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.study_groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  constraint group_members_role_check
    check (role in ('admin', 'member')),
  constraint group_members_unique_user_per_group unique (group_id, user_id)
);

create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references public.study_groups(id) on delete cascade,
  topic_id uuid references public.topics(id) on delete set null,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  message_type text not null default 'text',
  created_at timestamptz not null default now(),
  constraint group_messages_message_type_check
    check (message_type in ('text', 'system')),
  constraint group_messages_target_check
    check (
      (group_id is not null and topic_id is null)
      or (group_id is null and topic_id is not null)
    )
);

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  badge_type text not null,
  earned_at timestamptz not null default now()
);

create table if not exists public.weekly_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  week_start date not null,
  week_end date not null,
  topics_studied integer not null default 0,
  topics_planned integer not null default 0,
  sessions_completed integer not null default 0,
  sessions_planned integer not null default 0,
  average_rating numeric(4,2),
  best_subject text,
  weakest_subject text,
  streak_at_end integer not null default 0,
  ai_summary text,
  created_at timestamptz not null default now(),
  constraint weekly_reports_week_range_check
    check (week_end >= week_start),
  constraint weekly_reports_average_rating_check
    check (average_rating is null or (average_rating >= 0 and average_rating <= 10))
);

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists trg_profiles_set_updated_at on public.profiles;
create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists trg_study_groups_set_invite_code on public.study_groups;
create trigger trg_study_groups_set_invite_code
before insert on public.study_groups
for each row
execute function public.set_study_group_invite_code();

drop trigger if exists trg_topics_set_next_review_at on public.topics;
create trigger trg_topics_set_next_review_at
before insert or update of current_rating, last_studied_at on public.topics
for each row
execute function public.set_topic_next_review_at();

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- profiles
create index if not exists idx_profiles_course on public.profiles(course);

-- modules
create index if not exists idx_modules_user_id on public.modules(user_id);
create index if not exists idx_modules_semester on public.modules(semester);
create index if not exists idx_modules_is_active on public.modules(is_active);

-- topics
create index if not exists idx_topics_module_id on public.topics(module_id);
create index if not exists idx_topics_user_id on public.topics(user_id);
create index if not exists idx_topics_next_review_at on public.topics(next_review_at);
create index if not exists idx_topics_is_studied on public.topics(is_studied);

-- topic_ratings_history
create index if not exists idx_topic_ratings_history_topic_id on public.topic_ratings_history(topic_id);
create index if not exists idx_topic_ratings_history_user_id on public.topic_ratings_history(user_id);
create index if not exists idx_topic_ratings_history_rated_at on public.topic_ratings_history(rated_at desc);

-- uploaded_notes
create index if not exists idx_uploaded_notes_topic_id on public.uploaded_notes(topic_id);
create index if not exists idx_uploaded_notes_user_id on public.uploaded_notes(user_id);
create index if not exists idx_uploaded_notes_processing_status on public.uploaded_notes(processing_status);

-- note_chunks
create index if not exists idx_note_chunks_note_id on public.note_chunks(note_id);
create index if not exists idx_note_chunks_chunk_index on public.note_chunks(chunk_index);

-- class_timetable
create index if not exists idx_class_timetable_user_id on public.class_timetable(user_id);
create index if not exists idx_class_timetable_day_of_week on public.class_timetable(day_of_week);

-- study_sessions
create index if not exists idx_study_sessions_user_id on public.study_sessions(user_id);
create index if not exists idx_study_sessions_topic_id on public.study_sessions(topic_id);
create index if not exists idx_study_sessions_module_id on public.study_sessions(module_id);
create index if not exists idx_study_sessions_scheduled_date on public.study_sessions(scheduled_date);
create index if not exists idx_study_sessions_status on public.study_sessions(status);

-- exams
create index if not exists idx_exams_user_id on public.exams(user_id);
create index if not exists idx_exams_module_id on public.exams(module_id);
create index if not exists idx_exams_exam_date on public.exams(exam_date);

-- study_groups
create index if not exists idx_study_groups_created_by on public.study_groups(created_by);
create index if not exists idx_study_groups_invite_code on public.study_groups(invite_code);

-- group_members
create index if not exists idx_group_members_group_id on public.group_members(group_id);
create index if not exists idx_group_members_user_id on public.group_members(user_id);
create index if not exists idx_group_members_role on public.group_members(role);

-- group_messages
create index if not exists idx_group_messages_group_id on public.group_messages(group_id);
create index if not exists idx_group_messages_topic_id on public.group_messages(topic_id);
create index if not exists idx_group_messages_sender_id on public.group_messages(sender_id);
create index if not exists idx_group_messages_created_at on public.group_messages(created_at desc);

-- badges
create index if not exists idx_badges_user_id on public.badges(user_id);
create index if not exists idx_badges_badge_type on public.badges(badge_type);

-- weekly_reports
create index if not exists idx_weekly_reports_user_id on public.weekly_reports(user_id);
create index if not exists idx_weekly_reports_week_start on public.weekly_reports(week_start);
create index if not exists idx_weekly_reports_week_end on public.weekly_reports(week_end);

-- -----------------------------------------------------------------------------
-- Row Level Security (RLS)
-- Users can only access their own data.
-- -----------------------------------------------------------------------------

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

-- profiles
create policy profiles_select_own
on public.profiles
for select
using (id = auth.uid());

create policy profiles_insert_own
on public.profiles
for insert
with check (id = auth.uid());

create policy profiles_update_own
on public.profiles
for update
using (id = auth.uid())
with check (id = auth.uid());

create policy profiles_delete_own
on public.profiles
for delete
using (id = auth.uid());

-- modules
create policy modules_select_own
on public.modules
for select
using (user_id = auth.uid());

create policy modules_insert_own
on public.modules
for insert
with check (user_id = auth.uid());

create policy modules_update_own
on public.modules
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy modules_delete_own
on public.modules
for delete
using (user_id = auth.uid());

-- topics
create policy topics_select_own
on public.topics
for select
using (user_id = auth.uid());

create policy topics_insert_own
on public.topics
for insert
with check (user_id = auth.uid());

create policy topics_update_own
on public.topics
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy topics_delete_own
on public.topics
for delete
using (user_id = auth.uid());

-- topic_ratings_history
create policy topic_ratings_history_select_own
on public.topic_ratings_history
for select
using (user_id = auth.uid());

create policy topic_ratings_history_insert_own
on public.topic_ratings_history
for insert
with check (user_id = auth.uid());

create policy topic_ratings_history_update_own
on public.topic_ratings_history
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy topic_ratings_history_delete_own
on public.topic_ratings_history
for delete
using (user_id = auth.uid());

-- uploaded_notes
create policy uploaded_notes_select_own
on public.uploaded_notes
for select
using (user_id = auth.uid());

create policy uploaded_notes_insert_own
on public.uploaded_notes
for insert
with check (user_id = auth.uid());

create policy uploaded_notes_update_own
on public.uploaded_notes
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy uploaded_notes_delete_own
on public.uploaded_notes
for delete
using (user_id = auth.uid());

-- note_chunks (owned through uploaded_notes.user_id)
create policy note_chunks_select_own
on public.note_chunks
for select
using (
  exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
);

create policy note_chunks_insert_own
on public.note_chunks
for insert
with check (
  exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
);

create policy note_chunks_update_own
on public.note_chunks
for update
using (
  exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
);

create policy note_chunks_delete_own
on public.note_chunks
for delete
using (
  exists (
    select 1
    from public.uploaded_notes un
    where un.id = note_chunks.note_id
      and un.user_id = auth.uid()
  )
);

-- class_timetable
create policy class_timetable_select_own
on public.class_timetable
for select
using (user_id = auth.uid());

create policy class_timetable_insert_own
on public.class_timetable
for insert
with check (user_id = auth.uid());

create policy class_timetable_update_own
on public.class_timetable
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy class_timetable_delete_own
on public.class_timetable
for delete
using (user_id = auth.uid());

-- study_sessions
create policy study_sessions_select_own
on public.study_sessions
for select
using (user_id = auth.uid());

create policy study_sessions_insert_own
on public.study_sessions
for insert
with check (user_id = auth.uid());

create policy study_sessions_update_own
on public.study_sessions
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy study_sessions_delete_own
on public.study_sessions
for delete
using (user_id = auth.uid());

-- exams
create policy exams_select_own
on public.exams
for select
using (user_id = auth.uid());

create policy exams_insert_own
on public.exams
for insert
with check (user_id = auth.uid());

create policy exams_update_own
on public.exams
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy exams_delete_own
on public.exams
for delete
using (user_id = auth.uid());

-- study_groups (owned by creator)
create policy study_groups_select_own
on public.study_groups
for select
using (created_by = auth.uid());

create policy study_groups_insert_own
on public.study_groups
for insert
with check (created_by = auth.uid());

create policy study_groups_update_own
on public.study_groups
for update
using (created_by = auth.uid())
with check (created_by = auth.uid());

create policy study_groups_delete_own
on public.study_groups
for delete
using (created_by = auth.uid());

-- group_members (owned by member row)
create policy group_members_select_own
on public.group_members
for select
using (user_id = auth.uid());

create policy group_members_insert_own
on public.group_members
for insert
with check (user_id = auth.uid());

create policy group_members_update_own
on public.group_members
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy group_members_delete_own
on public.group_members
for delete
using (user_id = auth.uid());

-- group_messages (owned by sender)
create policy group_messages_select_own
on public.group_messages
for select
using (sender_id = auth.uid());

create policy group_messages_insert_own
on public.group_messages
for insert
with check (sender_id = auth.uid());

create policy group_messages_update_own
on public.group_messages
for update
using (sender_id = auth.uid())
with check (sender_id = auth.uid());

create policy group_messages_delete_own
on public.group_messages
for delete
using (sender_id = auth.uid());

-- badges
create policy badges_select_own
on public.badges
for select
using (user_id = auth.uid());

create policy badges_insert_own
on public.badges
for insert
with check (user_id = auth.uid());

create policy badges_update_own
on public.badges
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy badges_delete_own
on public.badges
for delete
using (user_id = auth.uid());

-- weekly_reports
create policy weekly_reports_select_own
on public.weekly_reports
for select
using (user_id = auth.uid());

create policy weekly_reports_insert_own
on public.weekly_reports
for insert
with check (user_id = auth.uid());

create policy weekly_reports_update_own
on public.weekly_reports
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy weekly_reports_delete_own
on public.weekly_reports
for delete
using (user_id = auth.uid());
