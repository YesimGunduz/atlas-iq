import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:globeinfo/data/country.dart';
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
/// Anahtar verilmezse dokümandaki demo anahtarı kullanılır — o da tek bir
/// ülke (Kanada) döndürür, yani uygulama gerçek anahtar olmadan dolmaz.
class CountryService {
  static const String _base = "https://api.restcountries.com/countries/v5";

  static const String apiKey = String.fromEnvironment(
    "RC_API_KEY",
    defaultValue: "rc_live_demo",
  );

  static bool get isUsingDemoKey => apiKey == "rc_live_demo";

  /// v5'ten istediğimiz alanlar (nokta yollu).
  static const String _responseFields =
      "names.common,capitals,flag.url_png,flag.colors.dominant,region,"
      "population,currencies,timezones,languages,codes.alpha_2";

  static const Duration _timeout = Duration(seconds: 20);

  static List<Country>? _cache;

  /// API cevabında `data._demo` bloğu geldiyse true.
  static bool demoResponseDetected = false;

  /// API'nin bildirdiği toplam ülke sayısı (data.meta.total).
  static int? reportedTotal;

  /// Elimizdeki liste diskteki önbellekten mi geldi?
  static bool loadedFromCache = false;

  /// Verinin indirildiği tarih (önbellekten geldiyse o tarih).
  static DateTime? dataDate;

  static Map<String, String> get _headers => {
        "Authorization": "Bearer $apiKey",
        "Accept": "application/json",
      };

  // ===============================================================
  // İSTEK
  // ===============================================================
  /// v5'e tek bir istek atar ve sayfayı döndürür.
  /// Hem liste hem tek kayıt çağrıları bunu kullanıyor.
  static Future<_Page> _request(String path) async {
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
        "API anahtarı kabul edilmedi (HTTP ${response.statusCode}).\n"
        "restcountries.com'dan ücretsiz anahtar alıp uygulamayı şöyle "
        "çalıştır:\nflutter run --dart-define=RC_API_KEY=anahtarin",
      );
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

    if (data["_demo"] != null) demoResponseDetected = true;

    final items = (data["objects"] as List)
        .whereType<Map>()
        .map((e) => Country.fromV5(Map<String, dynamic>.from(e)))
        .where((c) => c.isValid)
        .toList();

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
  static Future<List<Country>> getAllCountries({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) return _cache!;

    if (!forceRefresh) {
      final cached = await CountryCache.read();
      if (cached != null && cached.isNotEmpty) {
        _cache = cached;
        loadedFromCache = true;
        dataDate = await CountryCache.savedAt();
        return cached;
      }
    }

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
  static Future<List<Country>> _downloadAll() async {
    demoResponseDetected = false;
    reportedTotal = null;

    final all = <Country>[];
    var offset = 0;
    const pageSize = 100; // ücretsiz planın üst sınırı

    Object? lastError;

    for (var i = 0; i < 5; i++) {
      _Page page;

      try {
        page = await _request(
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
    final unique = <Country>[];
    for (final c in all) {
      if (seen.add(c.name)) unique.add(c);
    }

    unique.sort((a, b) => a.name.compareTo(b.name));
    return unique;
  }

  // ===============================================================
  // TEK ÜLKE
  // ===============================================================
  static Future<Country?> getCountry(String name) async {
    final query = name.trim();
    if (query.isEmpty) return null;

    // 1) Elimizdeki listeden bak - ağa hiç çıkmadan cevap verir
    final cached = _cache;
    if (cached != null) {
      final lower = query.toLowerCase();

      for (final c in cached) {
        if (c.name.toLowerCase() == lower) return c;
      }
      for (final c in cached) {
        if (c.name.toLowerCase().contains(lower)) return c;
      }
    }

    // 2) Tam isimle oku
    try {
      final exact = await _request(
        "/names.common/${Uri.encodeComponent(query)}"
        "?response_fields=$_responseFields",
      );
      if (exact.items.isNotEmpty) return exact.items.first;
    } on CountryServiceException catch (e) {
      debugPrint("getCountry exact: $e");
    }

    // 3) Bulamazsa isim araması
    final found = await _request(
      "/name?q=${Uri.encodeComponent(query)}&limit=5"
      "&response_fields=$_responseFields",
    );

    return found.items.isEmpty ? null : found.items.first;
  }

  // ===============================================================
  // TL KARŞILIĞI
  // ===============================================================
  /// 1 birim [currencyCode] kaç TL eder? Ulaşılamazsa "-".
  static Future<String> getTryRate(String currencyCode) async {
    final code = currencyCode.trim().toUpperCase();
    if (code.isEmpty) return "-";
    if (code == "TRY") return "1.00";

    try {
      final uri = Uri.parse("https://open.er-api.com/v6/latest/$code");
      // Kur yan bilgi; sayfayı bekletmesin diye kısa timeout.
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
  final List<Country> items;
  final bool more;
  const _Page(this.items, this.more);
}

class CountryServiceException implements Exception {
  final String message;
  const CountryServiceException(this.message);

  @override
  String toString() => message;
}
