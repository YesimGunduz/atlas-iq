/// Uygulamadaki bütün kullanıcıya görünen metinler.
///
/// Soyut sınıf + her dil için bir uygulama şeklinde yazıldı; harita
/// kullanmadık çünkü böylece **derleyici** iki dilin de eksiksiz olduğunu
/// kontrol ediyor. Yeni bir metin eklediğinde hem [TrStrings] hem
/// [EnStrings] onu tanımlamak zorunda, yoksa derlenmiyor.
abstract class AppStrings {
  // ----- Genel -----
  String get languageName;
  String get tryAgain;
  String get clear;
  String get apply;
  String get search;

  // ----- Üst bar -----
  String get welcomeBack;
  String get play;

  // ----- Alt menü -----
  String get navHome;
  String get navSaved;

  // ----- Açılış -----
  String get splashTagline;
  String get splashLoading;

  // ----- Ana sayfa -----
  List<String> get searchHints;
  String get heroTitle;
  String get heroSubtitle;
  String get statCountries;
  String get statVisaRules;
  String get statLanguages;
  String get statData;
  String get statDataLive;
  String get travelTitle;
  String get travelSubtitle;
  String get travelAction;
  String get clearSearch;
  String noSearchMatch(String query);

  // ----- Boş / hata durumları -----
  String get emptyListTitle;
  String get emptyListDetail;
  String emptyFilteredSearch(String query);
  String emptySearchTitle(String query);
  String get emptySearchDetail;
  String emptyFilterDetail(int loaded);
  String get emptyFilterNoMatch;
  String get clearFilter;
  String get loadFailed;
  String get demoKeyWarning;

  // ----- Veri bilgisi -----
  String cacheNotice(String age);
  String minutesAgo(int minutes);
  String hoursAgo(int hours);
  String daysAgo(int days);
  String loadedOf(int loaded, int total);
  String loadedCount(int loaded);
  String get demoNoticeDetail;
  String get incompleteNoticeDetail;

  // ----- Filtre -----
  String get filterTitle;
  String get filterEntryType;
  String get filterVisaType;

  // ----- Kaydedilenler -----
  String get savedTitle;
  String get savedEmptyTitle;
  String get savedEmptyDetail;
  String get savedEmptyAction;
  String savedCount(int count);
  String get saveTooltip;
  String get unsaveTooltip;
  String savedToast(String country);
  String get unsavedToast;

  // ----- Detay -----
  String get visaStatus;
  String get visaUnknown;
  String get visaUnknownDetail;
  String get rowTimeDiff;
  String get rowCapital;
  String get rowRegion;
  String get rowPopulation;
  String get rowLanguages;
  String get rowCurrency;
  String get rowExchange;
  String get rowTimezone;
  String get rateLoading;
  String get rateFailed;
  String get turkeyLabel;
  String get sameTime;
  String hoursAhead(String duration);
  String hoursBehind(String duration);
  String durationHours(int hours);
  String durationHoursMinutes(int hours, int minutes);
  String notFound(String query);
  String get notFoundHint;
  String get detailLoadFailed;
  String forPassport(String passport);
  String flagAlt(String country, String description);

  // ----- Oyun -----
  String get gameTitle;
  String questionOf(int current, int total);
  String get levelEasy;
  String get levelMedium;
  String get levelHard;
  String get points;
  String get whichCountry;
  String get gameStartFailed;
  String get gameDemoWarning;
  String scoreOf(int score, int max);
  String correctOf(int correct, int total);
  String get resultPerfect;
  String get resultGood;
  String get resultOk;
  String get resultPoor;
  String get newRecord;
  String get longestStreak;
  String get record;
  String get playAgain;
  String get backHome;

  // ----- Veri değerleri -----
  String visaLabel(String? value);
  String entryLabel(String? value);
  String regionLabel(String? value);
}

// ===================================================================
class TrStrings implements AppStrings {
  const TrStrings();

  @override String get languageName => "Türkçe";
  @override String get tryAgain => "Tekrar dene";
  @override String get clear => "Temizle";
  @override String get apply => "Uygula";
  @override String get search => "Ülke ara";

  @override String get welcomeBack => "HOŞ GELDİN";
  @override String get play => "Oyna";

  @override String get navHome => "Ana sayfa";
  @override String get navSaved => "Kaydedilenler";

  @override String get splashTagline =>
      "Ülkeleri, bayrakları ve güncel bilgileri tek yerde keşfet";
  @override String get splashLoading => "Dünya verileri yükleniyor...";

