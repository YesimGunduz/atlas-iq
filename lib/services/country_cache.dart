import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// İndirilen ülke listesini diskte tutar.
///
/// Amaç iki yönlü:
/// - Uygulama açılışta ağ beklemeden dolu bir ekranla başlasın
/// - İnternet yokken ya da API çökmüşken uygulama kullanılabilir kalsın
class CountryCache {
  static const String _dataKey = "countries_cache_v1";
  static const String _timeKey = "countries_cache_saved_at";

  /// Bu süreden eski önbellek "bayat" sayılır; gösterilir ama arka planda
  /// tazelenir.
  static const Duration maxAge = Duration(hours: 24);

  // ---------------------------------------------------------------
  static Future<void> write(List<Map<String, dynamic>> countries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dataKey, jsonEncode(countries));
      await prefs.setInt(
        _timeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint("CountryCache.write ERROR: $e");
    }
  }

  /// Diskteki listeyi döner. Yoksa ya da okunamazsa null.
  static Future<List<Map<String, dynamic>>?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_dataKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      final list = decoded
          .whereType<Map>()
          .map((e) => _restore(Map<String, dynamic>.from(e)))
          .toList();

      return list.isEmpty ? null : list;
    } catch (e) {
      debugPrint("CountryCache.read ERROR: $e");
      return null;
    }
  }

  /// jsonDecode dizileri List<dynamic> olarak veriyor; List<String>'e çeviriyoruz.
  static Map<String, dynamic> _restore(Map<String, dynamic> item) {
    item["timezones"] = _stringList(item["timezones"]);
    item["languages"] = _stringList(item["languages"]);
    return item;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  // ---------------------------------------------------------------
  static Future<DateTime?> savedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_timeKey);
      if (millis == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  /// Önbellek var ama [maxAge]'den eskiyse true.
  static Future<bool> isStale() async {
    final saved = await savedAt();
    if (saved == null) return true;
    return DateTime.now().difference(saved) > maxAge;
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dataKey);
      await prefs.remove(_timeKey);
    } catch (e) {
      debugPrint("CountryCache.clear ERROR: $e");
    }
  }
}
