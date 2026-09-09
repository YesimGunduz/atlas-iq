/// Veri dosyasındaki ve API'deki İngilizce değerlerin ekranda görünecek
/// Türkçe karşılıkları.
///
/// Değerlerin kendisi İngilizce kalıyor (JSON anahtarı, filtre karşılaştırması,
/// API cevabı hep İngilizce). Çeviri yalnızca gösterim katmanında yapılıyor —
/// böylece ileride ikinci bir dil eklemek bu dosyaya bir harita eklemekten
/// ibaret olur.
class Labels {
  // ----- Vize türü -----
  static const Map<String, String> _visa = {
    "Visa Free": "Vizesiz",
    "E-Visa": "e-Vize",
    "Visa On Arrival": "Kapıda vize",
    "Visa Required": "Vize gerekli",
  };

  // ----- Giriş belgesi -----
  static const Map<String, String> _entry = {
    "Passport Required": "Pasaport gerekli",
    "ID Only": "Kimlikle giriş",
  };

  // ----- Bölge (API'den İngilizce geliyor) -----
  static const Map<String, String> _region = {
    "Europe": "Avrupa",
    "Asia": "Asya",
    "Africa": "Afrika",
    "Americas": "Amerika",
    "Oceania": "Okyanusya",
    "Antarctic": "Antarktika",
  };

  static String visa(String? value) {
    if (value == null || value.isEmpty) return "-";
    return _visa[value] ?? value;
  }

  static String entry(String? value) {
    if (value == null || value.isEmpty) return "-";
    return _entry[value] ?? value;
  }

  static String region(String? value) {
    if (value == null || value.isEmpty) return "-";
    return _region[value] ?? value;
  }
}
