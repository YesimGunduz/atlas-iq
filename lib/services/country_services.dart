import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:globeinfo/services/country_cache.dart';
import 'package:http/http.dart' as http;

/// REST Countries **v5** istemcisi.
///
/// Önemli: v1-v4 (eski /v3.1 dahil) kapatıldı. v5 hem farklı bir adreste
/// hem de farklı bir cevap yapısında ve API anahtarı istiyor:
///
///   GET https://api.restcountries.com/countries/v5/...
///   Authorization: Bearer <ANAHTAR>
///
/// Cevap:  { "data": { "objects": [ ... ], "meta": {...} } }
/// Hata:   { "errors": [ { "message": "..." } ] }
///
/// Anahtarı koda gömmüyoruz. Çalıştırırken ver:
///   flutter run --dart-define=RC_API_KEY=senin_anahtarin
/// Anahtar verilmezse dokümandaki demo anahtarı kullanılır (örnek veri döner).
class CountryService {
  static const String _base = "https://api.restcountries.com/countries/v5";

  static const String apiKey = String.fromEnvironment(
    "RC_API_KEY",
    defaultValue: "rc_live_demo",
  );

  static bool get isUsingDemoKey => apiKey == "rc_live_demo";

  /// API cevabında `data._demo` bloğu geldiyse true. Demo anahtarıyla
  /// çalışırken tam liste yerine örnek veri döndüğünü gösterir.
  static bool demoResponseDetected = false;

  /// API'nin bildirdiği toplam ülke sayısı (data.meta.total).
  static int? reportedTotal;

  /// Elimizdeki liste diskteki önbellekten mi geldi?
  static bool loadedFromCache = false;

  /// Verinin indirildiği tarih (önbellekten geldiyse o tarih).
  static DateTime? dataDate;

  /// v5'te istediğimiz alanlar (nokta yollu).
  static const String _responseFields =
      "names.common,capitals,flag.url_png,flag.colors.dominant,region,population,currencies,timezones,languages,codes.alpha_2";

  static const Duration _timeout = Duration(seconds: 20);

  static List<Map<String, dynamic>>? _cache;

  static Map<String, String> get _headers => {
        "Authorization": "Bearer $apiKey",
        "Accept": "application/json",
      };