  @override List<String> get searchHints => const [
        "Ülke ya da bayrak ara...",
        "Ülkeleri anlık olarak keşfet",
        "İstediğin ülkeyi hemen bul",
        "Güncel ülke bilgileri",
      ];
  @override String get heroTitle => "Dünyayı Keşfet";
  @override String get heroSubtitle =>
      "Ülkeler, bayraklar ve diller — güncel verilerle";
  @override String get statCountries => "Ülke";
  @override String get statVisaRules => "Vize kaydı";
  @override String get statLanguages => "Dil";
  @override String get statData => "Veri";
  @override String get statDataLive => "GÜNCEL";
  @override String get travelTitle => "Seyahat Modu";
  @override String get travelSubtitle =>
      "Vize, pasaport ve kimlik kurallarına bak";
  @override String get travelAction => "Kuralları gör";
  @override String get clearSearch => "Aramayı temizle";
  @override String noSearchMatch(String q) => "\"$q\" ile eşleşen ülke yok";

  @override String get emptyListTitle => "Ülke listesi boş";
  @override String get emptyListDetail =>
      "Veri yüklenemedi. Aşağıdan tekrar deneyebilirsin.";
  @override String emptyFilteredSearch(String q) =>
      "\"$q\" bu filtrelerle bulunamadı";
  @override String emptySearchTitle(String q) => "\"$q\" ile eşleşen ülke yok";
  @override String get emptySearchDetail =>
      "Türkçe adıyla da arayabilirsin (almanya, abd, ingiltere).";
  @override String emptyFilterDetail(int loaded) =>
      "$loaded ülke yüklü, filtreye uyan yok.";
  @override String get emptyFilterNoMatch => "kayıtlı ülke yok";
  @override String get clearFilter => "Filtreyi temizle";
  @override String get loadFailed => "Veriler alınamadı";
  @override String get demoKeyWarning =>
      "Şu an demo API anahtarı kullanılıyor.\n"
      "restcountries.com'dan ücretsiz anahtar alıp env.json dosyasına yaz.";

  @override String cacheNotice(String age) =>
      "Kayıtlı veriden açıldı$age · arka planda güncelleniyor";
  @override String minutesAgo(int m) => " · $m dk önce";
  @override String hoursAgo(int h) => " · $h saat önce";
  @override String daysAgo(int d) => " · $d gün önce";
  @override String loadedOf(int l, int t) => "$l / $t ülke yüklendi";
  @override String loadedCount(int l) => "$l ülke yüklendi";
  @override String get demoNoticeDetail =>
      "Demo anahtarı sadece tek bir ülke döndürüyor. Tam liste için "
      "restcountries.com'dan ücretsiz anahtar al ve env.json dosyasına yaz.";
  @override String get incompleteNoticeDetail =>
      "API tam listeyi döndürmedi. Yenilemek için uygulamayı yeniden "
      "başlatabilirsin.";

  @override String get filterTitle => "Ülkeleri Filtrele";
  @override String get filterEntryType => "Giriş belgesi";
  @override String get filterVisaType => "Vize türü";

  @override String get savedTitle => "Kaydedilenler";
  @override String get savedEmptyTitle => "Henüz kayıtlı ülke yok";
  @override String get savedEmptyDetail =>
      "Bir ülkenin sayfasını açıp sağ üstteki yıldıza dokunarak buraya "
      "ekleyebilirsin.";
  @override String get savedEmptyAction => "Ülke ara";
  @override String savedCount(int c) => "$c ülke kayıtlı";
  @override String get saveTooltip => "Kaydet";
  @override String get unsaveTooltip => "Kaydedilenlerden çıkar";
  @override String savedToast(String c) => "$c kaydedildi";
  @override String get unsavedToast => "kaydedilenlerden çıkarıldı";

  @override String get visaStatus => "VİZE DURUMU";
  @override String get visaUnknown => "Kayıt yok";
  @override String get visaUnknownDetail => "Bu ülke vize veri dosyasında yok.";
  @override String get rowTimeDiff => "Saat farkı";
  @override String get rowCapital => "Başkent";
  @override String get rowRegion => "Bölge";
  @override String get rowPopulation => "Nüfus";
  @override String get rowLanguages => "Diller";
  @override String get rowCurrency => "Para birimi";
  @override String get rowExchange => "TL karşılığı";
  @override String get rowTimezone => "Saat dilimi";
  @override String get rateLoading => "hesaplanıyor...";
  @override String get rateFailed => "kur alınamadı";
  @override String get turkeyLabel => "TÜRKİYE";
  @override String get sameTime => "Türkiye ile aynı saat";
  @override String hoursAhead(String d) => "$d ileri";
  @override String hoursBehind(String d) => "$d geri";
  @override String durationHours(int h) => "$h saat";
  @override String durationHoursMinutes(int h, int m) => "$h saat $m dakika";
  @override String notFound(String q) => "\"$q\" bulunamadı.";
  @override String get notFoundHint =>
      "Ülke adını İngilizce yazmayı dene (ör. Germany).";
  @override String get detailLoadFailed =>
      "Bilgiler alınamadı. Bağlantını kontrol et.";
  @override String forPassport(String p) => "$p için.";
  @override String flagAlt(String c, String d) =>
      d.isEmpty ? "$c bayrağı" : "$c bayrağı: $d";

