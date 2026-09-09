# AtlasIQ

Ülke bilgilerini canlı veriyle gösteren, Türk pasaportu için vize kurallarını
da içeren bir Flutter uygulaması.

- **Ülke listesi ve arama** — 249 ülke, Türkçe adlarla da aranabiliyor
  ("almanya" yazınca Germany bulunuyor)
- **Detay sayfası** — başkent, nüfus, diller, para birimi ve **canlı TL kuru**,
  Türkiye ile saat farkı, iki şehrin saatini yan yana gösteren canlı saat
- **Vize filtresi** — 145 ülke için vize türü ve giriş belgesi
- **Kaydedilenler** — yıldızladığın ülkeler cihazda kalıcı
- **Bayrak oyunu** — kolaydan zora üç kademe; zor seviyede şıklar aynı
  bölgeden ve benzer bayrak renklerinden seçiliyor
- **Çevrimdışı çalışır** — liste diske yazılıyor, internet yokken de açılıyor

## Kurulum

### 1. API anahtarı al

Uygulama [REST Countries](https://restcountries.com) **v5** API'sini kullanıyor
ve bu sürüm anahtar istiyor. Ücretsiz:

1. <https://restcountries.com/sign-up> adresinden hesap aç
2. API anahtarını kopyala

> **Anahtarsız çalışmaz.** Anahtar vermezsen dokümandaki demo anahtarı devreye
> girer, o da yalnızca **tek bir ülke** (Kanada) döndürür — liste boş görünür ve
> bayrak oyunu 4 şık üretemediği için başlamaz.

### 2. Çalıştır

Anahtarı bir dosyaya koy — hem terminal hem IDE oradan okusun:

```bash
cp env.example.json env.json     # sonra env.json'u acip anahtarini yaz
flutter pub get
flutter run --dart-define-from-file=env.json
```

`env.json` `.gitignore`'da, yani anahtarın git'e sızmaz.

VS Code / Android Studio kullanıyorsan yeşil ▶ düğmesi de aynı dosyayı
okuyor (`.vscode/launch.json` hazır). **Düz `flutter run` çalıştırma** —
anahtar geçmez ve uygulama demo anahtarına düşer.

> Not: `--dart-define` anahtarı kaynak koddan çıkarır ama derlenmiş uygulamanın
> içinde metin olarak kalır. Ücretsiz bir anahtar için sorun değil; ücretli bir
> servise bağlanacaksan anahtarı kendi sunucunda tutman gerekir.

## Proje yapısı

```
lib/
├── data/
│   ├── country.dart          Country modeli; API ve önbellek okuması
│   ├── country_names_tr.dart Türkçe ülke adı eşlemesi
│   ├── labels.dart           İngilizce veri değerlerinin Türkçe karşılıkları
│   └── saved_data.dart       Kaydedilen ülkeler (shared_preferences)
├── services/
│   ├── country_services.dart REST Countries v5 istemcisi
│   ├── country_cache.dart    Çevrimdışı önbellek
│   ├── visa_dataservice.dart Vize veri dosyasını okur
│   └── visa_engine.dart      Vize filtreleme
└── views/
    ├── pages/                splash, home, details, saved, game
    └── widgets/              header, footer, filter_sheet
```

Veri değerleri (`Visa Free`, `Passport Required`, `Europe` …) her yerde
İngilizce tutuluyor; çeviri yalnızca gösterim katmanında, `labels.dart`
üzerinden yapılıyor. İkinci bir dil eklemek o dosyaya bir harita eklemek demek.

## Test

```bash
flutter test
```

Saf fonksiyonlar test ediliyor: saat dilimi ayrıştırması (yarım saatlik
farklar dahil), v5 cevabının okunması, önbellek gidiş-dönüşü, vize filtresi.

## Veri kaynakları

| Veri | Kaynak |
|---|---|
| Ülke bilgileri | [REST Countries v5](https://restcountries.com) |
| Döviz kuru | [open.er-api.com](https://open.er-api.com) |
| Vize kuralları | `assets/data/countries_database.json` (yerel) |

### Vize verisi hakkında uyarı

`countries_database.json` **Türkiye Cumhuriyeti pasaportu** içindir ve
bilgilendirme amaçlıdır. Vize kuralları sık değişir, bazıları koşulludur.
**Seyahat etmeden önce ilgili ülkenin konsolosluğundan veya T.C. Dışişleri
Bakanlığı'ndan doğrulayın.** Dosya, hangi pasaport için olduğunu ve güncelleme
tarihini kendi içinde taşır.

## Bilinen eksikler

- Uygulama tek temada (koyu); renkler henüz merkezî bir tema dosyasında değil
- `home_page.dart` ve `game_page.dart` bölünmeyi hak edecek kadar büyük
- Vize verisi resmî bir kaynaktan doğrulanmadı