  // ===============================================================
  // İSTEK
  // ===============================================================
  /// v5'e istek atar, `data.objects` listesini normalize edip döner.
  static Future<List<Map<String, dynamic>>> _fetchObjects(String path) async {
    final uri = Uri.parse("$_base$path");

    final response = await http.get(uri, headers: _headers).timeout(_timeout);

    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (_) {
      throw CountryServiceException(
        "API cevabı okunamadı (HTTP ${response.statusCode}): "
        "${_snippet(response.body)}",
      );
    }

    // Hata gövdesi
    if (decoded is Map && decoded["errors"] is List) {
      final errors = decoded["errors"] as List;
      final message = errors.isNotEmpty && errors.first is Map
          ? (errors.first as Map)["message"]?.toString()
          : null;

      throw CountryServiceException(
        message ?? "API hatası (HTTP ${response.statusCode})",
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CountryServiceException(
        "API anahtarı kabul edilmedi (HTTP ${response.statusCode}). "
        "restcountries.com'dan ücretsiz anahtar alıp uygulamayı şöyle çalıştır:\n"
        "flutter run --dart-define=RC_API_KEY=anahtarin",
      );
    }

    if (response.statusCode != 200) {
      throw CountryServiceException(
        "HTTP ${response.statusCode}: ${_snippet(response.body)}",
      );
    }

    if (decoded is! Map || decoded["data"] is! Map) {
      throw CountryServiceException(
        "Beklenmeyen cevap yapısı: ${_snippet(response.body)}",
      );
    }

    final data = decoded["data"] as Map;
    final objects = data["objects"];

    if (objects is! List) {
      throw const CountryServiceException("Cevapta data.objects yok");
    }

    return objects
        .whereType<Map>()
        .map((e) => _normalize(Map<String, dynamic>.from(e)))
        .where((e) => (e["name"] as String).isNotEmpty)
        .toList();
  }

  /// Bir sayfanın `data.meta.more` bilgisini de istediğimiz hâli.
  static Future<_Page> _fetchPage(String path) async {
    final uri = Uri.parse("$_base$path");
    final response = await http.get(uri, headers: _headers).timeout(_timeout);

    final decoded = json.decode(response.body);

    if (decoded is Map && decoded["errors"] is List) {
      final errors = decoded["errors"] as List;
      final message = errors.isNotEmpty && errors.first is Map
          ? (errors.first as Map)["message"]?.toString()
          : null;
      throw CountryServiceException(message ?? "API hatası");
    }

    if (response.statusCode != 200) {
      throw CountryServiceException(
        "HTTP ${response.statusCode}: ${_snippet(response.body)}",
      );
    }

    final data = decoded is Map ? decoded["data"] : null;
    if (data is! Map || data["objects"] is! List) {
      throw CountryServiceException(
        "Beklenmeyen cevap yapısı: ${_snippet(response.body)}",
      );
    }

    final items = (data["objects"] as List)
        .whereType<Map>()
        .map((e) => _normalize(Map<String, dynamic>.from(e)))
        .where((e) => (e["name"] as String).isNotEmpty)
        .toList();

    if (data["_demo"] != null) demoResponseDetected = true;

    final meta = data["meta"];
    final more = meta is Map && meta["more"] == true;

    if (meta is Map && meta["total"] is num) {
      reportedTotal = (meta["total"] as num).toInt();
    }

    return _Page(items, more);
  }

  // ===============================================================
  // TÜM ÜLKELER
  // ===============================================================
  /// Sıra: bellek -> disk -> ağ.
  ///
  /// Diskte liste varsa ağ hiç beklenmez; uygulama anında açılır ve
  /// internet yokken de çalışır. Tazeleme [refreshIfStale] ile arka planda.
  static Future<List<Map<String, dynamic>>> getAllCountries({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) return _cache!;

    // 1) Disk
    if (!forceRefresh) {
      final cached = await CountryCache.read();
      if (cached != null && cached.isNotEmpty) {
        _cache = cached;
        loadedFromCache = true;
        dataDate = await CountryCache.savedAt();
        return cached;
      }
    }

    // 2) Ağ
    final fresh = await _downloadAll();

    _cache = fresh;
    loadedFromCache = false;
    dataDate = DateTime.now();

    await CountryCache.write(fresh);
    return fresh;
  }

  /// Önbellekten açıldıysa ve veri bayatsa sessizce tazeler.
  /// Liste gerçekten değiştiyse true döner.
  static Future<bool> refreshIfStale() async {
    if (!loadedFromCache) return false;
    if (!await CountryCache.isStale()) return false;

    try {
      final fresh = await _downloadAll();
      final changed = fresh.length != (_cache?.length ?? 0);

      _cache = fresh;
      loadedFromCache = false;
      dataDate = DateTime.now();

      await CountryCache.write(fresh);
      return changed;
    } catch (e) {
      // Tazeleme başarısızsa elimizdeki önbellekle devam ediyoruz.
      debugPrint("refreshIfStale ERROR: $e");
      return false;
    }
  }

  /// Sayfa sayfa indirir.
  ///
  /// Bir sayfa hata verirse elde olanla devam eder; sadece hiç kayıt
  /// gelmediyse hata fırlatır. 3. sayfa düştü diye ilk 200 ülkeyi
  /// çöpe atmıyoruz.
  static Future<List<Map<String, dynamic>>> _downloadAll() async {
    demoResponseDetected = false;
    reportedTotal = null;

    final all = <Map<String, dynamic>>[];
    var offset = 0;
    const pageSize = 100; // ücretsiz planın üst sınırı

    Object? lastError;

    for (var i = 0; i < 5; i++) {
      _Page page;

      try {
        page = await _fetchPage(
          "?limit=$pageSize&offset=$offset&response_fields=$_responseFields",
        );
      } catch (e) {
        lastError = e;
        break; // elde olanı koru
      }

      all.addAll(page.items);

      if (!page.more || page.items.isEmpty) break;
      offset += pageSize;
    }

    if (all.isEmpty) {
      if (lastError is CountryServiceException) throw lastError;
      throw CountryServiceException(
        lastError?.toString() ?? "API boş ülke listesi döndürdü",
      );
    }

    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final c in all) {
      final name = c["name"] as String;
      if (seen.add(name)) unique.add(c);
    }

    unique.sort(
      (a, b) => (a["name"] as String).compareTo(b["name"] as String),
    );

    return unique;
  }

