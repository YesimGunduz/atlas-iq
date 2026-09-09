import 'dart:convert';

import 'package:flutter/services.dart';

/// assets/data/countries_database.json içindeki vize kurallarını yükler.
///
/// Dosya yapısı:
/// {
///   "passport": "...", "updated": "2026-09", "disclaimer": "...",
///   "countries": [
///     {"country": "Germany", "visa": "Visa Required",
///      "entry": "Passport Required", "note": "Schengen vizesi"}
///   ]
/// }
///
/// Eski düz dizi biçimi de okunabiliyor.
class VisaDatabase {
  static const String assetPath = 'assets/data/countries_database.json';

  static final Map<String, Map<String, dynamic>> _byCountry = {};

  static String passport = "";
  static String updated = "";
  static String disclaimer = "";

  static bool get isLoaded => _byCountry.isNotEmpty;
  static int get recordCount => _byCountry.length;

  static Future<void> load() async {
    if (isLoaded) return;

    final String raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    List<dynamic> list;

    if (decoded is Map) {
      passport = (decoded["passport"] ?? "").toString();
      updated = (decoded["updated"] ?? "").toString();
      disclaimer = (decoded["disclaimer"] ?? "").toString();
      list = decoded["countries"] is List ? decoded["countries"] as List : [];
    } else if (decoded is List) {
      list = decoded;
    } else {
      return;
    }

    for (final item in list) {
      if (item is! Map) continue;

      final name = item["country"]?.toString();
      if (name == null || name.isEmpty) continue;

      _byCountry[name.toLowerCase()] = Map<String, dynamic>.from(item);
    }
  }

  static Map<String, dynamic>? findByCountry(String name) =>
      _byCountry[name.trim().toLowerCase()];

  static String? visaOf(String name) => findByCountry(name)?["visa"]?.toString();

  static String? entryOf(String name) =>
      findByCountry(name)?["entry"]?.toString();

  static String? noteOf(String name) {
    final note = findByCountry(name)?["note"]?.toString();
    return (note == null || note.isEmpty) ? null : note;
  }

  /// Ülke kayıtlarına `visa`, `entry` ve `visaNote` alanlarını ekler.
  static List<Map<String, dynamic>> attachTo(
    List<Map<String, dynamic>> countries,
    String Function(Map<String, dynamic>) nameOf,
  ) {
    for (final country in countries) {
      final record = findByCountry(nameOf(country));
      country["visa"] = record?["visa"];
      country["entry"] = record?["entry"];
      country["visaNote"] = record?["note"];
    }
    return countries;
  }
}
