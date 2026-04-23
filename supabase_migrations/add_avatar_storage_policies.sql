-- Ensure avatar bucket exists and is publicly readable.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Authenticated users can upload avatars only inside their own folder: <user_id>/...
drop policy if exists "Avatar upload own folder" on storage.objects;
create policy "Avatar upload own folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Authenticated users can update avatars only inside their own folder.
drop policy if exists "Avatar update own folder" on storage.objects;
create policy "Avatar update own folder"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Authenticated users can delete avatars only inside their own folder.
drop policy if exists "Avatar delete own folder" on storage.objects;
create policy "Avatar delete own folder"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Public read access for avatars.
drop policy if exists "Avatar public read" on storage.objects;
create policy "Avatar public read"
on storage.objects
for select
to public
using (bucket_id = 'avatars');
