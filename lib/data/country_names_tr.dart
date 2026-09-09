/// Türkçe ülke adları -> REST Countries'teki İngilizce karşılıkları.
///
/// Arama kutusuna "Almanya" yazınca da Germany bulunsun diye.
class CountryNamesTr {
  static const Map<String, String> trToEn = {
    "almanya": "Germany",
    "fransa": "France",
    "italya": "Italy",
    "ispanya": "Spain",
    "hollanda": "Netherlands",
    "belçika": "Belgium",
    "belcika": "Belgium",
    "avusturya": "Austria",
    "isviçre": "Switzerland",
    "isvicre": "Switzerland",
    "isveç": "Sweden",
    "isvec": "Sweden",
    "norveç": "Norway",
    "norvec": "Norway",
    "danimarka": "Denmark",
    "finlandiya": "Finland",
    "izlanda": "Iceland",
    "ingiltere": "United Kingdom",
    "birleşik krallık": "United Kingdom",
    "birlesik krallik": "United Kingdom",
    "irlanda": "Ireland",
    "portekiz": "Portugal",
    "yunanistan": "Greece",
    "polonya": "Poland",
    "çekya": "Czechia",
    "cekya": "Czechia",
    "çek cumhuriyeti": "Czechia",
    "macaristan": "Hungary",
    "romanya": "Romania",
    "bulgaristan": "Bulgaria",
    "hırvatistan": "Croatia",
    "hirvatistan": "Croatia",
    "sırbistan": "Serbia",
    "sirbistan": "Serbia",
    "arnavutluk": "Albania",
    "bosna hersek": "Bosnia and Herzegovina",
    "karadağ": "Montenegro",
    "karadag": "Montenegro",
    "kuzey makedonya": "North Macedonia",
    "slovenya": "Slovenia",
    "slovakya": "Slovakia",
    "estonya": "Estonia",
    "letonya": "Latvia",
    "litvanya": "Lithuania",
    "rusya": "Russia",
    "ukrayna": "Ukraine",
    "gürcistan": "Georgia",
    "gurcistan": "Georgia",
    "azerbaycan": "Azerbaijan",
    "ermenistan": "Armenia",
    "kazakistan": "Kazakhstan",
    "özbekistan": "Uzbekistan",
    "ozbekistan": "Uzbekistan",
    "türkiye": "Turkey",
    "turkiye": "Turkey",
    "kıbrıs": "Cyprus",
    "kibris": "Cyprus",
    "amerika": "United States",
    "abd": "United States",
    "amerika birleşik devletleri": "United States",
    "kanada": "Canada",
    "meksika": "Mexico",
    "brezilya": "Brazil",
    "arjantin": "Argentina",
    "şili": "Chile",
    "sili": "Chile",
    "kolombiya": "Colombia",
    "peru": "Peru",
    "avustralya": "Australia",
    "yeni zelanda": "New Zealand",
    "japonya": "Japan",
    "güney kore": "South Korea",
    "guney kore": "South Korea",
    "kore": "South Korea",
    "çin": "China",
    "cin": "China",
    "hindistan": "India",
    "endonezya": "Indonesia",
    "malezya": "Malaysia",
    "singapur": "Singapore",
    "tayland": "Thailand",
    "vietnam": "Vietnam",
    "filipinler": "Philippines",
    "pakistan": "Pakistan",
    "birleşik arap emirlikleri": "United Arab Emirates",
    "birlesik arap emirlikleri": "United Arab Emirates",
    "bae": "United Arab Emirates",
    "katar": "Qatar",
    "suudi arabistan": "Saudi Arabia",
    "kuveyt": "Kuwait",
    "ürdün": "Jordan",
    "urdun": "Jordan",
    "lübnan": "Lebanon",
    "lubnan": "Lebanon",
    "israil": "Israel",
    "iran": "Iran",
    "irak": "Iraq",
    "mısır": "Egypt",
    "misir": "Egypt",
    "fas": "Morocco",
    "tunus": "Tunisia",
    "cezayir": "Algeria",
    "libya": "Libya",
    "güney afrika": "South Africa",
    "guney afrika": "South Africa",
    "kenya": "Kenya",
    "nijerya": "Nigeria",
    "etiyopya": "Ethiopia",
  };

  /// İngilizce ad -> o ada karşılık gelen Türkçe adlar.
  ///
  /// Önceden her ülke için 100 girişlik haritanın tamamı taranıyordu:
  /// 249 ülke x 100 giriş = tuş başına ~25.000 karşılaştırma. Haritayı bir
  /// kez ters çevirip saklıyoruz, arama tek sözlük bakışına iniyor.
  static Map<String, List<String>>? _byEnglish;

  static Map<String, List<String>> get _reverseIndex {
    final cached = _byEnglish;
    if (cached != null) return cached;

    final map = <String, List<String>>{};
    trToEn.forEach((turkish, english) {
      map.putIfAbsent(english.toLowerCase(), () => []).add(turkish);
    });

    _byEnglish = map;
    return map;
  }

  /// Yazılan metnin İngilizce karşılığı varsa onu, yoksa metnin kendisini döner.
  static String resolve(String input) {
    final key = input.trim().toLowerCase();
    return trToEn[key] ?? input.trim();
  }

  /// [query] bu ülkeyle eşleşiyor mu? Hem İngilizce adı hem Türkçe
  /// karşılıkları üzerinden bakar.
  static bool matches(String englishName, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final name = englishName.toLowerCase();
    if (name.contains(q)) return true;

    final turkishNames = _reverseIndex[name];
    if (turkishNames == null) return false;

    for (final turkish in turkishNames) {
      if (turkish.contains(q)) return true;
    }
    return false;
  }
}
