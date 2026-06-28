-- Daisy Shop review image storage.
-- Run this in Supabase SQL Editor when review images cannot upload.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'review-images',
  'review-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "review images are publicly readable" on storage.objects;
drop policy if exists "users upload own review images" on storage.objects;
drop policy if exists "users update own review images" on storage.objects;
drop policy if exists "users delete own review images" on storage.objects;

create policy "review images are publicly readable" on storage.objects
  for select using (bucket_id = 'review-images');

create policy "users upload own review images" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'review-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users update own review images" on storage.objects
  for update to authenticated using (
    bucket_id = 'review-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  ) with check (
    bucket_id = 'review-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users delete own review images" on storage.objects
  for delete to authenticated using (
    bucket_id = 'review-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
