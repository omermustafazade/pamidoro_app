# PamiDoro 🍅 | Core Features & Technical Architecture

PamiDoro, kullanıcıların odaklanma sürelerini optimize etmek, dikkat dağıtıcı unsurlardan uzaklaşmak ve görevlerini organize etmek için geliştirilmiş; Firebase altyapısı ile çalışan, Neo-Brutalist tasarım diline sahip modern bir odaklanma ve ajanda uygulamasıdır.

## 🚀 Kapsamlı Özellik Seti

### 1. Çoklu Odaklanma Modelleri
- **Geleneksel Pamidor (25/5):** Klasik pomodoro döngüsü.
- **Flowtime (Süresiz Akış):** Süre kısıtlaması olmadan, bozulana kadar odaklanma ve manuel mola yönetimi.
- **Bilişsel Odak Modları:** İnsan beyninin ultradiyen ritmine dayanan **90/30 Dengesi** ve **52/17 Bilimsel Kuralı**.
- **Alternatif Modlar:** İş ertelemeyi önlemek için **Mikro Adım (10/2)**, eğlence odaklı **Animedoro (40/20)** ve daha uzun oturumlar için **Uzun Pamidor (50/10)**.

### 2. Akıllı Ajanda ve Görev Yönetimi
- **Proje (Klasör) Bazlı Yönetim:** Görevleri farklı klasörler altında gruplandırma, klasörleri yeniden adlandırma veya kalıcı olarak silme/taşıma.
- **Gelişmiş Görev Kartları:** Alt görevler (Checklist) ekleme, görevleri pinleme (başa tutturma) ve tamamlama işlemleri.
- **Sürükle-Bırak (Drag & Drop):** Görevlerin öncelik sırasını manuel olarak kaydırarak belirleme ve bu sırayı buluta anlık kaydetme.

### 3. Analitik ve Gelişmiş İstatistikler (Dashboard)
- **Github Tarzı Heatmap Takvimi:** Kullanıcının son 30 günlük veya seçili aydaki odaklanma yoğunluğunu renk paleti ile (GridPainter) görselleştirme.
- **Verimlilik Dağılımı:** Haftanın günlerine göre odaklanma sürelerini gösteren dinamik Bar Chart.
- **Proje İstatistikleri:** Hangi projeye (klasöre) ne kadar zaman harcandığını ve hangi tekniklerin kullanıldığını hesaplayan detaylı alt ekranlar.

### 4. Zihinsel Hazırlık ve Atmosfer
- **Mindfulness (Zihinsel Isınma):** Odaklanma öncesi aktifleşen, animasyonlu ve büyüyen çember eşliğinde 5 saniyelik nefes egzersizi.
- **20-20-20 Kuralı:** Uzun süreli çalışmalarda göz sağlığını korumak için 20 dakikada bir ekrana gelen göz dinlendirme uyarıları.
- **Atmosfer Sesleri:** Odaklanmayı artırmak için entegre edilmiş yağmur, kafe, orman, ateş ve rüzgar (looping) arka plan sesleri.

### 5. Kesintisiz Misafir ve Üye Deneyimi (Auth Flow)
- **Kayıtsız Başlangıç:** Kullanıcıların uygulamayı test edebilmesi için 5 seanslık ücretsiz misafir (Anonymous) deneyimi.
- **Seamless Credential Linking:** Misafir kullanıcı kayıt olduğunda, eski verilerinin silinmesini önleyen ve mevcut misafir oturumuna E-Posta/Şifre kimliğini kalıcı olarak bağlayan akıllı geçiş mimarisi.
- **Gerçek Zamanlı Veri Doğrulama:** Kayıt esnasında Nickname (Kullanıcı adı) ve Telefon Numarası çakışmalarını anlık olarak veritabanından sorgulama.

---

## 🛠 Teknik Mimari ve Altyapı

PamiDoro, modern mobil geliştirme standartlarına (Dart Null-Safety) uygun, modüler ve yüksek performanslı bir yapıda inşa edilmiştir.

### Uygulama Çatısı & UI/UX
- **Framework:** Flutter (M4 Apple Silicon Native Support, iOS 15.0+ Deployment Target, UIScene Lifecycle uyumlu).
- **Tasarım Sistemi:** Özelleştirilmiş Neo-Brutalist tema (`AppColors`), yüksek kontrastlı border'lar, keskin gölgelendirmeler (BoxShadow) ve mikroskobik animasyonlar.
- **Custom Renderlama:** Standart widget'lar yerine, Heatmap (Aktivite takvimi), DashedRingPainter (Kesik çizgili zamanlayıcı) ve BreathingAnimation (Nefes alma) efektleri için **CustomPainter** ve **AnimatedBuilder** kullanımları.

### Veritabanı Mimarisi (Firebase Cloud Firestore)
- **NoSQL Veri Ağacı:** Kullanıcı bazlı izole edilmiş koleksiyon yapısı:
  - `users/{uid}/sessions`: Tamamlanan odaklanma seansları.
  - `users/{uid}/agendaTasks`: Klasör bazlı ajanda görevleri ve alt metrikler.
- **Güvenlik Kuralları (Security Rules):** 
  - Sadece kimliği doğrulanmış (Auth) ve hedef `uid` ile eşleşen kullanıcıların veri yazıp okumasına izin veren katı güvenlik kalkanı.
  - Sadece kayıt esnasında veri çakışmasını engellemek için `users` koleksiyonu kökünde izole edilmiş genel okuma kuralı.

### Cihaz ve Donanım Entegrasyonları
- **Local Notifications (`flutter_local_notifications`):** Uygulama arka planda (background/terminated) çalışırken, seans ve mola bitimlerinde yerel bildirimler (sesli ve görsel) gönderme.
- **Wakelock Plus (`wakelock_plus`):** Odaklanma sırasında kullanıcının isteğine bağlı olarak cihaz ekranının uykuya geçmesini (kararmasını) engelleme.
- **Audio Management (`audioplayers`):** Arkada planda asenkron olarak ortam seslerini (Ambient Sounds) kesintisiz döngüde (ReleaseMode.loop) çalma.
- **Haptic Engine (`HapticFeedback`):** Buton tıklamaları, drag & drop işlemleri ve seans bitişlerinde sisteme özgü hafif/ağır titreşim motoru entegrasyonu.
