# Ev Bütçem

Kişisel ve aile bütçe takip uygulaması.

## Özellikler (MVP)

- Genel Bakış ekranı (Gelir, Gider, Net, Kart borcu, Yaklaşan ödemeler)
- Gelir / Gider ekleme altyapısı
- Banka hesapları ve Kredi kartları
- Taksit takibi
- Açık / Koyu tema
- Offline çalışma (Hive)

## Kurulum

1. Flutter SDK'nın yüklü olduğundan emin ol (3.16+)
2. Projeyi klonla / indir
3. Terminalde proje klasörüne gir:

```bash
cd ev_butcem
flutter pub get
```

4. (İsteğe bağlı) Hive adapter'ları yeniden üretmek istersen:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Çalıştır:

```bash
flutter run
```

## Proje Yapısı

```
lib/
├── models/          # Veri modelleri (Category, Transaction, Account, CreditCard, Installment)
├── screens/         # Ekranlar
├── widgets/         # Ortak bileşenler
├── theme/           # Tema ayarları
├── utils/           # Yardımcı dosyalar
└── main.dart
```

## Sonraki Adımlar

- [x] Riverpod ile state management (işlemler)
- [x] Gerçek veri bağlama (Hive CRUD, işlemler)
- [x] Gelir/Gider ekleme formu
- [ ] Hesap ve kart ekleme formları
- [ ] Taksit ekranı
- [ ] Raporlar

---

Geliştirme: Ev Bütçem Ekibi
