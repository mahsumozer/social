-- Create a storage bucket for profile photos
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true);

-- Set up storage policies
create policy "Herkes profil fotoğraflarını görebilir"
  on storage.objects for select
  using ( bucket_id = 'photos' );

create policy "Kullanıcılar kendi profil fotoğraflarını yükleyebilir"
  on storage.objects for insert
  with check (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Kullanıcılar kendi profil fotoğraflarını silebilir"
  on storage.objects for delete
  using (
    bucket_id = 'photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  ); 