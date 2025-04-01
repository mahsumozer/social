# Tinder Klonu - Supabase SQL Şeması

Bu klasör, Tinder benzeri bir uygulama için Supabase veritabanı şemasını içerir. Bu şema, temel işlevleri destekleyen tablolar, fonksiyonlar, tetikleyiciler ve güvenlik politikalarını içerir.

## Şema İçeriği

### Tablolar

1. **profiles**: Kullanıcı profilleri için ana tablo
   - Temel kullanıcı bilgileri (isim, yaş, cinsiyet)
   - Konum bilgileri (latitude ve longitude)
   - Profil fotoğrafları dizisi

2. **likes**: Kullanıcıların birbirlerini beğenme kayıtları
   - Kullanıcı eşleştirme mantığının temeli

3. **matches**: Karşılıklı beğeni sonucu oluşan eşleşmeler
   - İki kullanıcının birbirini beğenmesi durumunda otomatik oluşur

4. **messages**: Eşleşen kullanıcılar arasındaki mesajlar
   - Mesaj okundu bilgisi
   - Mesaj içeriği ve zaman damgası

### Önemli Fonksiyonlar

1. **handle_new_like()**: Yeni bir beğeni eklendiğinde tetiklenir ve karşılıklı beğeni varsa eşleşme oluşturur
2. **handle_new_user()**: Yeni bir kullanıcı kaydı olduğunda otomatik olarak profil kaydı oluşturur
3. **nearby_users()**: Belirli bir konum etrafındaki kullanıcıları bulma fonksiyonu
   - Haversine formülü kullanarak mesafe hesaplar
   - Parametreler: enlem, boylam, mesafe (km) ve maksimum kullanıcı sayısı

### Güvenlik Politikaları (RLS)

Tüm tablolar için Row Level Security (RLS) politikaları tanımlanmıştır:

- Profil görüntüleme ve güncelleme
- Beğeni ekleme ve görüntüleme
- Eşleşme görüntüleme
- Mesaj gönderme, okuma ve güncelleme

### Storage

- Profil fotoğrafları için `photos` bucket'ı
- Fotoğraf ekleme, görüntüleme ve silme için güvenlik politikaları

### Realtime

Aşağıdaki tablolar için realtime özelliği etkinleştirilmiştir:
- profiles
- messages
- matches

## Kullanım

Bu SQL şemasını Supabase projenize uygulamak için:

1. Supabase Dashboard > SQL Editor bölümüne gidin
2. `tinder_clone_schema.sql` dosyasının içeriğini kopyalayın ve yapıştırın
3. Query'i çalıştırın

## Harita Özelliği

Bu şema, konum tabanlı eşleştirme için gerekli olan `latitude` ve `longitude` alanlarını ve `nearby_users()` fonksiyonunu içerir. Bu fonksiyon, verilen bir konuma belirli bir mesafe içindeki kullanıcıları bulmanızı sağlar. 