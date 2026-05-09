-- Soft delete support and orphan cleanup for historical data retention.
-- Adds deleted_at columns to content tables and cascades cleanup when a module or topic is soft-deleted.

alter table if exists public.modules
  add column if not exists deleted_at timestamptz;

alter table if exists public.topics
  add column if not exists deleted_at timestamptz;

alter table if exists public.exams
  add column if not exists deleted_at timestamptz;

alter table if exists public.class_timetable
  add column if not exists deleted_at timestamptz;

alter table if exists public.uploaded_notes
  add column if not exists deleted_at timestamptz;

create index if not exists idx_modules_deleted_at
  on public.modules (deleted_at);

create index if not exists idx_topics_deleted_at
  on public.topics (deleted_at);

create index if not exists idx_exams_deleted_at
  on public.exams (deleted_at);

create index if not exists idx_class_timetable_deleted_at
  on public.class_timetable (deleted_at);

create index if not exists idx_uploaded_notes_deleted_at
  on public.uploaded_notes (deleted_at);

create or replace function public.soft_delete_module_cleanup()
returns trigger
language plpgsql
as $$
begin
  if old.deleted_at is null and new.deleted_at is not null then
    update public.topics
      set deleted_at = coalesce(deleted_at, new.deleted_at)
      where module_id = new.id
        and deleted_at is null;

    update public.exams
      set deleted_at = coalesce(deleted_at, new.deleted_at)
      where module_id = new.id
        and deleted_at is null;
  end if;

  return new;
end;
$$;

create or replace function public.soft_delete_topic_cleanup()
returns trigger
language plpgsql
as $$
begin
  if old.deleted_at is null and new.deleted_at is not null then
    update public.study_sessions
      set topic_id = null
      where topic_id = new.id;

    update public.uploaded_notes
      set deleted_at = coalesce(deleted_at, new.deleted_at)
      where topic_id = new.id
        and deleted_at is null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_modules_soft_delete_cleanup on public.modules;
create trigger trg_modules_soft_delete_cleanup
after update of deleted_at on public.modules
for each row
execute function public.soft_delete_module_cleanup();

drop trigger if exists trg_topics_soft_delete_cleanup on public.topics;
create trigger trg_topics_soft_delete_cleanup
after update of deleted_at on public.topics
for each row
execute function public.soft_delete_topic_cleanup();
