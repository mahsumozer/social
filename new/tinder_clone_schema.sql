-- Mevcut tabloları temizle
drop trigger if exists on_auth_user_created on auth.users cascade;
drop trigger if exists on_new_like on public.likes cascade;
drop trigger if exists handle_profiles_updated_at on public.profiles cascade;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.handle_new_like() cascade;
drop function if exists public.handle_updated_at() cascade;
drop table if exists public.messages cascade;
drop table if exists public.matches cascade;
drop table if exists public.likes cascade;
drop table if exists public.profiles cascade;

-- Profiller tablosu
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  name text,
  age integer,
  gender text check (gender in ('male', 'female')),
  bio text,
  photos text[],
  latitude double precision,
  longitude double precision,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Profil güncelleme tetikleyicisi
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger handle_profiles_updated_at
  before update on public.profiles
  for each row
  execute procedure public.handle_updated_at();

-- Beğeniler tablosu
create table public.likes (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  liked_user_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, liked_user_id)
);

-- Eşleşmeler tablosu
create table public.matches (
  id uuid default uuid_generate_v4() primary key,
  user1_id uuid references public.profiles(id) on delete cascade not null,
  user2_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user1_id, user2_id)
);

-- Mesajlar tablosu
create table public.messages (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references auth.users(id) on delete cascade not null,
  receiver_id uuid references auth.users(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  read_at timestamp with time zone
);

-- RLS politikaları
alter table public.profiles enable row level security;
alter table public.likes enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;

-- Politikaları güvenli şekilde ekle
do
$$
begin
  -- Profil politikaları
  if not exists (select 1 from pg_policies where tablename = 'profiles' and policyname = 'Profiller herkese açık') then
    create policy "Profiller herkese açık"
      on public.profiles for select
      using (true);
  end if;

  if not exists (select 1 from pg_policies where tablename = 'profiles' and policyname = 'Kullanıcılar kendi profillerini güncelleyebilir') then
    create policy "Kullanıcılar kendi profillerini güncelleyebilir"
      on public.profiles for update
      using (auth.uid() = id);
  end if;

  -- Beğeni politikaları
  if not exists (select 1 from pg_policies where tablename = 'likes' and policyname = 'Kullanıcılar kendi beğenilerini görebilir') then
    create policy "Kullanıcılar kendi beğenilerini görebilir"
      on public.likes for select
      using (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where tablename = 'likes' and policyname = 'Kullanıcılar beğeni ekleyebilir') then
    create policy "Kullanıcılar beğeni ekleyebilir"
      on public.likes for insert
      with check (auth.uid() = user_id);
  end if;

  -- Eşleşme politikaları
  if not exists (select 1 from pg_policies where tablename = 'matches' and policyname = 'Kullanıcılar kendi eşleşmelerini görebilir') then
    create policy "Kullanıcılar kendi eşleşmelerini görebilir"
      on public.matches for select
      using (auth.uid() in (user1_id, user2_id));
  end if;

  -- Mesaj politikaları
  if not exists (select 1 from pg_policies where tablename = 'messages' and policyname = 'Kullanıcılar eşleştikleri kişilere mesaj gönderebilir') then
    create policy "Kullanıcılar eşleştikleri kişilere mesaj gönderebilir"
      on public.messages
      for insert
      to authenticated
      with check (
        exists (
          select 1 from matches
          where (user1_id = auth.uid() and user2_id = receiver_id)
             or (user2_id = auth.uid() and user1_id = receiver_id)
        )
        and sender_id = auth.uid()
      );
  end if;

  if not exists (select 1 from pg_policies where tablename = 'messages' and policyname = 'Kullanıcılar gönderdikleri veya aldıkları mesajları okuyabilir') then
    create policy "Kullanıcılar gönderdikleri veya aldıkları mesajları okuyabilir"
      on public.messages
      for select
      to authenticated
      using (
        sender_id = auth.uid()
        or receiver_id = auth.uid()
      );
  end if;

  if not exists (select 1 from pg_policies where tablename = 'messages' and policyname = 'Alıcılar mesajları okundu olarak işaretleyebilir') then
    create policy "Alıcılar mesajları okundu olarak işaretleyebilir"
      on public.messages
      for update
      to authenticated
      using (receiver_id = auth.uid())
      with check (receiver_id = auth.uid());
  end if;

  -- Storage politikaları
  if not exists (select 1 from pg_policies where tablename = 'objects' and policyname = 'Herkes profil fotoğraflarını görebilir') then
    create policy "Herkes profil fotoğraflarını görebilir"
      on storage.objects for select
      using ( bucket_id = 'photos' );
  end if;

  if not exists (select 1 from pg_policies where tablename = 'objects' and policyname = 'Kullanıcılar kendi profil fotoğraflarını yükleyebilir') then
    create policy "Kullanıcılar kendi profil fotoğraflarını yükleyebilir"
      on storage.objects for insert
      with check (
        bucket_id = 'photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
      );
  end if;

  if not exists (select 1 from pg_policies where tablename = 'objects' and policyname = 'Kullanıcılar kendi profil fotoğraflarını silebilir') then
    create policy "Kullanıcılar kendi profil fotoğraflarını silebilir"
      on storage.objects for delete
      using (
        bucket_id = 'photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
      );
  end if;
end
$$;

-- Fonksiyonlar
create or replace function public.handle_new_like()
returns trigger as $$
begin
  -- Karşılıklı beğeni kontrolü
  if exists (
    select 1 from public.likes
    where user_id = new.liked_user_id
    and liked_user_id = new.user_id
  ) then
    -- Eşleşme oluştur
    insert into public.matches (user1_id, user2_id)
    values (
      least(new.user_id, new.liked_user_id),
      greatest(new.user_id, new.liked_user_id)
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_new_like
  after insert on public.likes
  for each row
  execute procedure public.handle_new_like();

-- Yeni kullanıcı kaydı olduğunda profil oluştur
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id)
  values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute procedure public.handle_new_user();

-- Yakındaki kullanıcıları bulma fonksiyonu
create or replace function public.nearby_users(
  lat double precision,
  long double precision,
  distance_km double precision default 50,
  max_users integer default 100
)
returns table (
  id uuid,
  name text,
  age integer,
  gender text,
  bio text,
  photos text[],
  distance double precision
)
language sql
as $$
  -- Dünya yarıçapı km cinsinden
  with earth_radius_km as (
    select 6371 as radius
  )
  select
    p.id,
    p.name,
    p.age,
    p.gender,
    p.bio,
    p.photos,
    -- Haversine formülü ile uzaklık hesaplaması
    (
      select radius * 2 * asin(
        sqrt(
          power(sin((radians(p.latitude) - radians(lat)) / 2), 2) +
          cos(radians(lat)) * cos(radians(p.latitude)) *
          power(sin((radians(p.longitude) - radians(long)) / 2), 2)
        )
      ) from earth_radius_km
    ) as distance
  from
    profiles p
  where
    -- Kullanıcının kendisini hariç tut
    p.id != auth.uid()
    -- Enlem ve boylam değerleri olan profilleri al
    and p.latitude is not null
    and p.longitude is not null
  order by
    distance
  limit max_users;
$$;

-- Storage bucket oluştur
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

-- Realtime özelliğini etkinleştir
do
$$
begin
  -- Realtime yayını mevcut değilse oluştur
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;

  -- Tabloları kontrol et ve ekle
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'profiles') then
    alter publication supabase_realtime add table public.profiles;
  end if;

  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'messages') then
    alter publication supabase_realtime add table public.messages;
  end if;

  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'matches') then
    alter publication supabase_realtime add table public.matches;
  end if;
end
$$; 