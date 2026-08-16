<div align="center">

# ✨ BeYourself (ComeBack Project)

**Kişisel İlham, Alıntı Defteri, Instagram Medya Entegrasyonu ve Akıllı Bildirim Uygulaması**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.5-00D2B4?style=for-the-badge&logo=flutter&logoColor=white)](https://riverpod.dev)
[![Tests](https://img.shields.io/badge/Unit%20Tests-50%2F50%20Passed-success?style=for-the-badge&logo=checkmarx&logoColor=white)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-brightgreen?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)]()

<p align="center">
  <em>"Kendine inan, yapabileceklerinin sınırı yoktur."</em>
</p>

</div>

---

## 📱 Proje Hakkında

**BeYourself**, sosyal medyada (özellikle Instagram) gördüğünüz ilham verici sözleri, Reels videolarını ve galeri gönderilerini kolayca kaydedebileceğiniz, kategorilere ayırabileceğiniz, gün içerisinde motive edici yerel bildirimler alabileceğiniz ve telefonunuzun ana ekranında canlı widget ile takip edebileceğiniz modern bir Flutter uygulamasıdır.

Kullanıcı verileri ağırlıklı olarak cihazınızda (Local-First) tutulurken, gelişmiş kullanıcı profiliniz Supabase bulut veritabanı sayesinde cihazlar arası güvenle senkronize edilir. Web ve iOS platformlarındaki kısıtlamalar ise özel Vercel altyapısıyla aşılmıştır.

---

## 🚀 Öne Çıkan ve Aktif Olarak Kullanılan Özellikler

### 1. 🎬 Instagram Entegrasyonu (Reels & Çoklu Fotoğraf / Carousel)
- **Instagram URL ile Medya İndirme:** Reels videoları ve 10 fotoğrafa kadar olan carousel/post gönderileri tek tıkla cihaza indirilir.
- **Vercel Serverless & CORS Çözümü:** Web ve iOS ortamlarındaki medya engellemelerini (CORS) aşmak için Vercel üzerinde koşan özel sunucusuz (serverless) proxy API'ler entegre edilmiştir.
- **Otomatik Açıklama (Caption) & Akıllı Başlık:** Gönderi açıklaması alıntı metnine otomatik aktarılır, ilk cümleden vurucu bir kısa başlık (`shortText`) üretilir ve yazar adı Instagram profilinden çekilir.
- **Dahili Video Oynatıcı & Kaydırılabilir Galeri:** Alıntı detayında tam ekran Reels video oynatıcı ve çoklu fotoğraflar için sağa-sola kaydırılabilir galeri (`PageView`) bulunur.
- **Gelişmiş Tam Ekran Zoom (Pinch-to-Zoom):** Büyütülen fotoğraflarda parmakla kaydırarak sonraki görsellere geçiş yapılabilir.

### 2. 📲 Ana Ekran (Home Screen) Widget'ı
- **Android Home Widget:** Günün sözü Android ana ekranında zarif bir kart olarak görüntülenir.
- **Akıllı Senkronizasyon:** Uygulama içinden alıntı silindiğinde veya güncellendiğinde widget otomatik olarak fallback sözüne veya havuzdaki yeni bir söze güncellenir.
- **Derin Bağlantı (Deep Link):** Widget'a tıklandığında doğrudan o alıntının detay sayfasına yönlendirir.

### 3. ⏰ Akıllı Yerel Bildirimler (Local Notifications)
- **Kişiselleştirilebilir Zamanlama:** Günde 1 ile 5 arasında bildirim sıklığı ve özel saat seçimi (örn: 09:00, 14:00, 21:00).
- **Kategori Filtreli Bildirim:** Sadece seçtiğiniz kategorilerden (Motivasyon, Felsefe vb.) ilham alma imkanı.
- **Arka Planda Senkron:** Alıntı silindiğinde veya eklendiğinde bekleyen bildirimler anında yeniden senkronize edilir.
- **Bildirime Tıklama Desteği:** Bildirime tıklandığında uygulama açılır ve doğrudan ilgili alıntı kartına gider.

### 4. 👤 Gelişmiş Profil Yönetimi & Kişiselleştirme
- **İsim & Soyisim Düzenleme:** Dinamik kullanıcı profili yönetimi.
- **Bulut Senkronizasyonu (Supabase):** Kullanıcı profilleri Supabase veritabanı ile eşzamanlı çalışarak verilerinizin bulutta da güvenle yedeklenmesini sağlar.
- **Avatar & Fotoğraf Seçici:** Galeriden profil resmi yükleme veya 16 farklı hazır ilham avatarı (🌟, 🦋, 🌸, 🚀, vb.) seçme.
- **Kişisel İlham Mottosu:** Kullanıcının kendine hatırlatmak istediği yaşam felsefesi.
- **Bildirim Hitap Tercihi:** *Samimi* ("Günaydın Zehra ✨"), *Motive Edici* ("Bugün senin günün Zehra 🚀") veya *Sade* bildirim stilleri.
- **Canlı İstatistikler:** Toplam kaydedilen alıntı ve favori sayıları.

### 5. 🎲 Rastgele İlham Çarkı (Random Quote)
- Kategoriye göre filtrelenebilir rastgele alıntı getirme.
- Haptic Feedback (dokunsal titreşim) ve akıcı kart animasyonları.
- Son 5 alıntıyı hatırlayan geçmiş buffer'ı ile art arda aynı sözün gelmesi engellenir.

### 6. 🗂️ Dinamik Kategori & Favori Yönetimi
- Otomatik akıllı kategori ikonları (`CategoryIconHelper`).
- Yeni kategori ekleme, düzenleme ve silme (silinen kategorideki alıntılar güvenle "Genel" kategorisine aktarılır).
- Tek dokunuşla favorilere ekleme ve favori listesi.

### 7. 🌗 Modern Tasarım Sistemi (Dark & Light Mode)
- Özel renk paleti (`AppColors`) ve Glassmorphism cam efektleri.
- Koyu mod ve açık mod arasında anlık geçiş ve tercihlerin kalıcı saklanması.

---

## 🛠️ Teknoloji Yığını & Mimari

| Katman | Teknoloji / Kütüphane | Açıklama |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x & Dart 3.x | Çoklu platform (Android, iOS, Web) |
| **State Management** | Flutter Riverpod 2.5.x | Reaktif ve test edilebilir durum yönetimi |
| **Bulut Veritabanı** | Supabase | Kullanıcı profili bulut senkronizasyonu |
| **Sunucu / API** | Vercel Serverless | Instagram Medya Çözümleme ve CORS Proxy (`api/`) |
| **Yerel Depolama** | SharedPreferences | Local-First hızlı veri kalıcılığı (JSON serileştirme) |
| **Bildirimler** | `flutter_local_notifications` + `timezone` | Zamanlanmış çevrimdışı bildirimler |
| **Ana Ekran Widget** | `home_widget` | Android & iOS WidgetKit / AppWidgetProvider |
| **Medya & Video** | `video_player` + `image_picker` + `http` | Reels oynatıcı ve Instagram medya ayrıştırıcı |
| **Yazı Tipleri** | `google_fonts` (Outfit, Plus Jakarta Sans) | Tipografi ve modern UI |

---

## 🧪 Test Kapsamı (%100 Başarı)

Projede toplam **50 adet otomatik birim (unit) ve widget testi** bulunmaktadır:

```bash
flutter test
```

- ✅ `instagram_downloader_test.dart`: URL doğrulama, regex, shortcode ve Carousel modelleri.
- ✅ `notification_service_test.dart`: Bildirim planlama ve silme senkronizasyonu.
- ✅ `home_widget_service_test.dart`: Widget URI ayrıştırma, veri güncelleme ve fallback mekanizması.
- ✅ `profile_test.dart`: Profil modeli serileştirme, avatar ve motto güncellemeleri.
- ✅ `category_test.dart`: Kategori iş mantığı, büyük/küçük harf mükerrer engelleme ve ikon eşleştirmeleri.
- ✅ `quote_providers_test.dart`: Favori toggle, kategori taşıma, arama/filtreleme ve Günün Sözü önbelleği.
- ✅ `settings_and_navigation_test.dart`: Koyu mod ve alt sekme navigasyon testleri.
- ✅ `random_quote_test.dart`: Rastgele alıntı çekme ve geçmiş buffer hafızası.
- ✅ `persistence_test.dart`: SharedPreferences veri kalıcılığı testleri.

---

## 📂 Proje Klasör Yapısı

```
lib/
├── core/
│   ├── constants/       # Uygulama sabitleri ve metinleri
│   ├── theme/           # AppColors ve AppTheme (Dark & Light)
│   └── utils/           # CategoryIconHelper ve yardımcı araçlar
├── features/
│   ├── category/        # Kategori CRUD ve sağlayıcıları
│   ├── favorites/       # Favori alıntılar ekranı
│   ├── home/            # Ana sayfa ve alıntı kartları
│   ├── home_widget/     # Android/iOS Widget servisi
│   ├── media/           # Instagram Reels/Post indirici servisi
│   ├── notifications/   # Zamanlanmış yerel bildirim sistemi
│   ├── onboarding/      # Karşılama (Splash) ekranı
│   ├── profile/         # Profil ayarları, avatar ve motto yönetimi
│   ├── quote/           # Alıntı ekleme, düzenleme, detay ve filtreleme
│   └── settings/        # Ayarlar ve tema tercihleri
└── shared/
    ├── providers/       # Navigasyon sağlayıcısı
    └── widgets/         # AppVideoPlayer, MainShellPage
```

---

## 💻 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK (3.22 veya üzeri)
- Android Studio / VS Code
- Android Cihaz veya Emülatör

```bash
# 1. Projeyi klonlayın
git clone https://github.com/zehratuncer/ComeBack-Project.git

# 2. Proje dizinine gidin
cd ComeBack-Project/be_yourself

# 3. Bağımlılıkları yükleyin
flutter pub get

# 4. Testleri çalıştırın
flutter test

# 5. Uygulamayı başlatın
flutter run
```

---

## 📄 Lisans
Bu proje MIT Lisansı ile lisanslanmıştır.

<div align="center">
  <sub>Geliştirici: <strong>Zehra Tuncer</strong> • ComeBack Project</sub>
</div>