  // ===============================================================
  // TEK ÜLKE
  // ===============================================================
  static Future<Map<String, dynamic>?> getCountry(String name) async {
    final query = name.trim();
    if (query.isEmpty) return null;

    // 1) Elimizdeki listeden bak
    final cached = _cache;
    if (cached != null) {
      final lower = query.toLowerCase();
      for (final c in cached) {
        if ((c["name"] as String).toLowerCase() == lower) return c;
      }
      for (final c in cached) {
        if ((c["name"] as String).toLowerCase().contains(lower)) return c;
      }
    }

    // 2) Tam isimle oku
    try {
      final exact = await _fetchObjects(
        "/names.common/${Uri.encodeComponent(query)}"
        "?response_fields=$_responseFields",
      );
      if (exact.isNotEmpty) return exact.first;
    } on CountryServiceException catch (e) {
      debugPrint("getCountry exact: $e");
    }

    // 3) Bulamazsa isim araması yap
    final found = await _fetchObjects(
      "/name?q=${Uri.encodeComponent(query)}&limit=5"
      "&response_fields=$_responseFields",
    );

    return found.isEmpty ? null : found.first;
  }

  // ===============================================================
  // v5 KAYDINI UYGULAMANIN KULLANDIĞI DÜZ YAPIYA ÇEVİR
  // ===============================================================
  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final currency = _readCurrency(raw);

