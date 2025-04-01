-- =====================================================
-- !!! ÖNEMLİ UYARI !!!
-- Bu dosya sadece test ortamında kullanılmalıdır.
-- Gerçek production ortamında ASLA kullanmayın.
-- Bu SQL kodunu çalıştırmak için:
-- 1. SQL Editor'da 'Service Role' yetkisiyle çalıştırın VEYA
-- 2. Dosyadaki RLS devre dışı bırakma komutlarının aktif olduğundan emin olun
-- =====================================================

-- Test için örnek kullanıcı ve konum verileri ekleme
-- NOT: Bu dosya Supabase projesinde sadece test amaçlı kullanılmalıdır

-- Test sırasında RLS politikalarını devre dışı bırak
-- ÖNEMLİ: Bu sadece test ortamında kullanılmalıdır, gerçek ortamda asla!
begin;
-- RLS'yi geçici olarak devre dışı bırak
alter table public.profiles disable row level security;
alter table public.likes disable row level security;
alter table public.matches disable row level security;
alter table public.messages disable row level security;

-- Kullanıcılar için UUID'ler tanımlayalım
do $$
declare
  user1_id uuid := '00000000-0000-0000-0000-000000000001';
  user2_id uuid := '00000000-0000-0000-0000-000000000002';
  user3_id uuid := '00000000-0000-0000-0000-000000000003';
  user4_id uuid := '00000000-0000-0000-0000-000000000004';
  user5_id uuid := '00000000-0000-0000-0000-000000000005';
begin
  -- Önce test kullanıcılarını oluşturalım (eğer yoksa)
  
  -- Kullanıcı 1: İstanbul - Kadıköy
  insert into auth.users (id, email, role)
  values (user1_id, 'test1@example.com', 'authenticated')
  on conflict (id) do nothing;
  
  -- Kullanıcı 2: İstanbul - Beşiktaş
  insert into auth.users (id, email, role)
  values (user2_id, 'test2@example.com', 'authenticated')
  on conflict (id) do nothing;
  
  -- Kullanıcı 3: İstanbul - Şişli
  insert into auth.users (id, email, role)
  values (user3_id, 'test3@example.com', 'authenticated')
  on conflict (id) do nothing;
  
  -- Kullanıcı 4: İstanbul - Üsküdar
  insert into auth.users (id, email, role)
  values (user4_id, 'test4@example.com', 'authenticated')
  on conflict (id) do nothing;
  
  -- Kullanıcı 5: İstanbul - Beyoğlu
  insert into auth.users (id, email, role)
  values (user5_id, 'test5@example.com', 'authenticated')
  on conflict (id) do nothing;
  
  -- Profil bilgilerini güncelle
  -- Kullanıcı 1: İstanbul - Kadıköy
  update public.profiles set
    name = 'Ahmet',
    age = 28,
    gender = 'male',
    bio = 'İstanbul Kadıköy''de yaşıyorum. Spor ve müzik dinlemekten hoşlanırım.',
    photos = array['https://example.com/photos/ahmet1.jpg', 'https://example.com/photos/ahmet2.jpg'],
    latitude = 40.9929,  -- Kadıköy
    longitude = 29.0250
  where id = user1_id;
  
  -- Kullanıcı 2: İstanbul - Beşiktaş
  update public.profiles set
    name = 'Ayşe',
    age = 25,
    gender = 'female',
    bio = 'Beşiktaş''ta yaşıyorum. Kitap okumak ve yeni insanlarla tanışmak beni mutlu eder.',
    photos = array['https://example.com/photos/ayse1.jpg', 'https://example.com/photos/ayse2.jpg'],
    latitude = 41.0420,  -- Beşiktaş
    longitude = 29.0094
  where id = user2_id;
  
  -- Kullanıcı 3: İstanbul - Şişli
  update public.profiles set
    name = 'Mehmet',
    age = 30,
    gender = 'male',
    bio = 'Şişli''de yaşayan bir yazılım geliştiriciyim. Kod yazmak ve doğa yürüyüşleri favorilerim.',
    photos = array['https://example.com/photos/mehmet1.jpg'],
    latitude = 41.0570,  -- Şişli
    longitude = 28.9900
  where id = user3_id;
  
  -- Kullanıcı 4: İstanbul - Üsküdar
  update public.profiles set
    name = 'Zeynep',
    age = 27,
    gender = 'female',
    bio = 'Üsküdar''da yaşıyorum. Fotoğrafçılık ve seyahat etmek en büyük hobilerim.',
    photos = array['https://example.com/photos/zeynep1.jpg', 'https://example.com/photos/zeynep2.jpg'],
    latitude = 41.0234,  -- Üsküdar
    longitude = 29.0140
  where id = user4_id;
  
  -- Kullanıcı 5: İstanbul - Beyoğlu
  update public.profiles set
    name = 'Can',
    age = 32,
    gender = 'male',
    bio = 'Beyoğlu''nun kalbinde yaşıyorum. Müzik, tiyatro ve iyi yemek vazgeçilmezlerim.',
    photos = array['https://example.com/photos/can1.jpg', 'https://example.com/photos/can2.jpg'],
    latitude = 41.0319,  -- Beyoğlu
    longitude = 28.9833
  where id = user5_id;
  
  -- Bazı beğeniler ekleyelim
  insert into public.likes (user_id, liked_user_id)
  values
    (user1_id, user2_id),
    (user2_id, user1_id),  -- Eşleşme oluşacak
    (user1_id, user4_id),
    (user3_id, user4_id),
    (user4_id, user3_id),  -- Eşleşme oluşacak
    (user5_id, user2_id)
  on conflict (user_id, liked_user_id) do nothing;
  
  -- Bazı mesajlar ekleyelim (yukarıdaki eşleşmeler için)
  insert into public.messages (sender_id, receiver_id, content)
  values
    (user1_id, user2_id, 'Merhaba Ayşe, profilini çok beğendim!'),
    (user2_id, user1_id, 'Teşekkür ederim Ahmet, ben de seninkini beğendim. Nasılsın?'),
    (user3_id, user4_id, 'Merhaba Zeynep, fotoğraflarını çok etkileyici buldum.'),
    (user4_id, user3_id, 'Teşekkürler Mehmet, yazılımla ilgilendiğini gördüm. Hangi dilleri kullanıyorsun?')
  on conflict do nothing;
end;
$$;

-- RLS'yi tekrar etkinleştir
alter table public.profiles enable row level security;
alter table public.likes enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;

commit; 