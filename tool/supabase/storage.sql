-- Veloce storage buckets, limits and anon policies (TECHNICAL.md §7, §8.3).
-- Run once in the Supabase SQL editor. Safe to re-run. Policy names are
-- prefixed `veloce_` so they never touch other projects sharing this database.
--
-- Limits are per bucket, not per file type: images are expected to be
-- compressed on the device (<= 5 MB); buckets that accept video allow 50 MB.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('car-media', 'car-media', true, 52428800,
    array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime', 'application/pdf']),
  ('user-docs', 'user-docs', true, 5242880,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('checklist-media', 'checklist-media', true, 52428800,
    array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']),
  ('receipts', 'receipts', true, 5242880,
    array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "veloce_anon_insert" on storage.objects;
create policy "veloce_anon_insert" on storage.objects
  for insert to anon
  with check (bucket_id in ('car-media', 'user-docs', 'checklist-media', 'receipts'));

drop policy if exists "veloce_anon_select" on storage.objects;
create policy "veloce_anon_select" on storage.objects
  for select to anon
  using (bucket_id in ('car-media', 'user-docs', 'checklist-media', 'receipts'));

-- No UPDATE or DELETE for anon: replacing a file means uploading a new
-- uuid path. The URL of a sensitive file lives only in owner-only Firestore
-- documents (decision D-3).