    return {
      "name": _readName(raw),
      "capital": _readCapital(raw),
      "flag": _readFlag(raw),
      "region": (raw["region"] ?? "").toString(),
      "flagColor": _readFlagColor(raw),
      "population": raw["population"] is num ? raw["population"] as num : null,
      "currencyCode": currency?.$1 ?? "",
      "currencyName": currency?.$2 ?? "",
      "timezones": _readTimezones(raw),
      "languages": _readLanguages(raw),
      "alpha2": _readAlpha2(raw),
    };
  }

  static String _readName(Map<String, dynamic> raw) {
    final names = raw["names"];
    if (names is Map && names["common"] != null) {
      return names["common"].toString();
    }
    return "";
  }

  static String _readCapital(Map<String, dynamic> raw) {
    final capitals = raw["capitals"];
    if (capitals is List && capitals.isNotEmpty) {
      final first = capitals.first;
      if (first is Map && first["name"] != null) return first["name"].toString();
      if (first is String) return first;
    }
    return "-";
  }

  static String _readFlag(Map<String, dynamic> raw) {
    final flag = raw["flag"];
    if (flag is Map) {
      final png = flag["url_png"] ?? flag["url_svg"];
      if (png != null) return png.toString();
    }
    // Elde bayrak yoksa ülke kodundan üret
    final code = _readAlpha2(raw);
    if (code.isNotEmpty) {
      return "https://flagcdn.com/w320/${code.toLowerCase()}.png";
    }
    return "";
  }

  /// flag.colors.dominant -> "#RRGGBB". Yoksa boş string.
  static String _readFlagColor(Map<String, dynamic> raw) {
    final flag = raw["flag"];
    if (flag is Map) {
      final colors = flag["colors"];
      if (colors is Map && colors["dominant"] != null) {
        return colors["dominant"].toString();
      }
    }
    return "";
  }

  static String _readAlpha2(Map<String, dynamic> raw) {
    final codes = raw["codes"];
    if (codes is Map && codes["alpha_2"] != null) {
      return codes["alpha_2"].toString();
    }
    return "";
  }

  /// (kod, isim) - şekli kesin bilmediğimiz için birkaç olasılığı karşılıyoruz.
  static (String, String)? _readCurrency(Map<String, dynamic> raw) {
    final currencies = raw["currencies"];

    if (currencies is Map && currencies.isNotEmpty) {
      final code = currencies.keys.first.toString();
      final detail = currencies[currencies.keys.first];

      if (detail is Map) {
        final name = (detail["name"] ?? detail["title"] ?? "").toString();
        return (code, name);
      }
      if (detail is String) return (code, detail);
      return (code, "");
    }

    if (currencies is List && currencies.isNotEmpty) {
      final first = currencies.first;
      if (first is Map) {
        final code = (first["code"] ?? first["iso_4217"] ?? "").toString();
        final name = (first["name"] ?? "").toString();
        return (code, name);
      }
    }

    return null;
  }

  static List<String> _readTimezones(Map<String, dynamic> raw) {
    final zones = raw["timezones"];
    if (zones is List) return zones.map((e) => e.toString()).toList();
    if (zones is String) return [zones];
    return const [];
  }

  static List<String> _readLanguages(Map<String, dynamic> raw) {
    final langs = raw["languages"];

    if (langs is List) {
      final out = <String>[];
      for (final item in langs) {
        if (item is String) {
          out.add(item);
        } else if (item is Map) {
          final name = item["english"] ??
              item["name"] ??
              item["english_name"] ??
              item["name_english"] ??
              item["native"] ??
              item["native_name"];
          if (name != null) out.add(name.toString());
        }
      }
      return out;
    }

    // Eski şekil: {"deu": "German"}
    if (langs is Map) {
      return langs.values.map((e) => e.toString()).toList();
    }

    return const [];
  }

  // ===============================================================
  // TL KARŞILIĞI
  // ===============================================================
  static Future<String> getTryRate(String currencyCode) async {
    final code = currencyCode.trim().toUpperCase();
    if (code.isEmpty) return "-";
    if (code == "TRY") return "1.00";

    try {
      final uri = Uri.parse("https://open.er-api.com/v6/latest/$code");
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return "-";

      final data = json.decode(response.body);
      if (data is! Map || data["result"] != "success") return "-";

      final rates = data["rates"];
      if (rates is! Map) return "-";

      final tryRate = rates["TRY"];
      if (tryRate is! num) return "-";

      return tryRate.toStringAsFixed(2);
    } catch (e) {
      debugPrint("getTryRate ERROR: $e");
      return "-";
    }
  }

  // ===============================================================
  // YARDIMCILAR (UI bunları kullanıyor)
  // ===============================================================
  static String countryName(Map<String, dynamic> country) =>
      (country["name"] ?? "").toString();

  static String flagUrl(Map<String, dynamic> country) =>
      (country["flag"] ?? "").toString();

  static String capitalOf(Map<String, dynamic> country) {
    final capital = (country["capital"] ?? "").toString();
    return capital.isEmpty ? "-" : capital;
  }

  static Future<void> clearCache() async {
    _cache = null;
    loadedFromCache = false;
    dataDate = null;
    await CountryCache.clear();
  }

  static String _snippet(String body) {
    final clean = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length > 200 ? "${clean.substring(0, 200)}..." : clean;
  }
}

class _Page {
  final List<Map<String, dynamic>> items;
  final bool more;
  const _Page(this.items, this.more);
}

class CountryServiceException implements Exception {
  final String message;
  const CountryServiceException(this.message);

  @override
  String toString() => message;
}
