-- Mesajlar tablosunu oluştur
create table public.messages (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references auth.users(id) on delete cascade not null,
  receiver_id uuid references auth.users(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  read_at timestamp with time zone
);

-- RLS'yi etkinleştir
alter table public.messages enable row level security;

-- Mesaj gönderme politikası
create policy "Users can send messages to their matches"
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

-- Mesaj okuma politikası
create policy "Users can read messages they sent or received"
  on public.messages
  for select
  to authenticated
  using (
    sender_id = auth.uid()
    or receiver_id = auth.uid()
  );

-- Mesaj güncelleme politikası (okundu işaretleme için)
create policy "Users can mark messages as read if they are the receiver"
  on public.messages
  for update
  to authenticated
  using (receiver_id = auth.uid())
  with check (receiver_id = auth.uid());

-- Realtime özelliğini etkinleştir
alter publication supabase_realtime add table messages; 