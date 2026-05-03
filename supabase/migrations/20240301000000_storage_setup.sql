-- StudyTrack Storage setup for Phase 9
-- Safe to run on a fresh Supabase project.

insert into storage.buckets (id, name, public)
values ('studytrack-notes', 'studytrack-notes', true)
on conflict (id) do update
set public = excluded.public;

-- Public bucket for OTA APK distribution and latest.json.
insert into storage.buckets (id, name, public)
values ('app-updates', 'app-updates', true)
on conflict (id) do update
set public = excluded.public;

-- Optional hardening for object listing while keeping files publicly readable.
-- In many projects, public buckets already work without extra policies.
-- These statements are included for explicitness.

drop policy if exists "studytrack_notes_public_read" on storage.objects;
create policy "studytrack_notes_public_read"
on storage.objects
for select
to public
using (bucket_id = 'studytrack-notes');
