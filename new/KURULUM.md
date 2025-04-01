# Supabase Kurulum Kılavuzu

Bu döküman, Tinder klonu uygulaması için Supabase projesini kurma adımlarını içerir.

## 1. Supabase Hesabı Oluşturma

1. [Supabase](https://supabase.com/) sitesine gidin
2. Yeni bir hesap oluşturun veya mevcut hesabınızla giriş yapın
3. "New Project" butonuna tıklayın

## 2. Yeni Proje Oluşturma

1. Projeye bir isim verin (örn. "Tinder-Clone")
2. Bir şifre belirleyin (bu şifreyi not alın, PostgreSQL veritabanı için gerekecek)
3. Bölge seçin (uygulamanın hedef kitlesine en yakın bölgeyi tercih edin)
4. "Create New Project" butonuna tıklayın ve projenin oluşturulmasını bekleyin

## 3. SQL Şemasını Uygulama

1. Supabase projesinin kontrol panelinde, sol menüden "SQL Editor" seçeneğine tıklayın
2. "New Query" butonuna tıklayın
3. `tinder_clone_schema.sql` dosyasının içeriğini editöre kopyalayın
4. "Run" butonuna tıklayarak SQL sorgusunu çalıştırın
5. Tüm tabloların, fonksiyonların ve güvenlik politikalarının başarıyla oluşturulduğundan emin olun

## 4. Authentication Ayarları

1. Sol menüden "Authentication" seçeneğine tıklayın
2. "Settings" sekmesinde, "Email Auth" özelliğinin aktif olduğundan emin olun
3. Opsiyonel: Sosyal giriş yöntemlerini ekleyebilirsiniz (Google, Facebook vb.)

## 5. Storage Bucket Kontrolü

1. Sol menüden "Storage" seçeneğine tıklayın
2. `photos` adlı bir bucket'ın otomatik oluşturulduğunu kontrol edin
3. Eğer oluşturulmadıysa, "New Bucket" butonuna tıklayarak manuel olarak oluşturun:
   - Bucket Name: photos
   - Public Bucket: Evet (işaretleyin)
   - RLS: Enable (işaretleyin)

## 6. Test Verileri Ekleme

1. Sol menüden "SQL Editor" seçeneğine tıklayın
2. "New Query" butonuna tıklayın 
3. `ornek_veri.sql` dosyasının içeriğini editöre kopyalayın
4. RLS (Row-Level Security) hataları alırsanız:
   - Dosyanın içinde "RLS'yi geçici olarak devre dışı bırak" bölümünün aktif olduğundan emin olun
   - VEYA Service Role API anahtarını kullanarak sorguları çalıştırın:
     - SQL Editor'ın sağ üst köşesindeki "Servis Rolünü Kullan" seçeneğini işaretleyin
     - Bu, RLS kurallarını atlamanızı sağlayacaktır
5. "Run" butonuna tıklayarak SQL sorgusunu çalıştırın

## 7. API Anahtarlarını Alma

1. Sol menüden "Settings" > "API" seçeneğine tıklayın
2. Aşağıdaki bilgileri not alın:
   - URL: `https://[YOUR-PROJECT-ID].supabase.co`
   - anon/public: `your-anon-key`
   - service_role: `your-service-role-key` (sadece güvenli ortamlarda kullanın)

## 8. Uygulama Entegrasyonu

1. Not aldığınız API bilgilerini uygulamanızın `.env` dosyasına ekleyin:

```
REACT_APP_SUPABASE_URL=https://[YOUR-PROJECT-ID].supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key
```

2. Uygulamanızın Supabase istemcisini yapılandırın (örnek kod):

```javascript
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
```

## 9. Realtime Özelliğini Test Etme

1. SQL Editor'da aşağıdaki komutu çalıştırarak Realtime özelliğinin etkin olduğunu kontrol edin:

```sql
select * from pg_publication;
```

2. Sonuçlarda `supabase_realtime` yayınını ve içerdiği tabloları (`profiles`, `messages`, `matches`) görmelisiniz

## 10. Harita Fonksiyonunu Test Etme

1. SQL Editor'da aşağıdaki sorguyu çalıştırarak `nearby_users` fonksiyonunu test edin:

```sql
select * from nearby_users(41.0082, 28.9784, 10, 5);  -- İstanbul koordinatları, 10km mesafe, en fazla 5 kullanıcı
```

2. Bu sorgu, belirlenen konuma en yakın 5 kullanıcıyı ve mesafelerini döndürecektir (test verisi eklenmişse)

## Notlar

- SQL şeması, tablolar zaten varsa silip yeniden oluşturacak şekilde tasarlanmıştır. Mevcut verileri korumak isterseniz, dosyanın başındaki `drop` ifadelerini kaldırın.
- Gerçek uygulamada, kullanıcı konumlarını güncellemek için düzenli olarak istemciden konum bilgisi almalısınız.
- API anahtarlarını her zaman gizli tutun ve asla istemci tarafında kaynak kodunda saklamayın. 