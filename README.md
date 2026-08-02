# 📖 Quote Reminder

<p align="center">
  <strong>Favori sözlerini kaydet, kategorilere ayır ve gün içerisinde bildirimlerle tekrar hatırla.</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart" />
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android" />
  <img alt="Database" src="https://img.shields.io/badge/Database-Isar-6E56CF?style=flat-square" />
  <img alt="Status" src="https://img.shields.io/badge/Status-Geliştiriliyor-orange?style=flat-square" />
</p>

<p align="center">
  <a href="#kurulum"><strong>Kurulum</strong></a>
  ·
  <a href="#proje-amaci"><strong>Proje Amacı</strong></a>
  ·
  <a href="#mimari"><strong>Mimari</strong></a>
  ·
  <a href="#yol-haritasi"><strong>Yol Haritası</strong></a>
</p>

---

<div align="center">

# İçindekiler

| # | Bölüm | Açıklama |
|:-:|:------|:---------|
| **1** | Kurulum | Flutter kurulumu ve projeyi çalıştırma |
| **2** | Proje Amacı | Uygulamanın amacı ve kapsamı |
| **3** | Özellikler | Mevcut ve planlanan özellikler |
| **4** | Teknolojiler | Kullanılan teknolojiler |
| **5** | Mimari | Katman yapısı |
| **6** | Klasör Yapısı | Flutter klasör organizasyonu |
| **7** | Veri Modeli | Quote modeli |
| **8** | Bildirim Sistemi | Local Notification mantığı |
| **9** | Yol Haritası | Geliştirme planı |
| **10** | Katkı | Git stratejisi |

</div>

---

# 🚀 1. Kurulum

## Gereksinimler

- Flutter SDK
- Dart SDK
- Android Studio
- Android SDK
- VS Code
- Flutter Extension

Flutter sürümünü kontrol edin.

```bash
flutter --version
```

---

## Projeyi Klonlayın

```bash
git clone https://github.com/kullaniciadi/quote-reminder.git

cd be_yourself
```

---

## Paketleri Yükleyin

```bash
flutter pub get
```

---

## Uygulamayı Çalıştırın

```bash
flutter run
```

---

# 🎯 2. Proje Amacı

Quote Reminder, sosyal medya platformlarında kaydedilen motivasyon, psikoloji, kişisel gelişim, kitap ve şarkı sözlerini düzenli olarak hatırlatmayı amaçlayan bir Flutter mobil uygulamasıdır.

Uygulama internet bağlantısına ihtiyaç duymadan tamamen yerel (offline) çalışmaktadır.

Temel hedefler:

- Favori sözleri tek yerde toplamak
- Gün içerisinde otomatik bildirim almak
- Kategorilere göre filtreleme yapmak
- Basit ve modern kullanıcı deneyimi sunmak

---

# ✨ 3. Özellikler

## Mevcut

- [ ] Söz ekleme
- [ ] Söz düzenleme
- [ ] Söz silme
- [ ] Favorilere ekleme
- [ ] Kategori oluşturma
- [ ] Yerel bildirim
- [ ] Offline çalışma

---

## Planlanan

- [ ] Arama
- [ ] Filtreleme
- [ ] Rastgele söz
- [ ] Dark Mode
- [ ] İstatistikler
- [ ] Widget desteği
- [ ] AI ile yeni söz üretme

---

# 🛠️ 4. Kullanılan Teknolojiler

| Teknoloji | Amaç |
|-----------|------|
| Flutter | Mobil uygulama geliştirme |
| Dart | Programlama dili |
| Isar | Yerel veritabanı |
| Riverpod | State Management |
| flutter_local_notifications | Bildirim sistemi |
| go_router | Sayfa geçişleri |

---

# 🏗️ 5. Mimari

Proje Feature Based Architecture yapısına göre geliştirilmektedir.

```
Presentation

↓

Application

↓

Data

↓

Local Database
```

İlerleyen sürümlerde Clean Architecture yapısına dönüştürülebilecek şekilde geliştirilecektir.

---

# 📂 6. Klasör Yapısı

```
lib/

core/
│
├── constants/
├── theme/
├── services/
└── utils/

features/

home/

quote/

settings/

favorites/

notifications/

shared/

main.dart
```

---

# 🗄️ 7. Veri Modeli

## Quote

| Alan | Açıklama |
|------|----------|
| id | Benzersiz ID |
| text | Söz |
| author | Yazarı |
| category | Kategori |
| isFavorite | Favori mi |
| createdDate | Oluşturulma tarihi |

---

# 🔔 8. Bildirim Sistemi

Bildirimler cihaz üzerinde çalışmaktadır.

Sunucu kullanılmamaktadır.

Bildirim mantığı:

```
Quote

↓

Local Database

↓

Notification Scheduler

↓

Android Notification
```

Kullanıcı;

- Bildirim saatini belirleyebilir.
- Günlük bildirim sayısını seçebilir.
- Hangi kategorilerden bildirim almak istediğini belirleyebilir.

---

# 🗺️ 9. Yol Haritası

## Versiyon 1.0

- Ana Sayfa
- CRUD işlemleri
- Kategoriler
- Local Notification

---

## Versiyon 1.1

- Favoriler
- Arama
- Filtreleme
- Dark Mode

---

## Versiyon 2.0

- Cloud Sync
- Kullanıcı hesabı
- ASP.NET Core Backend
- PostgreSQL
- Çoklu cihaz desteği

---

# 🤝 10. Katkı Kuralları

Dal yapısı

```
main

develop

feature/*
```

Commit örnekleri

```
feat: quote ekleme ekranı

fix: notification bug

refactor: repository düzenlemesi

docs: README güncellendi
```

---

<div align="center">

## 👨‍💻 Geliştirici

**Zehra Tuncer**

Bilgisayar Mühendisliği Öğrencisi

Flutter • Mobile Development • AI Applications

---

⭐ Eğer projeyi beğendiysen yıldız vermeyi unutma.

</div>
