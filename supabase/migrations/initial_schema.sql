-- Profiller tablosu
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  name text,
  age integer,
  gender text check (gender in ('male', 'female')),
  bio text,
  photos text[],
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

-- RLS politikaları
alter table public.profiles enable row level security;
alter table public.likes enable row level security;
alter table public.matches enable row level security;

-- Profil politikaları
create policy "Profiller herkese açık"
  on public.profiles for select
  using (true);

create policy "Kullanıcılar kendi profillerini güncelleyebilir"
  on public.profiles for update
  using (auth.uid() = id);

-- Beğeni politikaları
create policy "Kullanıcılar kendi beğenilerini görebilir"
  on public.likes for select
  using (auth.uid() = user_id);

create policy "Kullanıcılar beğeni ekleyebilir"
  on public.likes for insert
  with check (auth.uid() = user_id);

-- Eşleşme politikaları
create policy "Kullanıcılar kendi eşleşmelerini görebilir"
  on public.matches for select
  using (auth.uid() in (user1_id, user2_id));

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