  @override String get gameTitle => "Bayrak Oyunu";
  @override String questionOf(int c, int t) => "Soru $c / $t";
  @override String get levelEasy => "Kolay";
  @override String get levelMedium => "Orta";
  @override String get levelHard => "Zor";
  @override String get points => "puan";
  @override String get whichCountry => "Bu bayrak hangi ülkeye ait?";
  @override String get gameStartFailed => "Oyun başlatılamadı";
  @override String get gameDemoWarning =>
      "Demo API anahtarı yalnızca 1 ülke döndürüyor.\n"
      "Oyun için en az 4 ülke gerekiyor.\n\n"
      "restcountries.com'dan ücretsiz anahtar alıp env.json dosyasına yaz.";
  @override String scoreOf(int s, int m) => "$s / $m puan";
  @override String correctOf(int c, int t) => "$c / $t doğru";
  @override String get resultPerfect => "Kusursuz! Zor soruları da bildin.";
  @override String get resultGood => "İyi iş, coğrafyan sağlam.";
  @override String get resultOk => "Fena değil, zor sorular biraz zorladı.";
  @override String get resultPoor => "Bayraklara biraz daha bakmak lazım.";
  @override String get newRecord => "Yeni rekor!";
  @override String get longestStreak => "En uzun seri";
  @override String get record => "Rekor";
  @override String get playAgain => "Tekrar oyna";
  @override String get backHome => "Ana sayfaya dön";

  @override String visaLabel(String? v) => switch (v) {
        "Visa Free" => "Vizesiz",
        "E-Visa" => "e-Vize",
        "Visa On Arrival" => "Kapıda vize",
        "Visa Required" => "Vize gerekli",
        _ => v ?? "-",
      };
  @override String entryLabel(String? v) => switch (v) {
        "Passport Required" => "Pasaport gerekli",
        "ID Only" => "Kimlikle giriş",
        _ => v ?? "-",
      };
  @override String regionLabel(String? v) => switch (v) {
        "Europe" => "Avrupa",
        "Asia" => "Asya",
        "Africa" => "Afrika",
        "Americas" => "Amerika",
        "Oceania" => "Okyanusya",
        "Antarctic" => "Antarktika",
        _ => (v == null || v.isEmpty) ? "-" : v,
      };
}

// ===================================================================
class EnStrings implements AppStrings {
  const EnStrings();

  @override String get languageName => "English";
  @override String get tryAgain => "Try again";
  @override String get clear => "Clear";
  @override String get apply => "Apply";
  @override String get search => "Search countries";

  @override String get welcomeBack => "WELCOME BACK";
  @override String get play => "Play";

  @override String get navHome => "Home";
  @override String get navSaved => "Saved";

  @override String get splashTagline =>
      "Explore countries, flags and live facts in one place";
  @override String get splashLoading => "Loading world data...";

  @override List<String> get searchHints => const [
        "Search a country or flag...",
        "Explore countries in real time",
        "Find any country instantly",
        "Live country data",
      ];
  @override String get heroTitle => "Explore The World";
  @override String get heroSubtitle =>
      "Countries, flags and languages — with live data";
  @override String get statCountries => "Countries";
  @override String get statVisaRules => "Visa rules";
  @override String get statLanguages => "Languages";
  @override String get statData => "Data";
  @override String get statDataLive => "LIVE";
  @override String get travelTitle => "Travel Mode";
  @override String get travelSubtitle =>
      "Check visa, passport and ID rules";
  @override String get travelAction => "See rules";
  @override String get clearSearch => "Clear search";
  @override String noSearchMatch(String q) => "No country matches \"$q\"";

