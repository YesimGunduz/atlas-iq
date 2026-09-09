import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedCountry {
  final String name;
  final String capital;
  final String flag;
  final String continent;

  SavedCountry({
    required this.name,
    required this.capital,
    required this.flag,
    required this.continent,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "capital": capital,
        "flag": flag,
        "continent": continent,
      };

  factory SavedCountry.fromJson(Map<String, dynamic> json) => SavedCountry(
        name: (json["name"] ?? "").toString(),
        capital: (json["capital"] ?? "-").toString(),
        flag: (json["flag"] ?? "").toString(),
        continent: (json["continent"] ?? "-").toString(),
      );
}

/// Kaydedilen ülkeler. Telefonun diskinde tutulur, uygulama kapanınca silinmez.
class SavedData {
  static const String _storageKey = "saved_countries_v1";

  static List<SavedCountry> savedCountries = [];

  /// Uygulama açılırken bir kez çağrılır.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      savedCountries = decoded
          .whereType<Map>()
          .map((e) => SavedCountry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint("SavedData.load ERROR: $e");
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(savedCountries.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint("SavedData._persist ERROR: $e");
    }
  }

  static bool contains(String name) =>
      savedCountries.any((e) => e.name == name);

  static Future<void> add(SavedCountry country) async {
    if (contains(country.name)) return;
    savedCountries.add(country);
    await _persist();
  }

  static Future<void> remove(String name) async {
    savedCountries.removeWhere((e) => e.name == name);
    await _persist();
  }

  static Future<void> clear() async {
    savedCountries.clear();
    await _persist();
  }
}
