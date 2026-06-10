import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryService {

  // 🌍 TEK ÜLKE ÇEKME (SENİN ESKİ FONKSİYON - KORUNDU)
  static Future<Map<String, dynamic>?> getCountry(String name) async {
    try {
      final url = Uri.parse(
        'https://restcountries.com/v3.1/name/$name',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.isNotEmpty ? data[0] : null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 🌍 TÜM ÜLKELER (FIXLENDİ 🔥)
  static Future<List<Map<String, dynamic>>> getAllCountries() async {
    try {
      final url = Uri.parse('https://restcountries.com/v3.1/all');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        // 🔥 KRİTİK FIX: normalize etmeden dönmüyorsun
        return data.map<Map<String, dynamic>>((c) {
          return normalizeCountry(c);
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // 🧠 NORMALIZE (KORUNDU + SADECE SAĞLAMLAŞTIRILDI)
  static Map<String, dynamic> normalizeCountry(dynamic c) {
    try {
      final name = c["name"]?["common"] ?? "-";
      final code = c["cca2"] ?? "-";

      final capital = (c["capital"] != null && c["capital"].isNotEmpty)
          ? c["capital"][0]
          : "-";

      final currency = c["currencies"] != null
          ? c["currencies"].keys.first
          : "USD";

      return {
        "name": name,
        "code": code,
        "capital": capital,
        "currency": currency,

        // 🔥 FILTER SYSTEM (şimdilik placeholder)
        "visaType": "Visa Free",
        "entryType": "Passport Required",
      };
    } catch (e) {
      return {
        "name": "-",
        "code": "-",
        "capital": "-",
        "currency": "USD",
        "visaType": "Visa Free",
        "entryType": "Passport Required",
      };
    }
  }

  // 💰 DÖVİZ (TRY KURU)
  static Future<double?> getTryRateValue(String currencyCode) async {
    try {
      if (currencyCode == "TRY") return 1.0;

      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/$currencyCode'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final rate = data["rates"]?["TRY"];

        if (rate != null) {
          return (rate as num).toDouble();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 💱 STRING FORMAT (UI İÇİN)
  static Future getTryRate(String currencyCode) async {
    final rate = await getTryRateValue(currencyCode);

    if (rate == null) return "-";

    return "1 $currencyCode = ${rate.toStringAsFixed(2)} ₺";
  }
}