  @override String get emptyListTitle => "No countries loaded";
  @override String get emptyListDetail =>
      "The data couldn't be loaded. You can try again below.";
  @override String emptyFilteredSearch(String q) =>
      "\"$q\" not found with these filters";
  @override String emptySearchTitle(String q) => "No country matches \"$q\"";
  @override String get emptySearchDetail =>
      "You can also search in Turkish (almanya, abd, ingiltere).";
  @override String emptyFilterDetail(int loaded) =>
      "$loaded countries loaded, none match the filter.";
  @override String get emptyFilterNoMatch => "no countries recorded";
  @override String get clearFilter => "Clear filter";
  @override String get loadFailed => "Couldn't load data";
  @override String get demoKeyWarning =>
      "The demo API key is in use.\n"
      "Get a free key from restcountries.com and put it in env.json.";

  @override String cacheNotice(String age) =>
      "Loaded from saved data$age · refreshing in the background";
  @override String minutesAgo(int m) => " · $m min ago";
  @override String hoursAgo(int h) => " · $h h ago";
  @override String daysAgo(int d) => " · $d days ago";
  @override String loadedOf(int l, int t) => "$l / $t countries loaded";
  @override String loadedCount(int l) => "$l countries loaded";
  @override String get demoNoticeDetail =>
      "The demo key returns a single country. For the full list, get a free "
      "key from restcountries.com and put it in env.json.";
  @override String get incompleteNoticeDetail =>
      "The API didn't return the full list. Restart the app to refresh.";

  @override String get filterTitle => "Filter Countries";
  @override String get filterEntryType => "Entry document";
  @override String get filterVisaType => "Visa type";

  @override String get savedTitle => "Saved";
  @override String get savedEmptyTitle => "No saved countries yet";
  @override String get savedEmptyDetail =>
      "Open a country page and tap the star in the top right to add it here.";
  @override String get savedEmptyAction => "Search countries";
  @override String savedCount(int c) => "$c countries saved";
  @override String get saveTooltip => "Save";
  @override String get unsaveTooltip => "Remove from saved";
  @override String savedToast(String c) => "$c saved";
  @override String get unsavedToast => "removed from saved";

  @override String get visaStatus => "VISA STATUS";
  @override String get visaUnknown => "No record";
  @override String get visaUnknownDetail =>
      "This country isn't in the visa data file.";
  @override String get rowTimeDiff => "Time difference";
  @override String get rowCapital => "Capital";
  @override String get rowRegion => "Region";
  @override String get rowPopulation => "Population";
  @override String get rowLanguages => "Languages";
  @override String get rowCurrency => "Currency";
  @override String get rowExchange => "In Turkish lira";
  @override String get rowTimezone => "Time zone";
  @override String get rateLoading => "calculating...";
  @override String get rateFailed => "rate unavailable";
  @override String get turkeyLabel => "TÜRKİYE";
  @override String get sameTime => "Same time as Türkiye";
  @override String hoursAhead(String d) => "$d ahead";
  @override String hoursBehind(String d) => "$d behind";
  @override String durationHours(int h) => "$h h";
  @override String durationHoursMinutes(int h, int m) => "$h h $m min";
  @override String notFound(String q) => "\"$q\" not found.";
  @override String get notFoundHint =>
      "Try the English name (e.g. Germany).";
  @override String get detailLoadFailed =>
      "Couldn't load the details. Check your connection.";
  @override String forPassport(String p) => "For $p.";
  @override String flagAlt(String c, String d) =>
      d.isEmpty ? "Flag of $c" : "Flag of $c: $d";

  @override String get gameTitle => "Flag Quiz";
  @override String questionOf(int c, int t) => "Question $c / $t";
  @override String get levelEasy => "Easy";
  @override String get levelMedium => "Medium";
  @override String get levelHard => "Hard";
  @override String get points => "points";
  @override String get whichCountry => "Which country does this flag belong to?";
  @override String get gameStartFailed => "Couldn't start the quiz";
  @override String get gameDemoWarning =>
      "The demo API key returns only 1 country.\n"
      "The quiz needs at least 4.\n\n"
      "Get a free key from restcountries.com and put it in env.json.";
  @override String scoreOf(int s, int m) => "$s / $m points";
  @override String correctOf(int c, int t) => "$c / $t correct";
  @override String get resultPerfect => "Flawless! Even the hard ones.";
  @override String get resultGood => "Nice work, solid geography.";
  @override String get resultOk => "Not bad, the hard ones got you.";
  @override String get resultPoor => "Time to look at a few more flags.";
  @override String get newRecord => "New record!";
  @override String get longestStreak => "Longest streak";
  @override String get record => "Record";
  @override String get playAgain => "Play again";
  @override String get backHome => "Back to home";

  @override String visaLabel(String? v) => v ?? "-";
  @override String entryLabel(String? v) => v ?? "-";
  @override String regionLabel(String? v) =>
      (v == null || v.isEmpty) ? "-" : v;
}
